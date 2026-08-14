"""Chat schemas."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class ChatMessageResponse(BaseModel):
    id: int
    emergency_session_id: int
    sender_user_id: int
    sender_name: str = ""
    message: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatSendRequest(BaseModel):
    message: str


class ChatSessionResponse(BaseModel):
    emergency_session_id: int
    vehicle_number: str
    destination: str
    status: str
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: int = 0

    model_config = {"from_attributes": True}
