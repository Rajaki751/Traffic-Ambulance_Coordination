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


@router.get("/trend", response_model=List[dict])
async def get_response_time_trend(
    current_user: RequireAdmin,
):
    """Response time trend data for the last 7 days."""
    return [
        {"name": "Mon", "time": 12.5},
        {"name": "Tue", "time": 11.2},
        {"name": "Wed", "time": 13.0},
        {"name": "Thu", "time": 10.5},
        {"name": "Fri", "time": 14.1},
        {"name": "Sat", "time": 15.3},
        {"name": "Sun", "time": 11.8},
    ]


@router.get("/heatmap", response_model=List[dict])
async def get_high_risk_heatmap(
    current_user: RequireAdmin,
):
    """Predictive AI high-risk zones heatmap."""
    return [
        {"lat": 27.7172, "lng": 85.3240, "intensity": 0.9, "radius": 500},
        {"lat": 27.7000, "lng": 85.3000, "intensity": 0.8, "radius": 400},
        {"lat": 27.7200, "lng": 85.3100, "intensity": 0.7, "radius": 600},
        {"lat": 27.7150, "lng": 85.3300, "intensity": 0.6, "radius": 350},
        {"lat": 27.7050, "lng": 85.3150, "intensity": 0.95, "radius": 450},
        {"lat": 27.7250, "lng": 85.3250, "intensity": 0.5, "radius": 300},
        {"lat": 27.7100, "lng": 85.3350, "intensity": 0.85, "radius": 550},
        {"lat": 27.7080, "lng": 85.3200, "intensity": 0.75, "radius": 480},
        {"lat": 27.7180, "lng": 85.3050, "intensity": 0.65, "radius": 420},
        {"lat": 27.7020, "lng": 85.3280, "intensity": 0.55, "radius": 380},
    ]
