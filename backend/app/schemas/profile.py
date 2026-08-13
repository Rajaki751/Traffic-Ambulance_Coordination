"""Profile and account schemas."""

from typing import Optional

from pydantic import BaseModel, Field


class ProfileResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    vehicle_number: Optional[str] = None
    assigned_zone: Optional[str] = None
    zone_latitude: Optional[float] = None
    zone_longitude: Optional[float] = None

    model_config = {"from_attributes": True}


class ProfileUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=255)


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=128)
