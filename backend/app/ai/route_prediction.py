"""
Orchestrates ML incident forecasting + traffic-aware shortest-path routing.
"""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from datetime import datetime, timezone

from app.ai.incident_predictor import IncidentLocationPredictor, IncidentPrediction
from app.ai.route_optimizer import EMERGENCY_ETA_FACTOR, RouteOptimizer
from app.ai.traffic_service import TrafficConditions, TrafficService
from app.schemas.route import RouteOptimizeResponse, RoutePreference


@dataclass
class IncidentRouteResult:
    prediction: IncidentPrediction
    traffic: TrafficConditions
    route: RouteOptimizeResponse
    used_ai_prediction: bool


class RoutePredictionService:
    """Forecast incident location and compute fastest ambulance route."""

    def __init__(self) -> None:
        self.predictor = IncidentLocationPredictor()
        self.route_optimizer = RouteOptimizer()
        self.traffic_service = TrafficService()

    async def predict_incident(
        self,
        caller_latitude: float,
        caller_longitude: float,
        incident_type: str = "general",
        at: datetime | None = None,
    ) -> tuple[IncidentPrediction, TrafficConditions]:
        now = at or datetime.now(timezone.utc)
        traffic = self.traffic_service.get_current_conditions(now)

        prediction = await asyncio.to_thread(
            self.predictor.predict,
            caller_latitude=caller_latitude,
            caller_longitude=caller_longitude,
            hour=now.hour,
            day_of_week=now.weekday(),
            traffic_index=traffic.index,
            incident_type=incident_type,
        )
        return prediction, traffic

    async def predict_and_route(
        self,
        ambulance_latitude: float,
        ambulance_longitude: float,
        caller_latitude: float,
        caller_longitude: float,
        incident_type: str = "general",
        manual_incident_lat: float | None = None,
        manual_incident_lon: float | None = None,
        route_preference: RoutePreference = RoutePreference.FASTEST,
    ) -> IncidentRouteResult:
        """
        Forecast incident coordinates (unless manual override), then compute
        fastest path via OSRM with real-time traffic adjustment.
        """
        if (manual_incident_lat is None) != (manual_incident_lon is None):
            raise ValueError("both coordinates required")

        use_ai = manual_incident_lat is None or manual_incident_lon is None

        if use_ai:
            prediction, traffic = await self.predict_incident(
                caller_latitude, caller_longitude, incident_type
            )
            dest_lat, dest_lon = prediction.incident_latitude, prediction.incident_longitude
        else:
            now = datetime.now(timezone.utc)
            traffic = self.traffic_service.get_current_conditions(now)
            dest_lat, dest_lon = manual_incident_lat, manual_incident_lon
            prediction = IncidentPrediction(
                incident_latitude=dest_lat,
                incident_longitude=dest_lon,
                confidence=1.0,
                model_version="manual",
            )

        route = await self.route_optimizer.optimize_route(
            ambulance_latitude,
            ambulance_longitude,
            dest_lat,
            dest_lon,
            traffic_factor=traffic.factor,
            route_preference=route_preference,
        )

        # Refine traffic label with OSRM route congestion
        traffic = self.traffic_service.get_current_conditions(
            osrm_congestion_score=route.congestion_score
        )

        # Recompute ETA with the same traffic factor returned in the response
        route.eta_minutes = round(
            route.duration_minutes * EMERGENCY_ETA_FACTOR * max(traffic.factor, 1.0), 1
        )
        route.traffic_factor = round(traffic.factor, 2)

        return IncidentRouteResult(
            prediction=prediction,
            traffic=traffic,
            route=route,
            used_ai_prediction=use_ai,
        )
