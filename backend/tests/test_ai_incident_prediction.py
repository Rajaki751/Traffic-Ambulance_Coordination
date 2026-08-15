"""Tests for AI model info, incident location heuristics, and route to incident predictions."""

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import create_access_token
from app.main import app
from app.models.user import UserRole

pytestmark = pytest.mark.asyncio


async def _client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_ai_model_info_endpoint():
    token = create_access_token(subject=1, role=UserRole.ADMIN.value)
    async with await _client() as client:
        resp = await client.get(
            "/api/v1/ai/model-info",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["model_loaded"] is True
        assert "accident" in data["supported_incident_types"]
        assert "cardiac" in data["supported_incident_types"]
        assert "fire" in data["supported_incident_types"]


async def test_ai_predict_incident_location():
    token = create_access_token(subject=1, role=UserRole.DRIVER.value)
    async with await _client() as client:
        # Predict accident near Koteshwor (27.6750, 85.3450)
        resp = await client.post(
            "/api/v1/ai/predict-incident",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "caller_latitude": 27.6750,
                "caller_longitude": 85.3450,
                "incident_type": "accident",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "incident_latitude" in data
        assert "incident_longitude" in data
        assert 0.0 <= data["confidence"] <= 1.0
        assert "traffic_factor" in data
        assert "traffic_label" in data


async def test_ai_predict_general_fallback():
    token = create_access_token(subject=1, role=UserRole.DRIVER.value)
    async with await _client() as client:
        resp = await client.post(
            "/api/v1/ai/predict-incident",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "caller_latitude": 27.6750,
                "caller_longitude": 85.3450,
                "incident_type": "unknown_falls_back_to_general",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "incident_latitude" in data
        assert data["confidence"] > 0
