"""GPS tracking schemas."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class GPSUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    speed_kmh: Optional[float] = Field(None, ge=0)
    heading: Optional[float] = Field(None, ge=0, le=360)
    emergency_session_id: int


class GPSLogResponse(BaseModel):
    id: Optional[int] = None
    emergency_session_id: int
    latitude: float
    longitude: float
    speed_kmh: Optional[float]
    heading: Optional[float]
    timestamp: Optional[datetime] = None

    model_config = {"from_attributes": True}


class LiveAmbulanceLocation(BaseModel):
    ambulance_id: int
    vehicle_number: str
    emergency_session_id: int
    latitude: float
    longitude: float
    speed_kmh: Optional[float]
    heading: Optional[float]
    destination: str
    dest_latitude: Optional[float] = None
    dest_longitude: Optional[float] = None
    route_polyline: Optional[str] = None
    eta_minutes: Optional[float]
    status: str
    updated_at: datetime
