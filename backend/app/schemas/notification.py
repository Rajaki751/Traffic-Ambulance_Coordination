"""Notification schemas."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: int
    officer_id: int
    user_id: Optional[int] = None
    notification_type: str = "emergency_alert"
    emergency_session_id: Optional[int]
    title: str
    message: str
    is_read: bool
    is_acknowledged: bool
    acknowledgment: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationAcknowledge(BaseModel):
    notification_id: int
    action: Optional[str] = None


class DriverReplyRequest(BaseModel):
    emergency_session_id: int
    message: str
