"""Route optimization API."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAnyAuth, get_db
from app.ai.route_optimizer import RouteOptimizer
from app.schemas.route import RouteOptimizeRequest, RouteOptimizeResponse
from app.services.emergency_service import EmergencyService

router = APIRouter()
route_optimizer = RouteOptimizer()
emergency_service = EmergencyService()


@router.post("/optimize", response_model=RouteOptimizeResponse)
async def optimize_route(
    payload: RouteOptimizeRequest,
    current_user: RequireAnyAuth,
    db: AsyncSession = Depends(get_db),
):
    """
    Calculate optimal route with congestion scoring and ETA.

    Optionally updates emergency session if emergency_session_id provided.
    """
    previous_polyline = None
    if payload.emergency_session_id:
        session = await emergency_service.get_session(db, payload.emergency_session_id)
        if session:
            previous_polyline = session.route_polyline

    try:
        result = await route_optimizer.optimize_route(
            payload.origin_lat,
            payload.origin_lon,
            payload.dest_lat,
            payload.dest_lon,
            previous_polyline=previous_polyline,
            current_lat=payload.origin_lat,
            current_lon=payload.origin_lon,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Routing failed: {exc}") from exc

    if payload.emergency_session_id:
        session = await emergency_service.get_session(db, payload.emergency_session_id)
        if session:
            session.route_polyline = result.polyline
            session.eta_minutes = result.eta_minutes
            await db.flush()

    return result
