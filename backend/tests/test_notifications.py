"""Tests for traffic officer notifications, acknowledgments, and driver replies."""

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


async def test_notification_creation_and_ack():
    suffix = str(int(time.time() * 1000))
    async with async_session_maker() as db:
        officer = User(
            name=f"Officer {suffix}",
            email=f"off-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.OFFICER,
        )
        db.add(officer)
        await db.flush()

        off_profile = TrafficOfficer(
            user_id=officer.id,
            assigned_zone="Baneshwor Chowk",
            zone_latitude=27.6995,
            zone_longitude=85.3420,
        )
        db.add(off_profile)

        driver = User(
            name=f"Driver {suffix}",
            email=f"drv-{suffix}@example.com",
            password_hash="pw",
            role=UserRole.DRIVER,
        )
        db.add(driver)
        await db.flush()

        amb = Ambulance(
            driver_id=driver.id,
            vehicle_number=f"NOTIF-{suffix}",
            status=AmbulanceStatus.AVAILABLE,
        )
        db.add(amb)
        await db.flush()

        session = EmergencySession(
            ambulance_id=amb.id,
            destination="Norvic Hospital",
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
        # Create an emergency alert for the officer
        async with async_session_maker() as db:
            alerts = await NotificationService.create_emergency_alert(
                db,
                officer_ids=[officer_id],
                emergency_session_id=session_id,
                vehicle_number=f"NOTIF-{suffix}",
                destination="Norvic Hospital",
            )
            await db.commit()
            alert_id = alerts[0].id

        # 1. Officer fetches notifications
        resp = await client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) >= 1
        assert any(n["id"] == alert_id for n in data)

        # 2. Officer acknowledges the alert (accept)
        ack_resp = await client.post(
            "/api/v1/notifications/acknowledge",
            headers={"Authorization": f"Bearer {officer_token}"},
            json={
                "notification_id": alert_id,
                "action": "accept",
            },
        )
        assert ack_resp.status_code == 200
        ack_data = ack_resp.json()
        assert ack_data["is_acknowledged"] is True
        assert ack_data["acknowledgment"] == "accept"

        # 3. Officer sends direct message to driver
        send_driver_resp = await client.post(
            "/api/v1/notifications/send-to-driver",
            headers={"Authorization": f"Bearer {officer_token}"},
            json={
                "emergency_session_id": session_id,
                "title": "Lane Cleared",
                "message": "Left lane cleared at Baneshwor.",
            },
        )
        assert send_driver_resp.status_code == 200
        assert send_driver_resp.json()["title"] == "Lane Cleared"

        # 4. Driver reads driver notifications
        driver_notif_resp = await client.get(
            "/api/v1/notifications/driver",
            headers={"Authorization": f"Bearer {driver_token}"},
        )
        assert driver_notif_resp.status_code == 200
        driver_notifs = driver_notif_resp.json()
        assert len(driver_notifs) >= 1
