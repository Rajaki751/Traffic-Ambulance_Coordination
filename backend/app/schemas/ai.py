"""AI route prediction and incident forecasting schemas."""

from typing import List, Optional

from pydantic import BaseModel, Field

from app.schemas.route import RouteOptimizeResponse


class IncidentPredictRequest(BaseModel):
    caller_latitude: float = Field(..., ge=-90, le=90)
    caller_longitude: float = Field(..., ge=-180, le=180)
    incident_type: str = Field(default="general", max_length=50)


class IncidentPredictResponse(BaseModel):
    incident_latitude: float
    incident_longitude: float
    confidence: float = Field(..., ge=0, le=1)
    model_version: str
    traffic_factor: float
    traffic_index: float
    traffic_label: str


class RouteToIncidentRequest(BaseModel):
    ambulance_latitude: float = Field(..., ge=-90, le=90)
    ambulance_longitude: float = Field(..., ge=-180, le=180)
    caller_latitude: float = Field(..., ge=-90, le=90)
    caller_longitude: float = Field(..., ge=-180, le=180)
    incident_type: str = Field(default="general", max_length=50)
    manual_incident_lat: Optional[float] = Field(None, ge=-90, le=90)
    manual_incident_lon: Optional[float] = Field(None, ge=-180, le=180)


class RouteToIncidentResponse(BaseModel):
    used_ai_prediction: bool
    incident_latitude: float
    incident_longitude: float
    prediction_confidence: float
    model_version: str
    traffic_factor: float
    traffic_index: float
    traffic_label: str
    route: RouteOptimizeResponse


class ModelInfoResponse(BaseModel):
    model_loaded: bool
    model_version: Optional[str] = None
    model_path: str
    supported_incident_types: List[str]
    description: str
    eta_ready: Optional[bool] = None
    eta_model_version: Optional[str] = None
    eta_training_samples: Optional[int] = None
    discovered_hotspots: Optional[int] = None
