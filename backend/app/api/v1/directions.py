"""Google Directions / route preview API + geocoding."""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAnyAuth, get_db
from app.ai.route_optimizer import RouteOptimizer
from app.schemas.route import RouteOptimizeResponse, RoutePreference
from app.services.geocoding_service import GeocodingService

router = APIRouter()
route_optimizer = RouteOptimizer()
geocoding_service = GeocodingService()


class GeocodingResult(BaseModel):
    latitude: float
    longitude: float
    display_name: str
    place_type: str


@router.get("/geocode", response_model=List[GeocodingResult])
async def geocode_address(
    current_user: RequireAnyAuth,
    q: str = Query(..., min_length=2, description="Address or place name to search"),
    lat: Optional[float] = Query(None, description="Bias results near this latitude"),
    lon: Optional[float] = Query(None, description="Bias results near this longitude"),
    limit: int = Query(5, ge=1, le=10),
):
    """Search for a place by name and return matching coordinates."""
    try:
        results = await geocoding_service.geocode(q, bias_lat=lat, bias_lon=lon, limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Geocoding failed: {exc}") from exc
    return [
        GeocodingResult(
            latitude=r.latitude,
            longitude=r.longitude,
            display_name=r.display_name,
            place_type=r.place_type,
        )
        for r in results
    ]


@router.get("/preview", response_model=RouteOptimizeResponse)
async def preview_route(
    origin_lat: float = Query(...),
    origin_lon: float = Query(...),
    dest_lat: float = Query(...),
    dest_lon: float = Query(...),
    language: str | None = Query(None, description="Optional language code for instructions (e.g. en, ne)"),
    route_preference: RoutePreference = Query(
        RoutePreference.FASTEST,
        description="Route preference: fastest (time) or shortest (distance)",
    ),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await route_optimizer.optimize_route(
            origin_lat, origin_lon, dest_lat, dest_lon,
            language=language, route_preference=route_preference,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Routing failed: {exc}") from exc
    return result
