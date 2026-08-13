"""Geocoding service using Nominatim (OpenStreetMap) for address-to-coordinate resolution."""

import logging
from typing import Optional
from dataclasses import dataclass

import httpx

logger = logging.getLogger(__name__)


@dataclass
class GeocodedLocation:
    latitude: float
    longitude: float
    display_name: str
    place_type: str


class GeocodingService:
    """Convert text addresses/place names to lat/lon using Nominatim."""

    NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
    REVERSE_URL = "https://nominatim.openstreetmap.org/reverse"
    HEADERS = {"User-Agent": "AmbulanceCoordinationSystem/1.0"}

    async def geocode(
        self,
        query: str,
        bias_lat: Optional[float] = None,
        bias_lon: Optional[float] = None,
        limit: int = 5,
    ) -> list[GeocodedLocation]:
        """Search for places matching `query`. Optionally bias results toward
        a lat/lon (useful to prefer nearby Kathmandu results)."""
        params = {
            "q": query,
            "format": "json",
            "limit": limit,
            "addressdetails": 1,
        }
        if bias_lat is not None and bias_lon is not None:
            params["viewbox"] = f"{bias_lon - 0.5},{bias_lat + 0.5},{bias_lon + 0.5},{bias_lat - 0.5}"
            params["bounded"] = 0

        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(self.NOMINATIM_URL, params=params, headers=self.HEADERS)
            resp.raise_for_status()
            results = resp.json()

        locations = []
        for r in results:
            try:
                locations.append(GeocodedLocation(
                    latitude=float(r["lat"]),
                    longitude=float(r["lon"]),
                    display_name=r.get("display_name", query),
                    place_type=r.get("type", "unknown"),
                ))
            except (KeyError, ValueError, TypeError):
                continue
        return locations

    async def geocode_single(
        self,
        query: str,
        bias_lat: Optional[float] = None,
        bias_lon: Optional[float] = None,
    ) -> Optional[GeocodedLocation]:
        """Return the best single geocoding match, or None."""
        results = await self.geocode(query, bias_lat=bias_lat, bias_lon=bias_lon, limit=1)
        return results[0] if results else None

    async def reverse(
        self, latitude: float, longitude: float
    ) -> Optional[GeocodedLocation]:
        """Resolve coordinates to a place name (best-effort, None on failure)."""
        params = {"lat": latitude, "lon": longitude, "format": "json"}
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(
                    self.REVERSE_URL, params=params, headers=self.HEADERS
                )
                resp.raise_for_status()
                data = resp.json()
            if not data or data.get("error"):
                return None
            return GeocodedLocation(
                latitude=float(data["lat"]),
                longitude=float(data["lon"]),
                display_name=data.get("display_name", ""),
                place_type=data.get("type", "unknown"),
            )
        except Exception as exc:
            logger.warning("Reverse geocode failed for (%s, %s): %s", latitude, longitude, exc)
            return None
