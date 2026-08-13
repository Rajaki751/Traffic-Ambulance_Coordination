"""
Real-time traffic condition estimation for route planning.

Uses time-of-day patterns, day-of-week, and OSRM congestion signals
to approximate live traffic impact without a paid traffic API.
"""

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class TrafficConditions:
    """Current traffic state used for routing and ML features."""

    factor: float  # 1.0 = normal; >1.0 = slower travel
    index: float  # 0.0–1.0 congestion index for ML
    label: str
    hour: int
    day_of_week: int


class TrafficService:
    """Estimate traffic impact from temporal patterns and route congestion."""

    @staticmethod
    def get_current_conditions(
        at: datetime | None = None,
        osrm_congestion_score: float | None = None,
    ) -> TrafficConditions:
        now = at or datetime.now(timezone.utc)
        hour = now.hour
        dow = now.weekday()

        temporal_factor, temporal_index, label = TrafficService._temporal_traffic(
            hour, dow
        )

        if osrm_congestion_score is not None:
            blended_index = min(0.95, temporal_index * 0.5 + osrm_congestion_score * 0.5)
            factor = 1.0 + blended_index * 0.8
            if osrm_congestion_score > 0.6:
                label = f"{label} + route congestion"
        else:
            blended_index = temporal_index
            factor = temporal_factor

        return TrafficConditions(
            factor=round(factor, 2),
            index=round(blended_index, 2),
            label=label,
            hour=hour,
            day_of_week=dow,
        )

    @staticmethod
    def _temporal_traffic(hour: int, day_of_week: int) -> tuple[float, float, str]:
        """Return (duration_factor, congestion_index, label)."""
        is_weekend = day_of_week >= 5

        if is_weekend:
            if 11 <= hour <= 15:
                return 1.25, 0.35, "weekend moderate traffic"
            if 18 <= hour <= 21:
                return 1.35, 0.45, "weekend evening traffic"
            return 1.05, 0.15, "weekend light traffic"

        # Weekday rush hours
        if 7 <= hour <= 9:
            return 1.55, 0.72, "morning rush hour"
        if 17 <= hour <= 19:
            return 1.6, 0.78, "evening rush hour"
        if 12 <= hour <= 14:
            return 1.2, 0.4, "midday traffic"
        if 22 <= hour or hour <= 5:
            return 0.95, 0.08, "night — low traffic"

        return 1.1, 0.25, "normal daytime traffic"
