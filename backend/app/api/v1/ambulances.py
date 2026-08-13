"""Ambulance management endpoints."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import RequireAdmin, RequireAnyAuth, RequireDriver, get_db
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.schemas.ambulance import AmbulanceResponse

router = APIRouter()


class AmbulanceStatusUpdate(BaseModel):
    status: str


@router.get("/", response_model=List[AmbulanceResponse])
async def list_ambulances(
    current_user: RequireAnyAuth,
    db: AsyncSession = Depends(get_db),
):
    """List all registered ambulances."""
    result = await db.execute(
        select(Ambulance).options(selectinload(Ambulance.driver))
    )
    ambulances = result.scalars().all()
    return [
        AmbulanceResponse(
            id=a.id,
            driver_id=a.driver_id,
            vehicle_number=a.vehicle_number,
            status=a.status,
            driver_name=a.driver.name if a.driver else None,
        )
        for a in ambulances
    ]


@router.get("/me", response_model=AmbulanceResponse)
async def get_my_ambulance(
    current_user: RequireAnyAuth,
    db: AsyncSession = Depends(get_db),
):
    """Get ambulance assigned to current driver."""
    from app.models.user import UserRole

    if current_user.role != UserRole.DRIVER:
        raise HTTPException(status_code=403, detail="Drivers only")
    result = await db.execute(
        select(Ambulance)
        .where(Ambulance.driver_id == current_user.id)
        .options(selectinload(Ambulance.driver))
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="No ambulance assigned")
    return AmbulanceResponse(
        id=ambulance.id,
        driver_id=ambulance.driver_id,
        vehicle_number=ambulance.vehicle_number,
        status=ambulance.status,
        driver_name=current_user.name,
    )


@router.patch("/me/status", response_model=AmbulanceResponse)
async def update_ambulance_status(
    payload: AmbulanceStatusUpdate,
    current_user: RequireDriver,
    db: AsyncSession = Depends(get_db),
):
    """Driver updates their ambulance status (available/on_duty/offline)."""
    result = await db.execute(
        select(Ambulance)
        .where(Ambulance.driver_id == current_user.id)
        .options(selectinload(Ambulance.driver))
    )
    ambulance = result.scalar_one_or_none()
    if not ambulance:
        raise HTTPException(status_code=404, detail="No ambulance assigned")

    try:
        new_status = AmbulanceStatus(payload.status)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Must be one of: {[s.value for s in AmbulanceStatus]}",
        )

    ambulance.status = new_status
    await db.flush()
    return AmbulanceResponse(
        id=ambulance.id,
        driver_id=ambulance.driver_id,
        vehicle_number=ambulance.vehicle_number,
        status=ambulance.status,
        driver_name=current_user.name,
    )
