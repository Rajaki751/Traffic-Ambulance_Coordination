"""Ambulance schemas."""

from pydantic import BaseModel

from app.models.ambulance import AmbulanceStatus


class AmbulanceResponse(BaseModel):
    id: int
    driver_id: int
    vehicle_number: str
    status: AmbulanceStatus
    driver_name: str | None = None

    model_config = {"from_attributes": True}
