"""Chat schemas."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class ChatParticipant(BaseModel):
    user_id: int
    name: str = ""
    role: str = ""


class ChatMessageResponse(BaseModel):
    id: int
    emergency_session_id: int
    sender_user_id: int
    sender_name: str = ""
    sender_role: str = ""
    message: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatSendRequest(BaseModel):
    message: str = ""
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ChatSessionResponse(BaseModel):
    emergency_session_id: int
    vehicle_number: str
    destination: str
    status: str
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: int = 0
    participants: List[ChatParticipant] = []

    model_config = {"from_attributes": True}
