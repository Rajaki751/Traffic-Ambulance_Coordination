"""
Deterministic incident location estimation using hotspot-anchored heuristics.

A statistical model trained on synthetic data has nothing real to learn, so
this module replaces the Random Forest with a transparent, repeatable
algorithm:

1. Start at the caller's position (incidents occur 0.1-2 km away).
2. Per incident type, a reach profile encodes how far the actual incident
   can plausibly be (cardiac close, fire imprecise).
3. A curated table of Kathmandu Valley risk hotspots (junctions, arterial
   roads, markets, hospital access points) attracts the estimate with an
   inverse-square distance weight, modulated by time of day and traffic.
4. Confidence is geometric: derived from hotspot proximity and agreement,
   not from a trained model.

Same interface as before, so routing and API layers are unchanged.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from app.core.logging import get_logger

logger = get_logger(__name__)

INCIDENT_TYPES = ["accident", "cardiac", "fire", "respiratory", "trauma", "general"]

# Which hotspot kinds each incident type is attracted to.
_TYPE_KINDS = {
    "accident": {"junction", "arterial"},
    "cardiac": {"hospital"},
    "fire": {"market", "junction"},
    "respiratory": {"hospital"},
    "trauma": {"junction", "arterial", "hospital"},
    "general": {"junction", "arterial", "market", "hospital"},
}

# Per-type reach (max plausible distance from caller, km), how far the
# estimate should sit inside that reach when hotspots agree, and a fallback
# offset when no hotspot is nearby.
TYPE_PROFILE = {
    "accident": {"reach_km": 1.2, "offset_fraction": 0.35, "default_offset_km": 0.6},
    "cardiac": {"reach_km": 0.5, "offset_fraction": 0.25, "default_offset_km": 0.25},
    "fire": {"reach_km": 2.0, "offset_fraction": 0.45, "default_offset_km": 1.0},
    "respiratory": {"reach_km": 0.4, "offset_fraction": 0.25, "default_offset_km": 0.2},
    "trauma": {"reach_km": 0.8, "offset_fraction": 0.35, "default_offset_km": 0.4},
    "general": {"reach_km": 1.0, "offset_fraction": 0.35, "default_offset_km": 0.5},
}

_KIND_WEIGHT = {"junction": 1.0, "arterial": 0.8, "market": 0.7, "hospital": 0.65}

_KATHMANDU_CENTER = (27.7172, 85.3240)

_KM_PER_DEG = 111.0

# name, latitude, longitude, kinds
HOTSPOTS: list[dict] = [
    {"name": "Kalanki chowk", "lat": 27.6940, "lon": 85.2920, "kinds": {"junction"}},
    {"name": "Balkhu chowk", "lat": 27.6860, "lon": 85.2970, "kinds": {"junction"}},
    {"name": "Vayodha, Balkhu", "lat": 27.6860, "lon": 85.2960, "kinds": {"hospital"}},
    {"name": "Kalimati", "lat": 27.6980, "lon": 85.2990, "kinds": {"market"}},
    {"name": "Tripureshwor", "lat": 27.6990, "lon": 85.3120, "kinds": {"junction"}},
    {"name": "Ratna Park", "lat": 27.7060, "lon": 85.3185, "kinds": {"junction", "market"}},
    {"name": "Bir Hospital", "lat": 27.7090, "lon": 85.3180, "kinds": {"hospital"}},
    {"name": "Jamal", "lat": 27.7090, "lon": 85.3190, "kinds": {"junction"}},
    {"name": "Asan", "lat": 27.7125, "lon": 85.3115, "kinds": {"market"}},
    {"name": "Indrachowk", "lat": 27.7095, "lon": 85.3125, "kinds": {"junction", "market"}},
    {"name": "New Road", "lat": 27.7065, "lon": 85.3140, "kinds": {"market"}},
    {"name": "Basantapur", "lat": 27.7035, "lon": 85.3070, "kinds": {"market"}},
    {"name": "Thamel", "lat": 27.7145, "lon": 85.3100, "kinds": {"market", "arterial"}},
    {"name": "TU Teaching Hospital", "lat": 27.7170, "lon": 85.3080, "kinds": {"hospital"}},
    {"name": "Maharajgunj", "lat": 27.7170, "lon": 85.3080, "kinds": {"junction"}},
    {"name": "Maitighar", "lat": 27.6995, "lon": 85.3220, "kinds": {"junction"}},
    {"name": "Thapathali, Norvic", "lat": 27.6955, "lon": 85.3250, "kinds": {"junction", "arterial", "hospital"}},
    {"name": "Baneshwor", "lat": 27.6995, "lon": 85.3420, "kinds": {"junction", "market"}},
    {"name": "New Baneshwor", "lat": 27.6960, "lon": 85.3350, "kinds": {"junction"}},
    {"name": "Civil Hospital", "lat": 27.6905, "lon": 85.3420, "kinds": {"hospital"}},
    {"name": "Koteshwor", "lat": 27.6860, "lon": 85.3440, "kinds": {"junction"}},
    {"name": "Tinkune", "lat": 27.6920, "lon": 85.3500, "kinds": {"junction"}},
    {"name": "Sinamangal", "lat": 27.7030, "lon": 85.3505, "kinds": {"junction"}},
    {"name": "Tribhuvan Airport", "lat": 27.6960, "lon": 85.3590, "kinds": {"arterial"}},
    {"name": "Gwarko", "lat": 27.6740, "lon": 85.3440, "kinds": {"junction"}},
    {"name": "Satdobato", "lat": 27.6590, "lon": 85.3310, "kinds": {"junction"}},
    {"name": "Ekantakuna", "lat": 27.6760, "lon": 85.3170, "kinds": {"junction"}},
    {"name": "Kupondole", "lat": 27.6820, "lon": 85.3160, "kinds": {"arterial"}},
    {"name": "Sanepa", "lat": 27.6845, "lon": 85.3095, "kinds": {"arterial"}},
    {"name": "Star Hospital", "lat": 27.6835, "lon": 85.3110, "kinds": {"hospital"}},
    {"name": "Dhobighat", "lat": 27.6800, "lon": 85.3290, "kinds": {"junction"}},
    {"name": "Balkumari", "lat": 27.6690, "lon": 85.3370, "kinds": {"junction"}},
    {"name": "Patan Hospital", "lat": 27.6745, "lon": 85.3220, "kinds": {"hospital"}},
    {"name": "Pulchowk", "lat": 27.6780, "lon": 85.3180, "kinds": {"junction"}},
    {"name": "Jawalakhel", "lat": 27.6710, "lon": 85.3100, "kinds": {"junction", "market"}},
    {"name": "Lagankhel, Alka Hospital", "lat": 27.6610, "lon": 85.3140, "kinds": {"junction", "hospital"}},
    {"name": "Chabahil", "lat": 27.7205, "lon": 85.3430, "kinds": {"junction", "market"}},
    {"name": "Gaushala", "lat": 27.7180, "lon": 85.3390, "kinds": {"junction", "arterial"}},
    {"name": "Kanti Children's Hospital", "lat": 27.7150, "lon": 85.3370, "kinds": {"hospital"}},
    {"name": "Boudha", "lat": 27.7210, "lon": 85.3610, "kinds": {"market"}},
    {"name": "Dhumbarahi, HAMS", "lat": 27.7280, "lon": 85.3370, "kinds": {"arterial", "hospital"}},
    {"name": "Bansbari, Mediciti", "lat": 27.7205, "lon": 85.3360, "kinds": {"arterial", "hospital"}},
    {"name": "Dhapasi", "lat": 27.7320, "lon": 85.3310, "kinds": {"arterial"}},
    {"name": "Jorpati, NMC", "lat": 27.7300, "lon": 85.3530, "kinds": {"arterial", "hospital"}},
    {"name": "Balaju", "lat": 27.7300, "lon": 85.3050, "kinds": {"junction", "arterial"}},
    {"name": "Gongabu bus park", "lat": 27.7260, "lon": 85.3110, "kinds": {"junction", "market"}},
    {"name": "Swayambhu", "lat": 27.7150, "lon": 85.2895, "kinds": {"arterial"}},
    {"name": "Kirtipur", "lat": 27.6690, "lon": 85.2800, "kinds": {"junction", "market"}},
]


@dataclass
class IncidentPrediction:
    incident_latitude: float
    incident_longitude: float
    confidence: float
    model_version: str


def _distance_km(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Equirectangular approximation, fine at sub-2 km scale."""
    lat1, lon1, lat2, lon2 = map(math.radians, (lat1, lon1, lat2, lon2))
    x = (lon2 - lon1) * math.cos((lat1 + lat2) / 2.0)
    y = lat2 - lat1
    return math.sqrt(x * x + y * y) * 6371.0


def _vector_km(dlat: float, dlon: float, lat_ref: float) -> float:
    """Magnitude in km of a (deg-lat, deg-lon) vector at lat_ref."""
    dlat_km = dlat * _KM_PER_DEG
    dlon_km = dlon * _KM_PER_DEG * math.cos(math.radians(lat_ref))
    return math.hypot(dlat_km, dlon_km)


class IncidentLocationPredictor:
    """Deterministic hotspot-anchored incident location estimator."""

    MODEL_VERSION = "hybrid-v1"

    def ensure_model(self) -> None:
        """No model file needed; kept for startup compatibility."""
        return None

    def predict(
        self,
        caller_latitude: float,
        caller_longitude: float,
        hour: int,
        day_of_week: int,
        traffic_index: float,
        incident_type: str = "general",
    ) -> IncidentPrediction:
        if incident_type not in INCIDENT_TYPES:
            incident_type = "general"

        profile = TYPE_PROFILE[incident_type]
        kinds = _TYPE_KINDS[incident_type]
        reach = profile["reach_km"]

        is_weekend = day_of_week >= 5
        rush_hour = (
            not is_weekend and (7 <= hour <= 9 or 17 <= hour <= 19)
        )
        night = hour >= 22 or hour <= 5

        candidates: list[tuple[dict, float, float]] = []
        for hotspot in HOTSPOTS:
            matching = kinds & hotspot["kinds"]
            if not matching:
                continue
            distance = _distance_km(
                caller_latitude, caller_longitude, hotspot["lat"], hotspot["lon"]
            )
            if distance > reach:
                continue
            weight = _KIND_WEIGHT[next(iter(matching))]
            if (
                rush_hour
                and incident_type in ("accident", "trauma", "general")
                and (hotspot["kinds"] & {"junction", "arterial"})
            ):
                weight *= 1.4
            if (
                night
                and incident_type in ("accident", "fire", "trauma")
                and (hotspot["kinds"] & {"junction", "arterial"})
            ):
                weight *= 1.15
            candidates.append((hotspot, distance, weight))

        if candidates:
            total = 0.0
            pull_lat = 0.0
            pull_lon = 0.0
            for hotspot, distance, weight in candidates:
                inv = weight / (1.0 + distance * distance)
                total += inv
                pull_lat += inv * (hotspot["lat"] - caller_latitude)
                pull_lon += inv * (hotspot["lon"] - caller_longitude)
            pull_lat /= total
            pull_lon /= total

            pull_km = _vector_km(pull_lat, pull_lon, caller_latitude)
            if pull_km < 1e-9:
                city_lat, city_lon = _KATHMANDU_CENTER
                pull_lat = city_lat - caller_latitude
                pull_lon = city_lon - caller_longitude
                pull_km = _vector_km(pull_lat, pull_lon, caller_latitude)

            want_km = profile["offset_fraction"] * reach
            scale = want_km / pull_km
            est_lat = caller_latitude + pull_lat * scale
            est_lon = caller_longitude + pull_lon * scale

            best_distance = min(d for _, d, _ in candidates)
            confidence = 0.85 - 0.20 * (best_distance / reach)
            if len(candidates) >= 3:
                confidence += 0.05
        else:
            # Fallback: step toward the nearest attracting hotspot (or the
            # city centre) by the type's default offset distance.
            target_lat, target_lon = _KATHMANDU_CENTER
            nearest: float | None = None
            for hotspot in HOTSPOTS:
                if not (kinds & hotspot["kinds"]):
                    continue
                distance = _distance_km(
                    caller_latitude,
                    caller_longitude,
                    hotspot["lat"],
                    hotspot["lon"],
                )
                if nearest is None or distance < nearest:
                    nearest = distance
                    target_lat, target_lon = hotspot["lat"], hotspot["lon"]
            default_km = profile["default_offset_km"]
            dvec_km = _vector_km(
                target_lat - caller_latitude, target_lon - caller_longitude, caller_latitude
            )
            scale = default_km / dvec_km if dvec_km > 1e-9 else 0.0
            est_lat = caller_latitude + (target_lat - caller_latitude) * scale
            est_lon = caller_longitude + (target_lon - caller_longitude) * scale
            confidence = 0.50

        if rush_hour and incident_type in ("accident", "trauma"):
            confidence += 0.06
        if traffic_index >= 0.6 and incident_type in ("accident", "trauma"):
            confidence += 0.05
        if night and incident_type in ("fire", "trauma"):
            confidence -= 0.04

        confidence = max(0.35, min(0.98, round(confidence, 2)))

        logger.info(
            "Estimated %s incident at (%.6f, %.6f) conf=%.2f from caller "
            "(%.6f, %.6f) t=%s rush=%s",
            incident_type,
            est_lat,
            est_lon,
            confidence,
            caller_latitude,
            caller_longitude,
            traffic_index,
            rush_hour,
        )

        return IncidentPrediction(
            incident_latitude=round(est_lat, 6),
            incident_longitude=round(est_lon, 6),
            confidence=confidence,
            model_version=self.MODEL_VERSION,
        )