"""Traffic junction management schemas."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class JunctionClearCreate(BaseModel):
    emergency_session_id: Optional[int] = None
    junction_name: str = Field(..., min_length=2, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    notes: Optional[str] = Field(None, max_length=1000)


class JunctionClearResponse(BaseModel):
    id: int
    officer_id: int
    emergency_session_id: Optional[int]
    junction_name: str
    latitude: float
    longitude: float
    notes: Optional[str]
    cleared_at: datetime

    model_config = {"from_attributes": True}
