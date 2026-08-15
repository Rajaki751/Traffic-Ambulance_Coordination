"""Tests for user profile management, password change, and fleet activity metrics."""

import time
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token, hash_password
from app.database.session import async_session_maker
from app.main import app
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.user import User, UserRole

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_get_and_update_profile():
    suffix = str(int(time.time() * 1000))
    async with async_session_maker() as db:
        pw_hash = await hash_password("OldPassword@123")
        user = User(
            name=f"Profile User {suffix}",
            email=f"profile-{suffix}@example.com",
            password_hash=pw_hash,
            role=UserRole.DRIVER,
        )
        db.add(user)
        await db.flush()

        amb = Ambulance(
            driver_id=user.id,
            vehicle_number=f"PROF-{suffix}",
            status=AmbulanceStatus.AVAILABLE,
        )
        db.add(amb)
        await db.commit()
        user_id = user.id

    token = create_access_token(subject=user_id, role=UserRole.DRIVER.value)
    headers = {"Authorization": f"Bearer {token}"}

    async with await _client() as client:
        # 1. Get profile
        resp = await client.get("/api/v1/profile/me", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["name"] == f"Profile User {suffix}"
        assert data["vehicle_number"] == f"PROF-{suffix}"

        # 2. Update profile name
        patch_resp = await client.patch(
            "/api/v1/profile/me",
            headers=headers,
            json={"name": f"Updated Name {suffix}"},
        )
        assert patch_resp.status_code == 200
        assert patch_resp.json()["name"] == f"Updated Name {suffix}"

        # 3. Change password with wrong current password (should fail)
        bad_pw_resp = await client.post(
            "/api/v1/profile/change-password",
            headers=headers,
            json={
                "current_password": "WrongPassword@123",
                "new_password": "NewPassword@12345",
            },
        )
        assert bad_pw_resp.status_code == 400
        assert "incorrect" in bad_pw_resp.json()["detail"].lower()

        # 4. Change password with correct current password
        good_pw_resp = await client.post(
            "/api/v1/profile/change-password",
            headers=headers,
            json={
                "current_password": "OldPassword@123",
                "new_password": "NewPassword@12345",
            },
        )
        assert good_pw_resp.status_code == 200
        assert "successfully" in good_pw_resp.json()["message"]


async def test_fleet_analytics_ambulances():
    token = create_access_token(subject=1, role=UserRole.ADMIN.value)
    async with await _client() as client:
        resp = await client.get(
            "/api/v1/analytics/ambulances",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        fleet = resp.json()
        assert isinstance(fleet, list)
        for amb in fleet:
            assert "ambulance_id" in amb
            assert "vehicle_number" in amb
            assert "total_emergencies" in amb
