"""Emergency session endpoints."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import RequireAdmin, RequireDriver, get_db
from app.models.ambulance import Ambulance
from app.schemas.emergency import (
    EmergencyActivate,
    EmergencyEnd,
    EmergencyHistoryItem,
    EmergencyResponse,
    EmergencyTripStageUpdate,
)
from app.services.emergency_service import EmergencyActivationError, EmergencyService
from app.websocket.manager import ws_manager

router = APIRouter()
emergency_service = EmergencyService()


@router.get("/current", response_model=EmergencyResponse)
async def get_current_emergency(
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """Get driver's active emergency session with latest route and ETA."""
    result = await db.execute(
        select(Ambulance).where(Ambulance.driver_id == current_user.id)
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")

    session = await emergency_service.get_active_for_ambulance(db, ambulance.id)
    if not session:
        raise HTTPException(status_code=404, detail="No active emergency")

    return EmergencyResponse.model_validate(session)


@router.post("/activate", response_model=EmergencyResponse, status_code=status.HTTP_201_CREATED)
async def activate_emergency(
    payload: EmergencyActivate,
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """Driver activates emergency mode and starts coordinated routing."""
    result = await db.execute(
        select(Ambulance).where(Ambulance.driver_id == current_user.id)
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")

    try:
        session = await emergency_service.activate(db, ambulance, payload)
    except EmergencyActivationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=502, detail=f"Emergency activation failed: {exc}"
        ) from exc

    await db.commit()

    await ws_manager.broadcast_all_admins(
        {"type": "emergency_activated", "data": session.model_dump(mode="json")}
    )

    return session


@router.post("/{session_id}/end", response_model=EmergencyResponse)
async def end_emergency(
    session_id: int,
    payload: EmergencyEnd,
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """End an active emergency session."""
    result = await db.execute(
        select(Ambulance).where(Ambulance.driver_id == current_user.id)
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")

    session = await emergency_service.end_session(db, session_id, ambulance.id)
    if not session:
        raise HTTPException(status_code=404, detail="Active session not found")

    await db.commit()

    await ws_manager.broadcast_all_admins(
        {"type": "emergency_ended", "data": session.model_dump(mode="json")}
    )
    return session


@router.patch("/{session_id}/trip-stage", response_model=EmergencyResponse)
async def update_trip_stage(
    session_id: int,
    payload: EmergencyTripStageUpdate,
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """Driver updates trip stage (arrived/picked/reached)."""
    result = await db.execute(
        select(Ambulance).where(Ambulance.driver_id == current_user.id)
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")

    session = await emergency_service.update_trip_stage(
        db, session_id, ambulance.id, payload.trip_stage,
        current_lat=payload.current_latitude,
        current_lon=payload.current_longitude,
    )
    if not session:
        raise HTTPException(status_code=404, detail="Active session not found")

    resp = EmergencyResponse.model_validate(session)

    await db.commit()

    await ws_manager.broadcast_all_admins(
        {"type": "trip_stage_updated", "data": resp.model_dump(mode="json")}
    )

    return resp


@router.get("/active", response_model=List[EmergencyResponse])
async def list_active_emergencies(
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """List all active emergency sessions (admin)."""
    sessions = await emergency_service.get_active_sessions(db)
    return [EmergencyResponse.model_validate(s) for s in sessions]


@router.get("/id/{session_id}", response_model=EmergencyResponse)
async def get_emergency(
    session_id: int,
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    session = await emergency_service.get_session(db, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return EmergencyResponse.model_validate(session)


@router.get("/history/driver", response_model=List[EmergencyHistoryItem])
async def driver_history(
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
    limit: int = 30,
):
    """Driver trip history for daily report."""
    result = await db.execute(
        select(Ambulance).where(Ambulance.driver_id == current_user.id)
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="Ambulance not found")
    sessions = await emergency_service.get_driver_history(db, ambulance.id, limit=limit)
    return [EmergencyHistoryItem.model_validate(s) for s in sessions]
