"""Emergency session group chat endpoints."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireDriverOrOfficer, get_db
from app.models.emergency import EmergencySession
from app.schemas.chat import ChatMessageResponse, ChatSendRequest, ChatSessionResponse
from app.services.chat_service import ChatService
from app.websocket.manager import ChannelType, ws_manager

router = APIRouter()


@router.get("/sessions", response_model=List[ChatSessionResponse])
async def list_chat_sessions(
    current_user: RequireDriverOrOfficer,
    db: AsyncSession = Depends(get_db),
    limit: int = 30,
):
    """List chat sessions for the current driver or officer."""
    sessions = await ChatService.list_sessions(
        db, current_user.id, current_user.role.value
    )
    return sessions


@router.get("/sessions/{session_id}/messages", response_model=List[ChatMessageResponse])
async def list_chat_messages(
    session_id: int,
    current_user: RequireDriverOrOfficer,
    db: AsyncSession = Depends(get_db),
    limit: int = 100,
):
    """List messages in a session's group chat."""
    messages = await ChatService.list_messages(
        db, session_id, current_user.id, current_user.role.value, limit=limit
    )
    if messages is None:
        raise HTTPException(status_code=403, detail="Not a participant of this session")
    return messages


@router.post("/sessions/{session_id}/messages", response_model=ChatMessageResponse)
async def send_chat_message(
    session_id: int,
    payload: ChatSendRequest,
    current_user: RequireDriverOrOfficer,
    db: AsyncSession = Depends(get_db),
):
    """Send a message to the session's group chat."""
    text = payload.message.strip()
    has_location = (
        payload.latitude is not None and payload.longitude is not None
    )
    if not text and not has_location:
        raise HTTPException(status_code=422, detail="Message cannot be empty")
    msg = await ChatService.send_message(
        db,
        session_id,
        current_user.id,
        current_user.role.value,
        text,
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    if not msg:
        raise HTTPException(status_code=403, detail="Not a participant of this session")
    await db.commit()

    officer_ids, _driver_id = await ChatService.participants(db, session_id)

    session_result = await db.execute(
        select(EmergencySession).where(EmergencySession.id == session_id)
    )
    session = session_result.scalar_one_or_none()
    if session:
        message_data = {
            "type": "chat_message",
            "data": ChatMessageResponse(
                id=msg.id,
                emergency_session_id=session_id,
                sender_user_id=current_user.id,
                sender_name=current_user.name or "",
                sender_role=current_user.role.value,
                message=text,
                latitude=payload.latitude,
                longitude=payload.longitude,
                created_at=msg.created_at,
            ).model_dump(mode="json"),
        }
        await ws_manager.broadcast_to_channel(
            ChannelType.DRIVER, message_data, str(session.ambulance_id)
        )
        for officer_id in officer_ids:
            await ws_manager.notify_officer(officer_id, message_data)

    return ChatMessageResponse(
        id=msg.id,
        emergency_session_id=session_id,
        sender_user_id=current_user.id,
        sender_name=current_user.name or "",
        sender_role=current_user.role.value,
        message=text,
        latitude=payload.latitude,
        longitude=payload.longitude,
        created_at=msg.created_at,
    )


@router.post("/sessions/{session_id}/read")
async def mark_chat_read(
    session_id: int,
    current_user: RequireDriverOrOfficer,
    db: AsyncSession = Depends(get_db),
):
    """Mark the session's chat as read for the current user."""
    ok = await ChatService.mark_read(
        db, session_id, current_user.id, current_user.role.value
    )
    if not ok:
        raise HTTPException(status_code=403, detail="Not a participant of this session")
    await db.commit()
    return {"status": "ok"}
