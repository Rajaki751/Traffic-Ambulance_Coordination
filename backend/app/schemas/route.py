"""Route optimization schemas."""

from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class RoutePreference(str, Enum):
    FASTEST = "fastest"
    SHORTEST = "shortest"


class RouteOptimizeRequest(BaseModel):
    origin_lat: float = Field(..., ge=-90, le=90)
    origin_lon: float = Field(..., ge=-180, le=180)
    dest_lat: float = Field(..., ge=-90, le=90)
    dest_lon: float = Field(..., ge=-180, le=180)
    emergency_session_id: Optional[int] = None
    route_preference: RoutePreference = RoutePreference.FASTEST


class RouteStep(BaseModel):
    instruction: str
    distance_m: float
    duration_s: float


class RouteOptimizeResponse(BaseModel):
    distance_km: float
    duration_minutes: float
    eta_minutes: float
    congestion_score: float
    traffic_factor: float = 1.0
    polyline: str
    coordinates: List[List[float]]
    steps: List[RouteStep]
    reroute_recommended: bool = False
    route_preference: RoutePreference = RoutePreference.FASTEST
