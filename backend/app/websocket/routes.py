"""WebSocket endpoints for real-time updates."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status

from app.core.security import decode_access_token
from app.core.logging import get_logger
from app.models.user import UserRole
from app.websocket.manager import ChannelType, ws_manager

logger = get_logger(__name__)
router = APIRouter()


def _authenticate_ws(token: str) -> dict | None:
    """Validate JWT from query parameter."""
    if not token:
        return None
    return decode_access_token(token)


@router.websocket("/live")
async def websocket_live(
    websocket: WebSocket,
    token: str = Query(...),
    channel: str = Query("admin"),
    identifier: str = Query(""),
):
    """
    WebSocket for real-time GPS and emergency updates.

    Query params:
    - token: JWT access token
    - channel: admin | driver | officer
    - identifier: ambulance_id (driver) or user_id (officer)
    """
    payload = _authenticate_ws(token)
    if not payload:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    role = payload.get("role", "")
    channel_map = {
        "admin": (ChannelType.ADMIN, "", UserRole.ADMIN),
        "driver": (ChannelType.DRIVER, identifier, UserRole.DRIVER),
        "officer": (ChannelType.OFFICER, identifier, UserRole.OFFICER),
    }

    if channel not in channel_map:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    ch_type, ch_id, required_role = channel_map[channel]
    if role != required_role.value:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
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
