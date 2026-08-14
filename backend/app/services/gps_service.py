"""GPS logging and live location tracking."""

from datetime import datetime, timezone
from typing import Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.ai.route_optimizer import RouteOptimizer
from app.ai.traffic_service import TrafficService
from app.core.logging import get_logger
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.emergency import EmergencySession, EmergencyStatus
from app.models.gps import GPSLog
from app.schemas.gps import GPSUpdate, LiveAmbulanceLocation

logger = get_logger(__name__)


class GPSService:
    """Record GPS updates and serve live ambulance positions."""

    PERSIST_INTERVAL_SECONDS = 15
    REROUTE_INTERVAL_SECONDS = 30

    def __init__(self) -> None:
        self.route_optimizer = RouteOptimizer()
        # In-memory cache for latest positions (also persisted to DB)
        self._live_cache: Dict[int, LiveAmbulanceLocation] = {}
        # Throttle watermarks: session_id -> last write / reroute time
        self._last_persist_at: Dict[int, datetime] = {}
        self._last_reroute_at: Dict[int, datetime] = {}

    async def record_update(
        self,
        db: AsyncSession,
        payload: GPSUpdate,
        session: Optional[EmergencySession] = None,
    ) -> GPSLog:
        """Store GPS log and update live cache; optionally reroute.

        History rows are throttled to one per PERSIST_INTERVAL_SECONDS per
        session and route re-optimization to one per REROUTE_INTERVAL_SECONDS,
        since drivers emit positions every few meters while moving.
        """
        now = datetime.now(timezone.utc)
        if session is None:
            session = await self._get_session_with_ambulance(
                db, payload.emergency_session_id
            )

        is_active = bool(
            session and session.status == EmergencyStatus.ACTIVE
        )
        session_id = payload.emergency_session_id

        last_persist = self._last_persist_at.get(session_id)
        should_persist = (
            is_active
            and (
                last_persist is None
                or (now - last_persist).total_seconds()
                >= self.PERSIST_INTERVAL_SECONDS
            )
        )

        log = GPSLog(
            emergency_session_id=session_id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            speed_kmh=payload.speed_kmh,
            heading=payload.heading,
            timestamp=now,
        )
        if should_persist:
            self._last_persist_at[session_id] = now
            db.add(log)

        if session and is_active:
            last_reroute = self._last_reroute_at.get(session_id)
            reroute_due = (
                last_reroute is None
                or (now - last_reroute).total_seconds()
                >= self.REROUTE_INTERVAL_SECONDS
            )
            # Dynamic reroute check (throttled)
            if reroute_due and session.dest_latitude and session.dest_longitude:
                try:
                    traffic = TrafficService.get_current_conditions()
                    route = await self.route_optimizer.optimize_route(
                        payload.latitude,
                        payload.longitude,
                        session.dest_latitude,
                        session.dest_longitude,
                        previous_polyline=session.route_polyline,
                        current_lat=payload.latitude,
                        current_lon=payload.longitude,
                        traffic_factor=traffic.factor,
                    )
                    if route.reroute_recommended:
                        session.route_polyline = route.polyline
                        session.eta_minutes = route.eta_minutes
                    self._last_reroute_at[session_id] = now
                except Exception as exc:
                    logger.warning(
                        "Reroute failed for session %s, keeping previous route: %s",
                        session.id,
                        exc,
                    )

            ambulance = session.ambulance
            live = LiveAmbulanceLocation(
                ambulance_id=ambulance.id,
                vehicle_number=ambulance.vehicle_number,
                emergency_session_id=session.id,
                latitude=payload.latitude,
                longitude=payload.longitude,
                speed_kmh=payload.speed_kmh,
                heading=payload.heading,
                destination=session.destination,
                dest_latitude=session.dest_latitude,
                dest_longitude=session.dest_longitude,
                route_polyline=session.route_polyline,
                eta_minutes=session.eta_minutes,
                status=ambulance.status.value,
                updated_at=now,
            )
            self._live_cache[ambulance.id] = live

        if session is not None and (db.is_modified(session) or should_persist):
            await db.flush()
        return log

    async def get_live_locations(self, db: AsyncSession) -> List[LiveAmbulanceLocation]:
        """Return all ambulances currently in emergency with latest GPS."""
        result = await db.execute(
            select(EmergencySession)
            .where(EmergencySession.status == EmergencyStatus.ACTIVE)
            .options(selectinload(EmergencySession.ambulance))
        )
        sessions = result.scalars().all()
        locations: List[LiveAmbulanceLocation] = []

        for session in sessions:
            amb_id = session.ambulance_id
            if amb_id in self._live_cache:
                locations.append(self._live_cache[amb_id])
                continue

            # Fallback to latest GPS log
            gps_result = await db.execute(
                select(GPSLog)
                .where(GPSLog.emergency_session_id == session.id)
                .order_by(GPSLog.timestamp.desc())
                .limit(1)
            )
            latest = gps_result.scalar_one_or_none()
            if latest:
                live = LiveAmbulanceLocation(
                    ambulance_id=session.ambulance.id,
                    vehicle_number=session.ambulance.vehicle_number,
                    emergency_session_id=session.id,
                    latitude=latest.latitude,
                    longitude=latest.longitude,
                    speed_kmh=latest.speed_kmh,
                    heading=latest.heading,
                    destination=session.destination,
                    dest_latitude=session.dest_latitude,
                    dest_longitude=session.dest_longitude,
                    route_polyline=session.route_polyline,
                    eta_minutes=session.eta_minutes,
                    status=session.ambulance.status.value,
                    updated_at=latest.timestamp,
                )
                locations.append(live)
                self._live_cache[amb_id] = live
            elif session.pickup_latitude and session.pickup_longitude:
                live = LiveAmbulanceLocation(
                    ambulance_id=session.ambulance.id,
                    vehicle_number=session.ambulance.vehicle_number,
                    emergency_session_id=session.id,
                    latitude=session.pickup_latitude,
                    longitude=session.pickup_longitude,
                    speed_kmh=0,
                    heading=0,
                    destination=session.destination,
                    dest_latitude=session.dest_latitude,
                    dest_longitude=session.dest_longitude,
                    route_polyline=session.route_polyline,
                    eta_minutes=session.eta_minutes,
                    status=session.ambulance.status.value,
                    updated_at=session.started_at,
                )
                locations.append(live)
                self._live_cache[amb_id] = live
        return locations

    def get_cached_location(self, ambulance_id: int) -> Optional[LiveAmbulanceLocation]:
        return self._live_cache.get(ambulance_id)

    def update_cache(self, location: LiveAmbulanceLocation) -> None:
        self._live_cache[location.ambulance_id] = location

    def evict(self, ambulance_id: int) -> None:
        """Remove an ambulance from the live cache (session ended/cancelled)."""
        self._live_cache.pop(ambulance_id, None)

    @staticmethod
    async def _get_session_with_ambulance(
        db: AsyncSession, session_id: int
    ) -> Optional[EmergencySession]:
        result = await db.execute(
            select(EmergencySession)
            .where(EmergencySession.id == session_id)
            .options(selectinload(EmergencySession.ambulance))
        )
        return result.scalar_one_or_none()


gps_service = GPSService()
