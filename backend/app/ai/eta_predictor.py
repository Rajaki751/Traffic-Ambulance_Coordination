"""
Learned ETA model: predicts how much a trip will diverge from OSRM's
baseline, trained on completed emergency sessions.

Every completed trip is a label: the ratio `actual_duration_min /
baseline_duration_min`. A gradient boosting regressor learns that ratio
from distance, time of day, weekday, traffic factor, and incident type.
When no model is trained yet (or scikit-learn is unavailable), callers
fall back to the heuristic ETA — prediction is strictly additive.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from app.ai.incident_predictor import INCIDENT_TYPES

logger = logging.getLogger(__name__)

_MODELS_DIR = Path(__file__).resolve().parents[2] / "models"
ETA_MODEL_PATH = _MODELS_DIR / "eta_model.joblib"

MIN_TRAINING_SAMPLES = 25
RATIO_CLAMP = (0.7, 2.2)


def as_utc(value: Optional[datetime]) -> Optional[datetime]:
    """Normalize a possibly naive datetime to UTC-aware."""
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _type_index(incident_type: Optional[str]) -> float:
    if incident_type in INCIDENT_TYPES:
        return float(INCIDENT_TYPES.index(incident_type))
    return 0.0


def _features(
    distance_km: float,
    baseline_duration_min: float,
    started_at: Optional[datetime],
    traffic_factor: Optional[float],
    incident_type: Optional[str],
) -> list[float]:
    started = as_utc(started_at) or datetime.now(timezone.utc)
    return [
        distance_km,
        baseline_duration_min,
        float(started.hour),
        float(started.weekday()),
        float(traffic_factor or 1.0),
        _type_index(incident_type),
    ]


class ETAPredictor:
    """Gradient-boosted ETA ratio predictor, persisted to models/."""

    MODEL_VERSION = "eta-v1"

    def __init__(self) -> None:
        self._model = None

    @property
    def is_ready(self) -> bool:
        return self._model is not None

    def ensure_model(self) -> bool:
        """Load the persisted model if present (never raises)."""
        if self._model is not None:
            return True
        try:
            import joblib

            if ETA_MODEL_PATH.exists():
                self._model = joblib.load(ETA_MODEL_PATH)
                logger.info("Loaded learned ETA model (%s)", self.MODEL_VERSION)
                return True
        except Exception as exc:
            logger.warning("ETA model load failed: %s", exc)
        return False

    def train(self, rows: list[dict]) -> dict:
        """Fit on completed-trip rows; persists the model to disk."""
        try:
            import joblib
            import numpy as np
            from sklearn.ensemble import HistGradientBoostingRegressor
        except ImportError as exc:
            raise RuntimeError("scikit-learn is required for ETA training") from exc

        samples: list[tuple[list[float], float]] = []
        for row in rows:
            baseline = row.get("baseline_duration_min")
            actual = row.get("actual_duration_min")
            distance = row.get("distance_km")
            if not baseline or baseline <= 0 or not distance or distance <= 0:
                continue
            if not actual or actual <= 0:
                continue
            ratio = actual / baseline
            if not 0.2 <= ratio <= 5.0:
                continue
            samples.append(
                (
                    _features(
                        distance,
                        baseline,
                        row.get("started_at"),
                        row.get("traffic_factor"),
                        row.get("incident_type"),
                    ),
                    ratio,
                )
            )

        if len(samples) < MIN_TRAINING_SAMPLES:
            raise ValueError(
                f"need at least {MIN_TRAINING_SAMPLES} completed trips to train, "
                f"got {len(samples)}"
            )

        x = np.array([feats for feats, _ in samples], dtype=float)
        y = np.array([ratio for _, ratio in samples], dtype=float)
        model = HistGradientBoostingRegressor(
            max_iter=250, max_depth=5, learning_rate=0.06, random_state=42
        )
        model.fit(x, y)
        mae = float(np.mean(np.abs(model.predict(x) - y)))

        ETA_MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(model, ETA_MODEL_PATH)
        self._model = model

        metrics = {
            "samples": len(samples),
            "mae_ratio": round(mae, 3),
            "model_version": self.MODEL_VERSION,
        }
        logger.info("Trained ETA model on %d trips (MAE ratio %.3f)", len(samples), mae)
        return metrics

    def predict_ratio(
        self,
        distance_km: float,
        baseline_duration_min: float,
        hour: int,
        day_of_week: int,
        traffic_factor: float,
        incident_type: Optional[str] = "general",
    ) -> Optional[float]:
        """Predicted actual/baseline ratio, clamped; None when unavailable."""
        if self._model is None and not self.ensure_model():
            return None
        try:
            import numpy as np

            features = np.array(
                [
                    [
                        distance_km,
                        baseline_duration_min,
                        float(hour),
                        float(day_of_week),
                        float(traffic_factor),
                        _type_index(incident_type),
                    ]
                ],
                dtype=float,
            )
            ratio = float(self._model.predict(features)[0])
            return max(RATIO_CLAMP[0], min(RATIO_CLAMP[1], ratio))
        except Exception as exc:
            logger.warning("ETA prediction failed: %s", exc)
            return None