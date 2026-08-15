"""Tests for group chat service and participant access controls."""

import time
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token
from app.database.session import async_session_maker
from app.main import app
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.emergency import EmergencySession, EmergencyStatus
from app.models.notification import Notification
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole
from app.services.notification_service import NotificationService

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_chat_messages_flow():
    suffix = str(int(time.time() * 1000))
    async with async_session_maker() as db:
        officer = User(
            name=f"Officer {suffix}",
            email=f"chat-off-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.OFFICER,
        )
        db.add(officer)
        await db.flush()

        off_profile = TrafficOfficer(
            user_id=officer.id,
            assigned_zone="Maitighar",
        )
        db.add(off_profile)

        driver = User(
            name=f"Driver {suffix}",
            email=f"chat-drv-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.DRIVER,
        )
        db.add(driver)
        await db.flush()

        amb = Ambulance(
            driver_id=driver.id,
            vehicle_number=f"CHAT-{suffix}",
            status=AmbulanceStatus.AVAILABLE,
        )
        db.add(amb)
        await db.flush()

        session = EmergencySession(
            ambulance_id=amb.id,
            destination="Bir Hospital",
            status=EmergencyStatus.ACTIVE,
        )
        db.add(session)
        await db.commit()

        officer_id = officer.id
        driver_id = driver.id
        session_id = session.id

    # Alert the officer to associate them with the emergency session
    async with async_session_maker() as db:
        await NotificationService.create_emergency_alert(
            db,
            officer_ids=[officer_id],
            emergency_session_id=session_id,
            vehicle_number=f"CHAT-{suffix}",
            destination="Bir Hospital",
        )
        await db.commit()

    officer_token = create_access_token(subject=officer_id, role=UserRole.OFFICER.value)
    driver_token = create_access_token(subject=driver_id, role=UserRole.DRIVER.value)

    async with await _client() as client:
        # 1. Driver sends message
        msg1_resp = await client.post(
            f"/api/v1/chat/sessions/{session_id}/messages",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"message": "Approaching Maitighar intersection in 2 mins"},
        )
        assert msg1_resp.status_code == 200, msg1_resp.text
        msg1_data = msg1_resp.json()
        assert msg1_data["message"] == "Approaching Maitighar intersection in 2 mins"
        assert msg1_data["sender_role"] == "driver"

        # 2. Officer sends reply with coordinate
        msg2_resp = await client.post(
            f"/api/v1/chat/sessions/{session_id}/messages",
            headers={"Authorization": f"Bearer {officer_token}"},
            json={
                "message": "Copy, traffic stopped from Singhadurbar side",
                "latitude": 27.6995,
                "longitude": 85.3220,
            },
        )
        assert msg2_resp.status_code == 200
        msg2_data = msg2_resp.json()
        assert msg2_data["sender_role"] == "officer"
        assert msg2_data["latitude"] == 27.6995

        # 3. Officer lists messages
        list_resp = await client.get(
            f"/api/v1/chat/sessions/{session_id}/messages",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert list_resp.status_code == 200
        msgs = list_resp.json()
        assert len(msgs) >= 2

        # 4. Mark chat read
        read_resp = await client.post(
            f"/api/v1/chat/sessions/{session_id}/read",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert read_resp.status_code == 200
        assert read_resp.json()["status"] == "ok"
