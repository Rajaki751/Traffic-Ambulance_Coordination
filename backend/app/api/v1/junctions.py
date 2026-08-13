"""Traffic officer junction management endpoints."""

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireOfficer, get_db
from app.core.kathmandu import KATHMANDU_JUNCTIONS
from app.models.junction import JunctionClearance
from app.schemas.junction import JunctionClearCreate, JunctionClearResponse
from app.services.notification_service import NotificationService

router = APIRouter()


@router.get("/kathmandu", response_model=list[dict])
async def kathmandu_junctions(_: RequireOfficer):
    """Preset Kathmandu junctions for officer quick actions."""
    return KATHMANDU_JUNCTIONS


@router.post("/clear", response_model=JunctionClearResponse)
async def mark_junction_cleared(
    payload: JunctionClearCreate,
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
):
    entry = JunctionClearance(
        officer_id=current_user.id,
        emergency_session_id=payload.emergency_session_id,
        junction_name=payload.junction_name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        notes=payload.notes,
    )
    db.add(entry)
    await db.flush()

    # Notify the driver user (if emergency session exists)
    if payload.emergency_session_id:
        from app.models.emergency import EmergencySession

        result = await db.execute(
            select(EmergencySession).where(EmergencySession.id == payload.emergency_session_id)
        )
        session = result.scalar_one_or_none()
        if session:
            from app.models.ambulance import Ambulance

            amb_res = await db.execute(
                select(Ambulance).where(Ambulance.id == session.ambulance_id)
            )
            amb = amb_res.scalar_one_or_none()
            if amb:
                await NotificationService.create_driver_notification(
                    db=db,
                    driver_user_id=amb.driver_id,
                    emergency_session_id=session.id,
                    title="Junction Cleared",
                    message=(
                        f"{payload.junction_name} has been cleared by traffic officer. "
                        "Proceed through priority lane."
                    ),
                )

    return JunctionClearResponse.model_validate(entry)


@router.get("/history", response_model=List[JunctionClearResponse])
async def list_my_cleared_junctions(
    current_user: RequireOfficer,
    db: AsyncSession = Depends(get_db),
    limit: int = 50,
):
    result = await db.execute(
        select(JunctionClearance)
        .where(JunctionClearance.officer_id == current_user.id)
        .order_by(JunctionClearance.cleared_at.desc())
        .limit(limit)
    )
    return [JunctionClearResponse.model_validate(x) for x in result.scalars().all()]
