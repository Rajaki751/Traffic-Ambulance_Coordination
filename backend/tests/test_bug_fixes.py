"""Regression tests for bug fixes across user management, analytics, and trip lifecycle."""

import time
from datetime import datetime, timedelta, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.ai.eta_predictor import as_utc
from app.core.security import create_access_token
from app.database.session import async_session_maker
from app.main import app
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.emergency import EmergencySession, EmergencyStatus, TripStage
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole
from app.services.analytics_service import AnalyticsService
from app.services.emergency_service import EmergencyService

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_as_utc_conversion():
    # Test naive datetime
    naive = datetime(2026, 8, 15, 12, 0, 0)
    utc = as_utc(naive)
    assert utc is not None
    assert utc.tzinfo == timezone.utc
    assert utc.hour == 12

    # Test aware datetime with offset (+05:45 Nepal time)
    npt = timezone(timedelta(hours=5, minutes=45))
    aware = datetime(2026, 8, 15, 12, 0, 0, tzinfo=npt)
    converted = as_utc(aware)
    assert converted is not None
    assert converted.tzinfo == timezone.utc
    assert converted.hour == 6
    assert converted.minute == 15


async def test_admin_create_driver_creates_ambulance():
    suffix = str(int(time.time() * 1000))
    admin_token = create_access_token(subject=1, role=UserRole.ADMIN.value)
    headers = {"Authorization": f"Bearer {admin_token}"}

    async with await _client() as client:
        # Create driver
        resp = await client.post(
            "/api/v1/users/",
            headers=headers,
            json={
                "name": "Driver Test",
                "email": f"driver-{suffix}@example.com",
                "password": "Password@123",
                "role": "driver",
                "vehicle_number": f"AMB-{suffix}",
            },
        )
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert data["role"] == "driver"
        assert data["vehicle_number"] == f"AMB-{suffix}"

        # Verify ambulance exists in DB
        async with async_session_maker() as db:
            amb = await db.scalar(
                select(Ambulance).where(Ambulance.driver_id == data["id"])
            )
            assert amb is not None
            assert amb.vehicle_number == f"AMB-{suffix}"
            assert amb.status == AmbulanceStatus.AVAILABLE


async def test_admin_create_officer_creates_profile():
    suffix = str(int(time.time() * 1000))
    admin_token = create_access_token(subject=1, role=UserRole.ADMIN.value)
    headers = {"Authorization": f"Bearer {admin_token}"}

    async with await _client() as client:
        # Create officer
        resp = await client.post(
            "/api/v1/users/",
            headers=headers,
            json={
                "name": "Officer Test",
                "email": f"officer-{suffix}@example.com",
                "password": "Password@123",
                "role": "officer",
                "assigned_zone": f"Zone-{suffix}",
            },
        )
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert data["role"] == "officer"
        assert data["assigned_zone"] == f"Zone-{suffix}"

        # Verify profile exists in DB
        async with async_session_maker() as db:
            off = await db.scalar(
                select(TrafficOfficer).where(TrafficOfficer.user_id == data["id"])
            )
            assert off is not None
            assert off.assigned_zone == f"Zone-{suffix}"


async def test_admin_update_user_details():
    suffix = str(int(time.time() * 1000))
    admin_token = create_access_token(subject=1, role=UserRole.ADMIN.value)
    headers = {"Authorization": f"Bearer {admin_token}"}

    async with await _client() as client:
        # Create driver
        resp = await client.post(
            "/api/v1/users/",
            headers=headers,
            json={
                "name": "Update Test Driver",
                "email": f"update-{suffix}@example.com",
                "password": "Password@123",
                "role": "driver",
                "vehicle_number": f"OLD-{suffix}",
            },
        )
        assert resp.status_code == 201
        user_id = resp.json()["id"]

        # Update vehicle number while remaining driver
        update_resp = await client.put(
            f"/api/v1/users/{user_id}",
            headers=headers,
            json={
                "name": "Renamed Driver",
                "vehicle_number": f"NEW-{suffix}",
            },
        )
        assert update_resp.status_code == 200, update_resp.text
        updated_data = update_resp.json()
        assert updated_data["name"] == "Renamed Driver"
        assert updated_data["vehicle_number"] == f"NEW-{suffix}"


async def test_emergency_trip_stage_arrived_hospital_computes_actual_duration():
    async with async_session_maker() as db:
        # Create temporary driver + ambulance
        user = User(
            name="Trip Stage Driver",
            email=f"trip-stage-{int(time.time()*1000)}@example.com",
            password_hash="fake",
            role=UserRole.DRIVER,
        )
        db.add(user)
        await db.flush()

        amb = Ambulance(
            driver_id=user.id,
            vehicle_number=f"TS-{int(time.time()*1000)}",
            status=AmbulanceStatus.EMERGENCY,
        )
        db.add(amb)
        await db.flush()

        started_time = datetime.now(timezone.utc) - timedelta(minutes=15)
        session = EmergencySession(
            ambulance_id=amb.id,
            destination="Test Hospital",
            status=EmergencyStatus.ACTIVE,
            trip_stage=TripStage.EN_ROUTE.value,
            started_at=started_time,
            baseline_duration_min=12.0,
            distance_km=4.5,
        )
        db.add(session)
        await db.commit()
        session_id = session.id
        amb_id = amb.id

    service = EmergencyService()
    async with async_session_maker() as db:
        updated = await service.update_trip_stage(
            db,
            session_id=session_id,
            ambulance_id=amb_id,
            stage=TripStage.ARRIVED_HOSPITAL,
        )
        await db.commit()
        assert updated is not None
        assert updated.status == EmergencyStatus.COMPLETED
        assert updated.trip_stage == TripStage.COMPLETED.value
        assert updated.actual_duration_min is not None
        assert 14.5 <= updated.actual_duration_min <= 15.5


async def test_analytics_summary_tz_safe():
    async with async_session_maker() as db:
        summary = await AnalyticsService.get_summary(db)
        assert summary is not None
        assert isinstance(summary.total_users, int)
        assert isinstance(summary.avg_response_time_minutes, float)
