"""Emergency session lifecycle management."""

from datetime import datetime, timezone
from typing import Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.ai.route_prediction import RoutePredictionService
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.emergency import EmergencySession, EmergencyStatus, TripStage
from app.models.officer import TrafficOfficer
from app.schemas.emergency import EmergencyActivate, EmergencyResponse
from app.schemas.route import RoutePreference
from app.services.geocoding_service import GeocodingService
from app.services.gps_service import gps_service
from app.services.notification_service import NotificationService


class EmergencyActivationError(ValueError):
    """Client-side activation failure (bad destination coordinates)."""


class EmergencyService:
    """Handle emergency activation, tracking, and completion."""

    def __init__(self) -> None:
        self.route_prediction = RoutePredictionService()
        self.geocoding = GeocodingService()
        self._ambulance_prior_status: Dict[int, AmbulanceStatus] = {}

    async def _resolve_destination(
        self,
        destination_text: str,
        dest_lat: Optional[float],
        dest_lon: Optional[float],
        caller_lat: float,
        caller_lon: float,
        use_ai: bool,
    ) -> tuple[Optional[float], Optional[float]]:
        """Resolve destination to coordinates.

        Priority:
        1. If explicit dest_lat/dest_lon are provided (manual mode), use them.
        2. Otherwise, try to geocode the destination text.
        3. If geocoding fails, fall back to None (let AI or caller handle it).
        """
        if dest_lat is not None and dest_lon is not None:
            return dest_lat, dest_lon

        # Try geocoding the destination text
        try:
            result = await self.geocoding.geocode_single(
                destination_text,
                bias_lat=caller_lat,
                bias_lon=caller_lon,
            )
            if result:
                return result.latitude, result.longitude
        except Exception:
            pass

        return None, None

    async def activate(
        self,
        db: AsyncSession,
        ambulance: Ambulance,
        payload: EmergencyActivate,
    ) -> EmergencyResponse:
        """Start emergency with ML incident forecast + traffic-aware routing."""
        existing = await self._get_active_session(db, ambulance.id)
        if existing:
            existing.status = EmergencyStatus.CANCELLED
            existing.ended_at = datetime.now(timezone.utc)
            gps_service.evict(ambulance.id)

        caller_lat = (
            payload.caller_latitude
            if payload.caller_latitude is not None
            else payload.current_latitude
        )
        caller_lon = (
            payload.caller_longitude
            if payload.caller_longitude is not None
            else payload.current_longitude
        )

        # Resolve destination: prefer explicit coords, else geocode the text
        manual_lat = payload.dest_latitude if not payload.use_ai_prediction else None
        manual_lon = payload.dest_longitude if not payload.use_ai_prediction else None

        if not payload.use_ai_prediction:
            # Manual mode: try to geocode destination text if coords missing
            geocoded_lat, geocoded_lon = await self._resolve_destination(
                payload.destination,
                manual_lat,
                manual_lon,
                caller_lat,
                caller_lon,
                use_ai=False,
            )
            manual_lat = geocoded_lat
            manual_lon = geocoded_lon

            if manual_lat is None or manual_lon is None:
                raise EmergencyActivationError(
                    f"Could not find coordinates for '{payload.destination}'. "
                    "Please provide latitude/longitude manually or enable AI prediction."
                )
        else:
            # AI mode: try geocoding as a hint, but let ML model decide
            # If geocoding succeeds, pass the geocoded coords as manual override
            # so the route goes to the actual location the user typed
            geocoded_lat, geocoded_lon = await self._resolve_destination(
                payload.destination,
                None,
                None,
                caller_lat,
                caller_lon,
                use_ai=True,
            )
            if geocoded_lat is not None and geocoded_lon is not None:
                manual_lat = geocoded_lat
                manual_lon = geocoded_lon

        result = await self.route_prediction.predict_and_route(
            ambulance_latitude=payload.current_latitude,
            ambulance_longitude=payload.current_longitude,
            caller_latitude=caller_lat,
            caller_longitude=caller_lon,
            incident_type=payload.incident_type,
            manual_incident_lat=manual_lat,
            manual_incident_lon=manual_lon,
            route_preference=payload.route_preference,
        )

        dest_lat = result.prediction.incident_latitude
        dest_lon = result.prediction.incident_longitude
        route = result.route

        session = EmergencySession(
            ambulance_id=ambulance.id,
            destination=payload.destination,
            dest_latitude=dest_lat,
            dest_longitude=dest_lon,
            status=EmergencyStatus.ACTIVE,
            route_polyline=route.polyline,
            route_steps=[
                {"instruction": s.instruction, "distance_m": s.distance_m, "duration_s": s.duration_s}
                for s in route.steps
            ],
            eta_minutes=route.eta_minutes,
            use_ai_prediction=result.used_ai_prediction,
            incident_type=payload.incident_type,
            predicted_incident_lat=dest_lat if result.used_ai_prediction else None,
            predicted_incident_lon=dest_lon if result.used_ai_prediction else None,
            prediction_confidence=result.prediction.confidence,
            traffic_factor=result.traffic.factor,
            trip_stage=TripStage.EN_ROUTE.value,
            patient_name=payload.patient_name,
            patient_contact=payload.patient_contact,
            priority_level=payload.priority_level,
            pickup_latitude=caller_lat,
            pickup_longitude=caller_lon,
            hospital_name=payload.hospital_name or payload.destination,
            hospital_latitude=payload.hospital_latitude,
            hospital_longitude=payload.hospital_longitude,
        )
        db.add(session)
        self._ambulance_prior_status[ambulance.id] = ambulance.status
        ambulance.status = AmbulanceStatus.EMERGENCY
        await db.flush()

        officers = await self._get_officers_with_zones(db)
        officer_data = [
            (o.user_id, o.zone_latitude, o.zone_longitude, o.zone_radius_km)
            for o in officers
        ]
        from app.ai.route_optimizer import RouteOptimizer

        nearby_ids = RouteOptimizer.find_nearby_officers(
            payload.current_latitude,
            payload.current_longitude,
            officer_data,
        )
        if nearby_ids:
            await NotificationService.create_emergency_alert(
                db,
                nearby_ids,
                session.id,
                ambulance.vehicle_number,
                payload.destination,
            )

        await db.refresh(session)
        # Build response and attach OSRM route steps/coordinates for client
        resp = EmergencyResponse.model_validate(session)
        try:
            resp.route_steps = route.steps
            resp.route_coordinates = route.coordinates
        except Exception:
            # best-effort: if steps can't be attached, still return the session
            pass
        return resp

    async def end_session(
        self, db: AsyncSession, session_id: int, ambulance_id: int
    ) -> Optional[EmergencyResponse]:
        result = await db.execute(
            select(EmergencySession).where(
                EmergencySession.id == session_id,
                EmergencySession.ambulance_id == ambulance_id,
                EmergencySession.status == EmergencyStatus.ACTIVE,
            )
        )
        session = result.scalar_one_or_none()
        if not session:
            return None

        session.status = EmergencyStatus.COMPLETED
        session.trip_stage = TripStage.COMPLETED.value
        session.ended_at = datetime.now(timezone.utc)

        amb_result = await db.execute(
            select(Ambulance).where(Ambulance.id == ambulance_id)
        )
        ambulance = amb_result.scalar_one()
        ambulance.status = self._ambulance_prior_status.pop(
            ambulance_id, AmbulanceStatus.AVAILABLE
        )
        gps_service.evict(ambulance_id)

        return EmergencyResponse.model_validate(session)

    async def update_trip_stage(
        self,
        db: AsyncSession,
        session_id: int,
        ambulance_id: int,
        stage: TripStage,
        current_lat: Optional[float] = None,
        current_lon: Optional[float] = None,
    ) -> Optional[EmergencySession]:
        result = await db.execute(
            select(EmergencySession).where(
                EmergencySession.id == session_id,
                EmergencySession.ambulance_id == ambulance_id,
                EmergencySession.status == EmergencyStatus.ACTIVE,
            )
        )
        session = result.scalar_one_or_none()
        if not session:
            return None
        session.trip_stage = stage.value

        if stage == TripStage.PATIENT_PICKED_UP and session.hospital_latitude and session.hospital_longitude:
            try:
                from app.ai.route_optimizer import RouteOptimizer
                from app.schemas.route import RoutePreference

                origin_lat = current_lat or session.pickup_latitude or session.dest_latitude
                origin_lon = current_lon or session.pickup_longitude or session.dest_longitude
                if origin_lat and origin_lon:
                    optimizer = RouteOptimizer()
                    route = await optimizer.optimize_route(
                        origin_lat,
                        origin_lon,
                        session.hospital_latitude,
                        session.hospital_longitude,
                        route_preference=RoutePreference.FASTEST,
                    )
                    session.dest_latitude = session.hospital_latitude
                    session.dest_longitude = session.hospital_longitude
                    session.destination = session.hospital_name or "Hospital"
                    session.route_polyline = route.polyline
                    session.route_steps = [
                        {"instruction": s.instruction, "distance_m": s.distance_m, "duration_s": s.duration_s}
                        for s in route.steps
                    ]
                    session.eta_minutes = route.eta_minutes
            except Exception:
                pass

        if stage == TripStage.ARRIVED_HOSPITAL:
            session.status = EmergencyStatus.COMPLETED
            session.trip_stage = TripStage.COMPLETED.value
            session.ended_at = datetime.now(timezone.utc)

            amb_result = await db.execute(
                select(Ambulance).where(Ambulance.id == ambulance_id)
            )
            ambulance = amb_result.scalar_one_or_none()
            if ambulance:
                ambulance.status = self._ambulance_prior_status.pop(
                    ambulance_id, AmbulanceStatus.AVAILABLE
                )
            gps_service.evict(ambulance_id)
        return session

    async def get_active_sessions(self, db: AsyncSession) -> List[EmergencySession]:
        result = await db.execute(
            select(EmergencySession)
            .where(EmergencySession.status == EmergencyStatus.ACTIVE)
            .options(selectinload(EmergencySession.ambulance))
            .order_by(EmergencySession.started_at.desc())
        )
        return list(result.scalars().all())

    async def get_session(
        self, db: AsyncSession, session_id: int
    ) -> Optional[EmergencySession]:
        result = await db.execute(
            select(EmergencySession)
            .where(EmergencySession.id == session_id)
            .options(
                selectinload(EmergencySession.ambulance),
                selectinload(EmergencySession.gps_logs),
            )
        )
        return result.scalar_one_or_none()

    async def get_driver_history(
        self, db: AsyncSession, ambulance_id: int, limit: int = 30
    ) -> List[EmergencySession]:
        result = await db.execute(
            select(EmergencySession)
            .where(EmergencySession.ambulance_id == ambulance_id)
            .order_by(EmergencySession.started_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_active_for_ambulance(
        self, db: AsyncSession, ambulance_id: int
    ) -> Optional[EmergencySession]:
        return await self._get_active_session(db, ambulance_id)

    async def _get_active_session(
        self, db: AsyncSession, ambulance_id: int
    ) -> Optional[EmergencySession]:
        result = await db.execute(
            select(EmergencySession).where(
                EmergencySession.ambulance_id == ambulance_id,
                EmergencySession.status == EmergencyStatus.ACTIVE,
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def _get_officers_with_zones(db: AsyncSession) -> List[TrafficOfficer]:
        result = await db.execute(select(TrafficOfficer))
        return list(result.scalars().all())
