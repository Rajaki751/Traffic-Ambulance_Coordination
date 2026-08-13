"""
WebSocket connection manager for real-time GPS and dashboard updates.

Channels:
- admin: receives all live updates
- driver:{ambulance_id}: driver-specific updates
- officer:{user_id}: officer notifications and ambulance positions
"""

import json
from enum import Enum
from typing import Any, Dict, List, Set

from fastapi import WebSocket

from app.core.logging import get_logger

logger = get_logger(__name__)


class ChannelType(str, Enum):
    ADMIN = "admin"
    DRIVER = "driver"
    OFFICER = "officer"


class ConnectionManager:
    """Manage WebSocket connections and broadcast messages."""

    def __init__(self) -> None:
        # channel_key -> set of websockets
        self._connections: Dict[str, Set[WebSocket]] = {}

    def _channel_key(self, channel: ChannelType, identifier: str = "") -> str:
        if identifier:
            return f"{channel.value}:{identifier}"
        return channel.value

    async def connect(
        self,
        websocket: WebSocket,
        channel: ChannelType,
        identifier: str = "",
    ) -> str:
        await websocket.accept()
        key = self._channel_key(channel, identifier)
        if key not in self._connections:
            self._connections[key] = set()
        self._connections[key].add(websocket)
        logger.info("WebSocket connected: %s (total: %d)", key, len(self._connections[key]))
        return key

    def disconnect(self, websocket: WebSocket, key: str) -> None:
        if key in self._connections:
            self._connections[key].discard(websocket)
            if not self._connections[key]:
                del self._connections[key]
        logger.info("WebSocket disconnected: %s", key)

    async def send_personal(self, websocket: WebSocket, message: dict[str, Any]) -> None:
        await websocket.send_text(json.dumps(message, default=str))

    async def broadcast_to_channel(
        self, channel: ChannelType, message: dict[str, Any], identifier: str = ""
    ) -> None:
        key = self._channel_key(channel, identifier)
        await self._broadcast_key(key, message)

    async def broadcast_all_admins(self, message: dict[str, Any]) -> None:
        await self._broadcast_key(self._channel_key(ChannelType.ADMIN), message)

    async def broadcast_gps_update(self, message: dict[str, Any]) -> None:
        """Broadcast GPS update to admin and all officer channels."""
        await self.broadcast_all_admins(message)
        # Broadcast to all officer connections
        for key in list(self._connections.keys()):
            if key.startswith("officer:"):
                await self._broadcast_key(key, message)

    async def notify_officer(self, officer_id: int, message: dict[str, Any]) -> None:
        await self.broadcast_to_channel(
            ChannelType.OFFICER, message, str(officer_id)
        )

    async def _broadcast_key(self, key: str, message: dict[str, Any]) -> None:
        if key not in self._connections:
            return
        payload = json.dumps(message, default=str)
        dead: List[WebSocket] = []
        for ws in self._connections[key]:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self._connections[key].discard(ws)


ws_manager = ConnectionManager()
