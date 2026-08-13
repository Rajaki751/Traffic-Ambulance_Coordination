"""Traffic officer notification endpoints."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireDriver, RequireOfficer, get_db
from app.models.ambulance import Ambulance
from app.models.emergency import EmergencySession
from app.schemas.notification import NotificationAcknowledge, NotificationResponse
from app.services.notification_service import NotificationService
from app.websocket.manager import ws_manager

router = APIRouter()


class SendToDriverRequest(BaseModel):
    emergency_session_id: int
    title: str
    message: str


@router.get("/", response_model=List[NotificationResponse])
async def list_notifications(
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
    unread_only: bool = False,
):
    """List notifications for the current traffic officer."""
    notifs = await NotificationService.get_officer_notifications(
        db, current_user.id, unread_only=unread_only
    )
    return [NotificationResponse.model_validate(n) for n in notifs]


@router.get("/driver", response_model=List[NotificationResponse])
async def list_driver_notifications(
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
    unread_only: bool = False,
):
    """List notifications for current driver user."""
    notifs = await NotificationService.get_user_notifications(
        db, current_user.id, unread_only=unread_only
    )
    return [NotificationResponse.model_validate(n) for n in notifs]


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: int,
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
):
    success = await NotificationService.mark_read(db, notification_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")
    notifs = await NotificationService.get_officer_notifications(db, current_user.id)
    for n in notifs:
        if n.id == notification_id:
            return NotificationResponse.model_validate(n)
    raise HTTPException(status_code=404, detail="Notification not found")


@router.post("/acknowledge", response_model=NotificationResponse)
async def acknowledge_notification(
    payload: NotificationAcknowledge,
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
):
    """Officer acknowledges an emergency alert."""
    notif = await NotificationService.acknowledge(
        db, payload.notification_id, current_user.id
    )
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")

    await ws_manager.broadcast_all_admins(
        {
            "type": "notification_acknowledged",
            "data": NotificationResponse.model_validate(notif).model_dump(mode="json"),
        }
    )
    return NotificationResponse.model_validate(notif)


@router.post("/send-to-driver", response_model=NotificationResponse)
async def send_to_driver(
    payload: SendToDriverRequest,
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
):
    """Officer sends a notification to the driver of an active emergency."""
    result = await db.execute(
        select(EmergencySession).where(EmergencySession.id == payload.emergency_session_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Emergency session not found")

    amb_result = await db.execute(
        select(Ambulance).where(Ambulance.id == session.ambulance_id)
    )
    ambulance = amb_result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")

    notif = await NotificationService.create_driver_notification(
        db=db,
        driver_user_id=ambulance.driver_id,
        emergency_session_id=session.id,
        title=payload.title,
        message=payload.message,
    )
    return notif
