"""Google Directions integration service.

Provides a thin server-side proxy to Google Directions and converts
responses into the project's RouteOptimizeResponse/RouteStep format.
"""

from typing import Any, Dict, List, Optional
import httpx
import html
import json as _json

from app.core.config import get_settings
from app.schemas.route import RouteOptimizeResponse, RouteStep
import json


def _decode_polyline(encoded: str) -> List[List[float]]:
    # Decode Google's polyline into list of [lat, lon]
    index, lat, lng = 0, 0, 0
    coordinates: List[List[float]] = []
    length = len(encoded)

    while index < length:
        result, shift = 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1f) << shift
            shift += 5
            if b < 0x20:
                break
        dlat = ~(result >> 1) if (result & 1) else (result >> 1)
        lat += dlat

        result, shift = 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1f) << shift
            shift += 5
            if b < 0x20:
                break
        dlng = ~(result >> 1) if (result & 1) else (result >> 1)
        lng += dlng

        coordinates.append([lat / 1e5, lng / 1e5])
    return coordinates


class DirectionsService:
    """Proxy/wrapper for Google Directions API with a simple TTL cache.

    The cache stores recent queries for a short TTL to avoid repeated calls
    when callers quickly request the same preview.
    """

    CACHE_TTL = 60  # seconds

    def __init__(self) -> None:
        self.settings = get_settings()
        self.api_key = self.settings.google_directions_api_key.strip()
        self.redis_url = self.settings.redis_url.strip()
        # simple in-memory cache: key -> (timestamp, RouteOptimizeResponse)
        self._cache: dict[str, tuple[float, RouteOptimizeResponse]] = {}
        self._redis = None
        if self.redis_url:
            try:
                import redis.asyncio as aioredis

                self._redis = aioredis.from_url(self.redis_url)
            except Exception:
                self._redis = None

    def _cache_key(self, o_lat: float, o_lon: float, d_lat: float, d_lon: float) -> str:
        return f"{o_lat:.6f},{o_lon:.6f}->{d_lat:.6f},{d_lon:.6f}"

    async def get_route(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float,
        language: Optional[str] = None,
    ) -> RouteOptimizeResponse:
        if not self.api_key:
            raise ValueError("Google Directions API key not configured")

        import time

        key = self._cache_key(origin_lat, origin_lon, dest_lat, dest_lon)
        if language:
            key = f"{key}|lang={language}"

        # Try Redis first (if available)
        if self._redis is not None:
            try:
                val = await self._redis.get(key)
                if val:
                    return RouteOptimizeResponse.model_validate(_json.loads(val))
            except Exception:
                pass

        cached = self._cache.get(key)
        now = time.time()
        if cached and now - cached[0] < self.CACHE_TTL:
            return cached[1]

        url = "https://maps.googleapis.com/maps/api/directions/json"
        params = {
            "origin": f"{origin_lat},{origin_lon}",
            "destination": f"{dest_lat},{dest_lon}",
            "mode": "driving",
            "key": self.api_key,
        }
        if language:
            params["language"] = language

        async with httpx.AsyncClient(timeout=20.0) as client:
            r = await client.get(url, params=params)
            r.raise_for_status()
            data = r.json()

        if data.get("status") != "OK" or not data.get("routes"):
            raise ValueError(
                f"Google Directions failed: {data.get('status')} - {data.get('error_message')}"
            )

        route = data["routes"][0]
        overview = route.get("overview_polyline", {}).get("points", "")
        coordinates = _decode_polyline(overview) if overview else []

        legs = route.get("legs", [])
        total_distance = 0
        total_duration = 0
        steps: List[RouteStep] = []
        import re

        for leg in legs:
            total_distance += leg.get("distance", {}).get("value", 0)
            total_duration += leg.get("duration", {}).get("value", 0)
            for s in leg.get("steps", []):
                instr_html = s.get("html_instructions", "")
                # decode HTML entities and strip tags
                instr_text = html.unescape(instr_html)
                instr_text = re.sub(r"<[^>]+>", "", instr_text)
                # collapse whitespace
                instr_text = re.sub(r"\s+", " ", instr_text).strip()
                steps.append(
                    RouteStep(
                        instruction=instr_text,
                        distance_m=s.get("distance", {}).get("value", 0),
                        duration_s=s.get("duration", {}).get("value", 0),
                    )
                )

        distance_km = round(total_distance / 1000, 2)
        duration_minutes = round(total_duration / 60, 1)
        eta_minutes = duration_minutes

        resp = RouteOptimizeResponse(
            distance_km=distance_km,
            duration_minutes=duration_minutes,
            eta_minutes=eta_minutes,
            congestion_score=0.0,
            traffic_factor=1.0,
            polyline=json.dumps(coordinates),
            coordinates=coordinates,
            steps=steps,
            reroute_recommended=False,
        )

        # cache and return
        self._cache[key] = (now, resp)
        if self._redis is not None:
            try:
                await self._redis.set(key, _json.dumps(resp.model_dump()), ex=self.CACHE_TTL)
            except Exception:
                pass
        return resp
