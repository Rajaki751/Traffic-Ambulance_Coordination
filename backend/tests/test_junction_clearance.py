"""Tests for junction preemption, officer actions, and notification triggers."""

import time
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token
from app.database.session import async_session_maker
from app.main import app
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.emergency import EmergencySession, EmergencyStatus
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_junction_clearance_lifecycle():
    suffix = str(int(time.time() * 1000))
    async with async_session_maker() as db:
        officer = User(
            name=f"Officer {suffix}",
            email=f"junc-off-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.OFFICER,
        )
        db.add(officer)
        await db.flush()

        off_profile = TrafficOfficer(
            user_id=officer.id,
            assigned_zone="Kalanki Chowk",
        )
        db.add(off_profile)

        driver = User(
            name=f"Driver {suffix}",
            email=f"junc-drv-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.DRIVER,
        )
        db.add(driver)
        await db.flush()

        amb = Ambulance(
            driver_id=driver.id,
            vehicle_number=f"JUNC-{suffix}",
            status=AmbulanceStatus.AVAILABLE,
        )
        db.add(amb)
        await db.flush()

        session = EmergencySession(
            ambulance_id=amb.id,
            destination="National Hospital",
            status=EmergencyStatus.ACTIVE,
        )
        db.add(session)
        await db.commit()

        officer_id = officer.id
        driver_id = driver.id
        session_id = session.id

    officer_token = create_access_token(subject=officer_id, role=UserRole.OFFICER.value)
    driver_token = create_access_token(subject=driver_id, role=UserRole.DRIVER.value)

    async with await _client() as client:
        # 1. Officer gets preset Kathmandu junctions
        junc_resp = await client.get(
            "/api/v1/junctions/kathmandu",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert junc_resp.status_code == 200
        preset = junc_resp.json()
        assert len(preset) >= 5
        assert any("Kalanki" in j.get("name", "") for j in preset)

        # 2. Officer marks junction cleared for this emergency session
        clear_resp = await client.post(
            "/api/v1/junctions/clear",
            headers={"Authorization": f"Bearer {officer_token}"},
            json={
                "emergency_session_id": session_id,
                "junction_name": "Kalanki Chowk",
                "latitude": 27.6934,
                "longitude": 85.2816,
                "notes": "East-bound lane opened",
            },
        )
        assert clear_resp.status_code == 200
        data = clear_resp.json()
        assert data["junction_name"] == "Kalanki Chowk"
        assert data["officer_id"] == officer_id

        # 3. Officer views clearance history
        hist_resp = await client.get(
            "/api/v1/junctions/history",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert hist_resp.status_code == 200
        hist = hist_resp.json()
        assert len(hist) >= 1
        assert hist[0]["junction_name"] == "Kalanki Chowk"

        # 4. Verify driver received automated notification
        driver_notif_resp = await client.get(
            "/api/v1/notifications/driver",
            headers={"Authorization": f"Bearer {driver_token}"},
        )
        assert driver_notif_resp.status_code == 200
        notifs = driver_notif_resp.json()
        assert any("Kalanki Chowk has been cleared" in n["message"] for n in notifs)
