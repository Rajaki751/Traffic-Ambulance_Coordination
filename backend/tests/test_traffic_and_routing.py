"""Tests for traffic conditions, route preferences, and optimization logic."""

from datetime import datetime, timezone

import pytest

from app.ai.route_optimizer import RouteOptimizer
from app.ai.traffic_service import TrafficService
from app.schemas.route import RoutePreference


def test_traffic_temporal_patterns():
    # Morning rush hour on a weekday (Tuesday at 08:30 UTC)
    tue_morning = datetime(2026, 8, 18, 8, 30, tzinfo=timezone.utc)
    cond = TrafficService.get_current_conditions(tue_morning)
    assert cond.factor >= 1.5
    assert cond.index >= 0.6
    assert "morning rush hour" in cond.label

    # Evening rush hour on a weekday (Thursday at 18:00 UTC)
    thu_evening = datetime(2026, 8, 20, 18, 0, tzinfo=timezone.utc)
    cond_eve = TrafficService.get_current_conditions(thu_evening)
    assert cond_eve.factor >= 1.5
    assert "evening rush hour" in cond_eve.label

    # Night low traffic (Wednesday at 02:00 UTC)
    wed_night = datetime(2026, 8, 19, 2, 0, tzinfo=timezone.utc)
    cond_night = TrafficService.get_current_conditions(wed_night)
    assert cond_night.factor <= 1.0
    assert "night" in cond_night.label


def test_nearby_officer_detection():
    ambulance_lat = 27.7000
    ambulance_lon = 85.3200

    # Officer 1 is ~0.5km away (radius 2km) -> should match
    # Officer 2 is ~15km away (radius 2km) -> should not match
    # Officer 3 has no zone -> skipped in spatial filter
    officers = [
        (101, 27.7030, 85.3220, 2.0),
        (102, 27.5500, 85.1000, 2.0),
        (103, None, None, 2.0),
    ]

    nearby = RouteOptimizer.find_nearby_officers(ambulance_lat, ambulance_lon, officers)
    assert 101 in nearby
    assert 102 not in nearby
    assert 103 not in nearby


def test_congestion_score_calculation():
    optimizer = RouteOptimizer()
    # High speed: 10km in 12 min (50 km/h) -> low congestion
    score_free = optimizer._calculate_congestion_score(
        distance_m=10000, duration_s=720, point_count=50
    )
    assert score_free < 0.3

    # Low speed: 2km in 20 min (6 km/h) -> high congestion
    score_congested = optimizer._calculate_congestion_score(
        distance_m=2000, duration_s=1200, point_count=200
    )
    assert score_congested > 0.7
