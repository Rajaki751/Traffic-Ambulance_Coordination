"""
WebSocket connection manager for real-time GPS and dashboard updates.

Channels:
- admin: receives all live updates
- driver:{ambulance_id}: driver-specific updates
- officer:{user_id}: officer notifications and ambulance positions
"""

import asyncio
import json
from enum import Enum
from typing import Any, Dict, List, Set, Tuple

from fastapi import WebSocket

from app.core.logging import get_logger

logger = get_logger(__name__)


class ChannelType(str, Enum):
    ADMIN = "admin"
    DRIVER = "driver"
    OFFICER = "officer"


class ConnectionManager:
    """Manage WebSocket connections and broadcast messages."""

    HEARTBEAT_INTERVAL = 30.0

    def __init__(self) -> None:
        # channel_key -> set of websockets
        self._connections: Dict[str, Set[WebSocket]] = {}
        self._heartbeat_task: asyncio.Task | None = None

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
        conns = list(self._connections[key])
        results = await asyncio.gather(
            *(ws.send_text(payload) for ws in conns),
            return_exceptions=True,
        )
        dead: List[WebSocket] = []
        for ws, result in zip(conns, results):
            if isinstance(result, Exception):
                dead.append(ws)
        for ws in dead:
            self._connections[key].discard(ws)
        if not self._connections[key]:
            del self._connections[key]

    def start_heartbeat(self) -> None:
        """Start the dead-connection sweep (safe to call once)."""
        if self._heartbeat_task is None or self._heartbeat_task.done():
            self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

    async def stop_heartbeat(self) -> None:
        if self._heartbeat_task is not None:
            self._heartbeat_task.cancel()
            try:
                await self._heartbeat_task
            except asyncio.CancelledError:
                pass
            self._heartbeat_task = None

    async def _heartbeat_loop(self) -> None:
        """Ping every connection periodically and drop the dead ones."""
        while True:
            await asyncio.sleep(self.HEARTBEAT_INTERVAL)
            dead: List[Tuple[str, WebSocket]] = []
            for key, conns in list(self._connections.items()):
                for ws in list(conns):
                    try:
                        await ws.send_text(json.dumps({"type": "ping"}))
                    except Exception:
                        dead.append((key, ws))
            for key, ws in dead:
                self._connections[key].discard(ws)
                if not self._connections[key]:
                    del self._connections[key]
            if dead:
                logger.info("WebSocket heartbeat dropped %d dead connection(s)", len(dead))


ws_manager = ConnectionManager()
