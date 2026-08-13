"""Tests for learned ETA model and hotspot discovery."""

from datetime import datetime, timedelta, timezone

import pytest

from app.ai.eta_predictor import ETAPredictor, MIN_TRAINING_SAMPLES
from app.ai.hotspot_discovery import discover_hotspots, MIN_RECORDS


def _fake_trips(count: int) -> list[dict]:
    base = datetime(2026, 8, 1, 9, 0, tzinfo=timezone.utc)
    types = ["accident", "cardiac", "fire", "trauma", "general"]
    trips = []
    for i in range(count):
        baseline = 5.0 + (i % 10) * 2.0
        trips.append(
            {
                "distance_km": baseline * 0.4,
                "baseline_duration_min": baseline,
                "actual_duration_min": round(baseline * (1.05 + 0.15 * (i % 4)), 1),
                "traffic_factor": 1.0 + (i % 3) * 0.3,
                "incident_type": types[i % len(types)],
                "started_at": base + timedelta(hours=i),
            }
        )
    return trips


def test_eta_train_and_predict(tmp_path, monkeypatch):
    monkeypatch.setattr("app.ai.eta_predictor.ETA_MODEL_PATH", tmp_path / "eta.joblib")
    trips = _fake_trips(40)
    eta = ETAPredictor()
    metrics = eta.train(trips)

    assert metrics["samples"] >= MIN_TRAINING_SAMPLES
    assert metrics["model_version"] == "eta-v1"
    assert eta.is_ready

    first = eta.predict_ratio(
        distance_km=4.0,
        baseline_duration_min=10.0,
        hour=9,
        day_of_week=0,
        traffic_factor=1.3,
        incident_type="accident",
    )
    assert first is not None
    assert 0.7 <= first <= 2.2
    second = eta.predict_ratio(
        distance_km=4.0,
        baseline_duration_min=10.0,
        hour=9,
        day_of_week=0,
        traffic_factor=1.3,
        incident_type="accident",
    )
    assert first == second


def test_eta_train_insufficient_samples():
    with pytest.raises(ValueError):
        ETAPredictor().train(_fake_trips(5))


def test_hotspot_discovery_clusters():
    records = []
    for i in range(12):
        records.append(
            (27.6860 + 0.0005 * (i % 4), 85.3440 + 0.0005 * (i % 4), "accident")
        )
    for i in range(8):
        records.append(
            (27.6995 + 0.0005 * (i % 4), 85.3220 + 0.0005 * (i % 4), "cardiac")
        )
    for i in range(8):
        records.append(
            (27.7060 + 0.0005 * (i % 4), 85.3185 + 0.0005 * (i % 4), "fire")
        )

    found = discover_hotspots(records)
    assert len(found) >= 2
    for hotspot in found:
        assert hotspot["size"] >= 3
        assert hotspot["kinds"]
        assert hotspot["dominant_type"]


def test_hotspot_discovery_insufficient_records():
    records = [(27.7, 85.32, "accident")] * 5
    assert len(records) < MIN_RECORDS
    assert discover_hotspots(records) == []