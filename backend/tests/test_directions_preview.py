import pytest
from httpx import AsyncClient
from httpx import ASGITransport

from app.main import app
from app.schemas.route import RouteOptimizeResponse, RouteStep


@pytest.mark.asyncio
async def test_preview_route_monkeypatched(monkeypatch):
    # Prepare a fake response
    fake = RouteOptimizeResponse(
        distance_km=1.2,
        duration_minutes=5.0,
        eta_minutes=4.2,
        congestion_score=0.1,
        traffic_factor=1.0,
        polyline='[[27.7,85.3],[27.705,85.32]]',
        coordinates=[[27.7, 85.3], [27.705, 85.32]],
        steps=[RouteStep(instruction='Turn right', distance_m=100, duration_s=20)],
        reroute_recommended=False,
    )

    async def fake_optimize(*args, **kwargs):
        return fake

    # Patch the route_optimizer instance used by the directions router
    import app.api.v1.directions as directions_mod

    monkeypatch.setattr(directions_mod, "route_optimizer", directions_mod.route_optimizer)
    monkeypatch.setattr(directions_mod.route_optimizer, "optimize_route", fake_optimize)

    # `httpx.AsyncClient` historically accepted `app=...`, but some
    # versions require an `ASGITransport`. Use whichever works.
    try:
        client_kwargs = {"app": app, "base_url": "http://test"}
        ac = AsyncClient(**client_kwargs)
    except TypeError:
        ac = AsyncClient(transport=ASGITransport(app=app), base_url="http://test")
    async with ac as ac:
        resp = await ac.get(
            "/api/v1/directions/preview?origin_lat=27.7&origin_lon=85.3&dest_lat=27.705&dest_lon=85.32"
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["distance_km"] == 1.2
        assert "steps" in data and len(data["steps"]) == 1
        assert data["steps"][0]["instruction"] == "Turn right"
