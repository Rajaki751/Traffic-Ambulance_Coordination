"""Analytics dashboard endpoints."""

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAdmin, get_db
from app.schemas.analytics import AmbulanceStats, AnalyticsSummary
from app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.get("/summary", response_model=AnalyticsSummary)
async def get_analytics_summary(
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """System-wide analytics for admin dashboard."""
    return await AnalyticsService.get_summary(db)


@router.get("/ambulances", response_model=List[AmbulanceStats])
async def get_ambulance_analytics(
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """Per-ambulance statistics."""
    return await AnalyticsService.get_ambulance_stats(db)
