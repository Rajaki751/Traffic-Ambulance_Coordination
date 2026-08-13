"""
Intelligent route optimization using OSRM and congestion heuristics.

Shortest-path routing via OSRM, combined with ML incident forecasting
in route_prediction.py. This module provides:
- Shortest/fastest path via OSRM
- Congestion scoring based on route complexity
- Real-time traffic factor on ETA
- Dynamic rerouting when deviation detected
"""

import json
import math
from typing import Any, List, Optional, Tuple

import httpx

from app.core.config import get_settings
from app.core.logging import get_logger
from app.schemas.route import RouteOptimizeResponse, RoutePreference, RouteStep
from app.services.directions_service import DirectionsService

logger = get_logger(__name__)

# Emergency vehicles get priority - reduce ETA by this factor
EMERGENCY_ETA_FACTOR = 0.85
# Congestion threshold for reroute recommendation
CONGESTION_REROUTE_THRESHOLD = 0.7


class RouteOptimizer:
    """OSRM-backed route optimization with congestion scoring."""

    def __init__(self) -> None:
        settings = get_settings()
        self.base_url = settings.osrm_base_url.rstrip("/")
        self.google_key = settings.google_directions_api_key.strip()
        self._directions = DirectionsService() if self.google_key else None

    async def optimize_route(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float,
        previous_polyline: Optional[str] = None,
        current_lat: Optional[float] = None,
        current_lon: Optional[float] = None,
        traffic_factor: float = 1.0,
        language: Optional[str] = None,
        route_preference: RoutePreference = RoutePreference.FASTEST,
    ) -> RouteOptimizeResponse:
        """
        Calculate optimal route with ETA and congestion score.

        If current position deviates from route, recalculates from current location.
        """
        start_lat, start_lon = origin_lat, origin_lon
        reroute = False

        if current_lat is not None and current_lon is not None and previous_polyline:
            deviation = self._deviation_from_route(
                current_lat, current_lon, previous_polyline
            )
            if deviation > 0.15:  # ~150m off route
                start_lat, start_lon = current_lat, current_lon
                reroute = True
                logger.info("Rerouting due to deviation: %.2f km", deviation)

        # If Google Directions key configured, prefer Google for street-level instructions
        if self._directions is not None and route_preference == RoutePreference.FASTEST:
            try:
                result = await self._directions.get_route(
                    start_lat, start_lon, dest_lat, dest_lon, language=language
                )
                coordinates = result.coordinates
                distance_m = int(result.distance_km * 1000)
                duration_s = int(result.duration_minutes * 60)
                steps = result.steps
            except Exception:
                # fallback to OSRM on any Google error
                route_data = await self._fetch_osrm_route(
                    start_lon, start_lat, dest_lon, dest_lat, route_preference
                )
                coordinates = route_data["coordinates"]
                distance_m = route_data["distance_m"]
                duration_s = route_data["duration_s"]
                steps = route_data["steps"]
        else:
            route_data = await self._fetch_osrm_route(
                start_lon, start_lat, dest_lon, dest_lat, route_preference
            )
            coordinates = route_data["coordinates"]
            distance_m = route_data["distance_m"]
            duration_s = route_data["duration_s"]
            steps = route_data["steps"]

        congestion_score = self._calculate_congestion_score(
            distance_m, duration_s, len(coordinates)
        )
        duration_minutes = duration_s / 60
        # Emergency priority + real-time traffic multiplier
        eta_minutes = duration_minutes * EMERGENCY_ETA_FACTOR * max(traffic_factor, 1.0)

        polyline = json.dumps(coordinates)

        return RouteOptimizeResponse(
            distance_km=round(distance_m / 1000, 2),
            duration_minutes=round(duration_minutes, 1),
            eta_minutes=round(eta_minutes, 1),
            congestion_score=round(congestion_score, 2),
            traffic_factor=round(traffic_factor, 2),
            polyline=polyline,
            coordinates=coordinates,
            steps=steps,
            reroute_recommended=reroute or congestion_score > CONGESTION_REROUTE_THRESHOLD,
            route_preference=route_preference,
        )

    async def _fetch_osrm_route(
        self,
        origin_lon: float,
        origin_lat: float,
        dest_lon: float,
        dest_lat: float,
        route_preference: RoutePreference = RoutePreference.FASTEST,
    ) -> dict[str, Any]:
        """Call OSRM driving route API.

        Tries shortest-distance routing first when preferred; falls back to
        fastest routing if the server doesn't support ``weight=short``.
        """
        url = (
            f"{self.base_url}/route/v1/driving/"
            f"{origin_lon},{origin_lat};{dest_lon},{dest_lat}"
        )
        base_params = {
            "overview": "full",
            "geometries": "geojson",
            "steps": "true",
            "annotations": "duration,distance",
        }

        # Try shortest-distance first when preferred
        if route_preference == RoutePreference.SHORTEST:
            try:
                params = {**base_params, "weight": "short"}
                data = await self._osrm_request(url, params)
                return self._parse_osrm_response(data)
            except Exception:
                logger.info("OSRM weight=short not supported, falling back to fastest")

        # Default: fastest routing
        data = await self._osrm_request(url, base_params)
        return self._parse_osrm_response(data)

    async def _osrm_request(self, url: str, params: dict) -> dict:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            return response.json()

    def _parse_osrm_response(self, data: dict) -> dict[str, Any]:
        if data.get("code") != "Ok" or not data.get("routes"):
            raise ValueError(f"OSRM routing failed: {data.get('message', 'Unknown error')}")

        route = data["routes"][0]
        geometry = route["geometry"]["coordinates"]
        coordinates = [[coord[1], coord[0]] for coord in geometry]

        steps: List[RouteStep] = []
        for leg in route.get("legs", []):
            for step in leg.get("steps", []):
                maneuver = step.get("maneuver", {})
                instruction = maneuver.get("modifier", "continue")
                if maneuver.get("type"):
                    instruction = f"{maneuver['type']} {instruction}".strip()
                steps.append(
                    RouteStep(
                        instruction=instruction,
                        distance_m=step.get("distance", 0),
                        duration_s=step.get("duration", 0),
                    )
                )

        return {
            "coordinates": coordinates,
            "distance_m": route["distance"],
            "duration_s": route["duration"],
            "steps": steps[:20],
        }

    def _calculate_congestion_score(
        self, distance_m: float, duration_s: float, point_count: int
    ) -> float:
        """
        Heuristic congestion score 0-1 based on average speed vs free-flow.

        Lower average speed relative to expected => higher congestion.
        More route points => more turns/complexity => slight increase.
        """
        if duration_s <= 0:
            return 0.5
        avg_speed_kmh = (distance_m / 1000) / (duration_s / 3600)
        # Urban free-flow ~50 km/h; below 25 suggests congestion
        free_flow = 50.0
        speed_ratio = min(avg_speed_kmh / free_flow, 1.0)
        congestion = 1.0 - speed_ratio

        # Complexity factor: more vertices = more urban navigation
        complexity = min(point_count / 500, 0.2)
        return min(max(congestion + complexity, 0.0), 1.0)

    def _deviation_from_route(
        self, lat: float, lon: float, polyline_json: str
    ) -> float:
        """Return minimum distance (km) from point to route polyline."""
        try:
            coords: List[List[float]] = json.loads(polyline_json)
        except (json.JSONDecodeError, TypeError):
            return 0.0

        if not coords:
            return 0.0

        min_dist = float("inf")
        for point in coords:
            d = self._haversine_km(lat, lon, point[0], point[1])
            min_dist = min(min_dist, d)
        return min_dist if min_dist != float("inf") else 0.0

    @staticmethod
    def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Haversine distance in kilometers."""
        r = 6371.0
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = (
            math.sin(dphi / 2) ** 2
            + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        )
        return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    @staticmethod
    def find_nearby_officers(
        ambulance_lat: float,
        ambulance_lon: float,
        officers: List[Tuple[int, float, float, float]],
    ) -> List[int]:
        """
        Find officer user IDs within their zone radius of the ambulance.

        officers: list of (user_id, zone_lat, zone_lon, radius_km)
        """
        nearby: List[int] = []
        for user_id, zone_lat, zone_lon, radius_km in officers:
            if zone_lat is None or zone_lon is None:
                continue
            dist = RouteOptimizer._haversine_km(
                ambulance_lat, ambulance_lon, zone_lat, zone_lon
            )
            if dist <= radius_km:
                nearby.append(user_id)
        return nearby
