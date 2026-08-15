"""Full lifecycle tests for emergency activation, GPS tracking, and trip stage transitions."""

import time
from datetime import datetime, timezone

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token
from app.database.session import async_session_maker
from app.main import app
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.user import User, UserRole

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def _setup_driver_and_ambulance(db, suffix: str):
    user = User(
        name=f"Driver {suffix}",
        email=f"driver-{suffix}@example.com",
        password_hash="hashed_pw",
        role=UserRole.DRIVER,
    )
    db.add(user)
    await db.flush()

    ambulance = Ambulance(
        driver_id=user.id,
        vehicle_number=f"BA-{suffix}",
        status=AmbulanceStatus.AVAILABLE,
    )
    db.add(ambulance)
    await db.commit()
    return user, ambulance


async def test_full_emergency_lifecycle():
    suffix = str(int(time.time() * 1000))
    async with async_session_maker() as db:
        driver, ambulance = await _setup_driver_and_ambulance(db, suffix)
        driver_id = driver.id
        amb_id = ambulance.id

    token = create_access_token(subject=driver_id, role=UserRole.DRIVER.value)
    headers = {"Authorization": f"Bearer {token}"}

    async with await _client() as client:
        # 1. Activate emergency
        activate_resp = await client.post(
            "/api/v1/emergencies/activate",
            headers=headers,
            json={
                "destination": "Tribhuvan University Teaching Hospital",
                "current_latitude": 27.7000,
                "current_longitude": 85.3100,
                "dest_latitude": 27.7350,
                "dest_longitude": 85.3300,
                "use_ai_prediction": False,
                "incident_type": "accident",
                "patient_name": "Hari Bahadur",
                "patient_contact": "9800000000",
                "hospital_name": "TU Teaching Hospital",
                "hospital_latitude": 27.7350,
                "hospital_longitude": 85.3300,
            },
        )
        assert activate_resp.status_code == 201, activate_resp.text
        session_data = activate_resp.json()
        session_id = session_data["id"]
        assert session_data["status"] == "active"
        assert session_data["trip_stage"] == "en_route"
        assert session_data["ambulance_id"] == amb_id

        # 2. Get current active emergency
        current_resp = await client.get("/api/v1/emergencies/current", headers=headers)
        assert current_resp.status_code == 200
        assert current_resp.json()["id"] == session_id

        # 3. Post GPS updates
        gps_resp = await client.post(
            "/api/v1/gps/update",
            headers=headers,
            json={
                "emergency_session_id": session_id,
                "latitude": 27.7050,
                "longitude": 85.3150,
                "speed_kmh": 45.0,
                "heading": 90.0,
            },
        )
        assert gps_resp.status_code == 200
        assert gps_resp.json()["emergency_session_id"] == session_id

        # 4. Advance trip stage to arrived_patient
        stage1_resp = await client.patch(
            f"/api/v1/emergencies/{session_id}/trip-stage",
            headers=headers,
            json={
                "trip_stage": "arrived_patient",
                "current_latitude": 27.7100,
                "current_longitude": 85.3200,
            },
        )
        assert stage1_resp.status_code == 200
        assert stage1_resp.json()["trip_stage"] == "arrived_patient"

        # 5. Advance trip stage to patient_picked_up
        stage2_resp = await client.patch(
            f"/api/v1/emergencies/{session_id}/trip-stage",
            headers=headers,
            json={
                "trip_stage": "patient_picked_up",
                "current_latitude": 27.7150,
                "current_longitude": 85.3220,
            },
        )
        assert stage2_resp.status_code == 200
        assert stage2_resp.json()["trip_stage"] == "patient_picked_up"

        # 6. Complete trip by advancing to arrived_hospital
        stage3_resp = await client.patch(
            f"/api/v1/emergencies/{session_id}/trip-stage",
            headers=headers,
            json={
                "trip_stage": "arrived_hospital",
                "current_latitude": 27.7350,
                "current_longitude": 85.3300,
            },
        )
        assert stage3_resp.status_code == 200
        completed_data = stage3_resp.json()
        assert completed_data["status"] == "completed"
        assert completed_data["ended_at"] is not None

        # 7. Verify driver history contains completed trip
        history_resp = await client.get("/api/v1/emergencies/history/driver", headers=headers)
        assert history_resp.status_code == 200
        history_items = history_resp.json()
        assert len(history_items) >= 1
        assert any(item["id"] == session_id for item in history_items)
