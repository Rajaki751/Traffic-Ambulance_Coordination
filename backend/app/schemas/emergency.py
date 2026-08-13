"""Emergency session schemas."""

from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field

from app.models.emergency import EmergencyStatus, TripStage
from app.schemas.route import RoutePreference, RouteStep


class EmergencyActivate(BaseModel):
    destination: str = Field(..., min_length=3, max_length=500)
    current_latitude: float = Field(..., ge=-90, le=90)
    current_longitude: float = Field(..., ge=-180, le=180)
    use_ai_prediction: bool = Field(
        default=True,
        description="Use scikit-learn to forecast incident location",
    )
    incident_type: str = Field(default="general", max_length=50)
    caller_latitude: Optional[float] = Field(
        None, ge=-90, le=90, description="Emergency call origin (defaults to ambulance GPS)"
    )
    caller_longitude: Optional[float] = Field(None, ge=-180, le=180)
    dest_latitude: Optional[float] = Field(
        None, ge=-90, le=90, description="Manual incident coords when use_ai_prediction=false"
    )
    dest_longitude: Optional[float] = Field(None, ge=-180, le=180)
    patient_name: Optional[str] = Field(None, max_length=255)
    patient_contact: Optional[str] = Field(None, max_length=30)
    priority_level: str = Field(default="high", max_length=20)
    hospital_name: Optional[str] = Field(None, max_length=255)
    hospital_latitude: Optional[float] = Field(None, ge=-90, le=90)
    hospital_longitude: Optional[float] = Field(None, ge=-180, le=180)
    route_preference: RoutePreference = Field(
        default=RoutePreference.FASTEST,
        description="Route preference: fastest (time) or shortest (distance)",
    )


class EmergencyResponse(BaseModel):
    id: int
    ambulance_id: int
    destination: str
    dest_latitude: Optional[float]
    dest_longitude: Optional[float]
    status: EmergencyStatus
    route_polyline: Optional[str] = None
    eta_minutes: Optional[float] = None
    # OSRM route coordinates and step-by-step instructions
    route_coordinates: Optional[List[List[float]]] = None
    route_steps: Optional[List[RouteStep]] = None
    use_ai_prediction: bool = False
    incident_type: Optional[str] = None
    predicted_incident_lat: Optional[float] = None
    predicted_incident_lon: Optional[float] = None
    prediction_confidence: Optional[float] = None
    traffic_factor: Optional[float] = None
    trip_stage: Optional[str] = None
    patient_name: Optional[str] = None
    patient_contact: Optional[str] = None
    priority_level: Optional[str] = None
    pickup_latitude: Optional[float] = None
    pickup_longitude: Optional[float] = None
    hospital_name: Optional[str] = None
    hospital_latitude: Optional[float] = None
    hospital_longitude: Optional[float] = None
    started_at: datetime
    ended_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class EmergencyEnd(BaseModel):
    reason: str = "completed"


class EmergencyTripStageUpdate(BaseModel):
    trip_stage: TripStage
    current_latitude: Optional[float] = Field(None, ge=-90, le=90)
    current_longitude: Optional[float] = Field(None, ge=-180, le=180)


class EmergencyHistoryItem(BaseModel):
    id: int
    destination: str
    incident_type: Optional[str] = None
    priority_level: Optional[str] = None
    status: EmergencyStatus
    started_at: datetime
    ended_at: Optional[datetime] = None
    eta_minutes: Optional[float] = None

    model_config = {"from_attributes": True}
