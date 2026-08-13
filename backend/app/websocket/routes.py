"""WebSocket endpoints for real-time updates."""

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, _get_user_from_payload
from app.core.security import decode_access_token
from app.core.logging import get_logger
from app.models.ambulance import Ambulance
from app.models.user import UserRole
from app.websocket.manager import ChannelType, ws_manager

logger = get_logger(__name__)
router = APIRouter()

WS_UNAUTHENTICATED = 4401
WS_FORBIDDEN = 4403


def _extract_token(websocket: WebSocket, token: str) -> str | None:
    """Return the JWT from the query param or Sec-WebSocket-Protocol header."""
    if token:
        return token
    protocol = websocket.headers.get("sec-websocket-protocol", "")
    for entry in protocol.split(","):
        entry = entry.strip()
        if entry.startswith("token."):
            return entry[len("token."):]
    return None


@router.websocket("/live")
async def websocket_live(
    websocket: WebSocket,
    token: str = Query(""),
    channel: str = Query("admin"),
    db: AsyncSession = Depends(get_db),
):
    """
    WebSocket for real-time GPS and emergency updates.

    Query params:
    - token: JWT access token (or Sec-WebSocket-Protocol header `token.{jwt}`)
    - channel: admin | driver | officer

    The channel identifier is derived server-side from the token: drivers
    subscribe as their ambulance id, officers as their user id.
    """
    jwt_token = _extract_token(websocket, token)
    payload = decode_access_token(jwt_token) if jwt_token else None
    if not payload:
        await websocket.close(code=WS_UNAUTHENTICATED)
        return

    try:
        current_user = await _get_user_from_payload(db, payload)
    except Exception:
        await websocket.close(code=WS_UNAUTHENTICATED)
        return

    role = current_user.role
    ch_type: ChannelType
    ch_id: str

    if channel == ChannelType.ADMIN.value:
        ch_type = ChannelType.ADMIN
        ch_id = ""
        if role != UserRole.ADMIN:
            await websocket.close(code=WS_FORBIDDEN)
            return
    elif channel == ChannelType.DRIVER.value:
        if role != UserRole.DRIVER:
            await websocket.close(code=WS_FORBIDDEN)
            return
        result = await db.execute(
            select(Ambulance).where(Ambulance.driver_id == current_user.id)
        )
        ambulance = result.scalar_one_or_none()
        if ambulance is None:
            await websocket.close(code=WS_FORBIDDEN)
            return
        ch_type = ChannelType.DRIVER
        ch_id = str(ambulance.id)
    elif channel == ChannelType.OFFICER.value:
        if role != UserRole.OFFICER:
            await websocket.close(code=WS_FORBIDDEN)
            return
        ch_type = ChannelType.OFFICER
        ch_id = str(current_user.id)
    else:
        await websocket.close(code=WS_FORBIDDEN)
        return

    key = await ws_manager.connect(websocket, ch_type, ch_id)
    await ws_manager.send_personal(
        websocket,
        {"type": "connected", "channel": channel, "message": "Real-time feed active"},
    )

    try:
        while True:
            data = await websocket.receive_text()
            # Echo/ping support for keepalive
            if data == "ping":
                await ws_manager.send_personal(websocket, {"type": "pong"})
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, key)
    except Exception as exc:
        logger.warning("WebSocket error: %s", exc)
        ws_manager.disconnect(websocket, key)
