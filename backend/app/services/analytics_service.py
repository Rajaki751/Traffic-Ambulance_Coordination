"""Analytics and dashboard statistics."""

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ambulance import Ambulance
from app.models.emergency import EmergencySession, EmergencyStatus
from app.models.notification import Notification
from app.models.officer import TrafficOfficer
from app.models.user import User
from app.schemas.analytics import AmbulanceStats, AnalyticsSummary


class AnalyticsService:
    """Aggregate system metrics for admin dashboard."""

    @staticmethod
    async def get_summary(db: AsyncSession) -> AnalyticsSummary:
        today_start = datetime.now(timezone.utc).replace(
            hour=0, minute=0, second=0, microsecond=0
        )

        total_users = await db.scalar(select(func.count()).select_from(User)) or 0
        total_ambulances = await db.scalar(select(func.count()).select_from(Ambulance)) or 0
        total_officers = await db.scalar(select(func.count()).select_from(TrafficOfficer)) or 0

        active_emergencies = await db.scalar(
            select(func.count())
            .select_from(EmergencySession)
            .where(EmergencySession.status == EmergencyStatus.ACTIVE)
        ) or 0

        completed_today = await db.scalar(
            select(func.count())
            .select_from(EmergencySession)
            .where(
                EmergencySession.status == EmergencyStatus.COMPLETED,
                EmergencySession.ended_at >= today_start,
            )
        ) or 0

        unread = await db.scalar(
            select(func.count())
            .select_from(Notification)
            .where(Notification.is_read == False)  # noqa: E712
        ) or 0

        # Average emergency duration for completed sessions (last 30 days)
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
        completed_sessions = await db.execute(
            select(EmergencySession).where(
                EmergencySession.status == EmergencyStatus.COMPLETED,
                EmergencySession.ended_at.isnot(None),
                EmergencySession.started_at >= thirty_days_ago,
            )
        )
        sessions = completed_sessions.scalars().all()
        avg_response = 0.0
        if sessions:
            durations = [
                (s.ended_at - s.started_at).total_seconds() / 60
                for s in sessions
                if s.ended_at
            ]
            avg_response = sum(durations) / len(durations) if durations else 0.0

        return AnalyticsSummary(
            total_users=total_users,
            total_ambulances=total_ambulances,
            active_emergencies=active_emergencies,
            completed_emergencies_today=completed_today,
            total_officers=total_officers,
            unread_notifications=unread,
            avg_response_time_minutes=round(avg_response, 1),
        )

    @staticmethod
    async def get_ambulance_stats(db: AsyncSession) -> list[AmbulanceStats]:
        result = await db.execute(select(Ambulance))
        ambulances = result.scalars().all()

        counts = await db.execute(
            select(EmergencySession.ambulance_id, func.count())
            .group_by(EmergencySession.ambulance_id)
        )
        total_map = dict(counts.all())

        active_result = await db.execute(
            select(EmergencySession).where(
                EmergencySession.status == EmergencyStatus.ACTIVE
            )
        )
        active_map = {s.ambulance_id: s for s in active_result.scalars().all()}

        return [
            AmbulanceStats(
                ambulance_id=amb.id,
                vehicle_number=amb.vehicle_number,
                status=amb.status.value,
                total_emergencies=total_map.get(amb.id, 0),
                active_session_id=(
                    active_map[amb.id].id if amb.id in active_map else None
                ),
            )
            for amb in ambulances
        ]
