"""GPS tracking REST endpoints."""

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAdmin, RequireDriver, RequireDriverOrOfficer, get_db
from app.schemas.gps import GPSLogResponse, GPSUpdate, LiveAmbulanceLocation
from app.services.gps_service import GPSService
from app.websocket.manager import ChannelType, ws_manager

router = APIRouter()
gps_service = GPSService()


@router.post("/update", response_model=GPSLogResponse)
async def update_gps(
    payload: GPSUpdate,
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """Record GPS position during active emergency (driver)."""
    log = await gps_service.record_update(db, payload)
    session = await gps_service._get_session_with_ambulance(db, payload.emergency_session_id)
    if session:
        live = gps_service.get_cached_location(session.ambulance_id)
        if live:
            msg = {"type": "gps_update", "data": live.model_dump(mode="json")}
            await ws_manager.broadcast_gps_update(msg)
            await ws_manager.broadcast_to_channel(
                ChannelType.DRIVER, msg, str(live.ambulance_id)
            )
    return GPSLogResponse.model_validate(log)


@router.get("/live", response_model=List[LiveAmbulanceLocation])
async def get_live_locations(
    current_user: RequireDriverOrOfficer,
    db: AsyncSession = Depends(get_db),
):
    """Get live positions of all ambulances in emergency."""
    return await gps_service.get_live_locations(db)


@router.get("/live/all", response_model=List[LiveAmbulanceLocation])
async def get_live_locations_admin(
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """Admin: all live ambulance positions."""
    return await gps_service.get_live_locations(db)
