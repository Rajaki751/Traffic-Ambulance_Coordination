"""
Generate synthetic historical incident data for ML training.

Usage:
    cd backend
    python -m scripts.generate_incident_data
"""

from __future__ import annotations

import csv
import random
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
OUTPUT = DATA_DIR / "incidents_history.csv"

# Kathmandu valley approximate bounds
CENTER_LAT, CENTER_LON = 27.7172, 85.3240
INCIDENT_TYPES = ["accident", "cardiac", "fire", "respiratory", "trauma", "general"]

# Typical offset from call origin to incident (km) by type
TYPE_OFFSET_KM = {
    "accident": (0.3, 1.2),
    "cardiac": (0.1, 0.5),
    "fire": (0.5, 2.0),
    "respiratory": (0.1, 0.4),
    "trauma": (0.2, 0.8),
    "general": (0.2, 1.0),
}


def _offset_coords(lat: float, lon: float, km: float, bearing_deg: float) -> tuple[float, float]:
    import math

    r = 6371.0
    br = math.radians(bearing_deg)
    lat1, lon1 = math.radians(lat), math.radians(lon)
    lat2 = math.asin(
        math.sin(lat1) * math.cos(km / r)
        + math.cos(lat1) * math.sin(km / r) * math.cos(br)
    )
    lon2 = lon1 + math.atan2(
        math.sin(br) * math.sin(km / r) * math.cos(lat1),
        math.cos(km / r) - math.sin(lat1) * math.sin(lat2),
    )
    return math.degrees(lat2), math.degrees(lon2)


def generate(rows: int = 2500) -> None:
    random.seed(42)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "caller_latitude",
                "caller_longitude",
                "hour",
                "day_of_week",
                "traffic_index",
                "incident_type",
                "incident_latitude",
                "incident_longitude",
            ]
        )

        for _ in range(rows):
            caller_lat = CENTER_LAT + random.uniform(-0.08, 0.08)
            caller_lon = CENTER_LON + random.uniform(-0.08, 0.08)
            hour = random.randint(0, 23)
            dow = random.randint(0, 6)
            incident_type = random.choice(INCIDENT_TYPES)

            from app.ai.traffic_service import TrafficService

            traffic_index = TrafficService._temporal_traffic(hour, dow)[1]

            lo, hi = TYPE_OFFSET_KM[incident_type]
            offset_km = random.uniform(lo, hi)
            bearing = random.uniform(0, 360)
            inc_lat, inc_lon = _offset_coords(caller_lat, caller_lon, offset_km, bearing)

            writer.writerow(
                [
                    round(caller_lat, 6),
                    round(caller_lon, 6),
                    hour,
                    dow,
                    round(traffic_index, 3),
                    incident_type,
                    round(inc_lat, 6),
                    round(inc_lon, 6),
                ]
            )

    print(f"Generated {rows} records -> {OUTPUT}")


if __name__ == "__main__":
    generate()
