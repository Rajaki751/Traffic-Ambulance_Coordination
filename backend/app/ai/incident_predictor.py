"""
ML incident location prediction using scikit-learn Random Forest.

Trained on historical incident patterns (caller location, time, traffic, type)
to forecast where an emergency is likely occurring.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from app.core.logging import get_logger

logger = get_logger(__name__)

DATA_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "incidents_history.csv"
MODEL_PATH = Path(__file__).resolve().parent.parent.parent / "models" / "incident_location_model.joblib"

INCIDENT_TYPES = ["accident", "cardiac", "fire", "respiratory", "trauma", "general"]
FEATURE_COLUMNS = [
    "caller_latitude",
    "caller_longitude",
    "hour",
    "day_of_week",
    "traffic_index",
    "incident_type",
]
TARGET_COLUMNS = ["incident_latitude", "incident_longitude"]


@dataclass
class IncidentPrediction:
    incident_latitude: float
    incident_longitude: float
    confidence: float
    model_version: str


class IncidentLocationPredictor:
    """scikit-learn based incident coordinate forecaster."""

    MODEL_VERSION = "rf-v1"

    def __init__(self) -> None:
        self._pipeline: Pipeline | None = None

    def ensure_model(self) -> None:
        if self._pipeline is not None:
            return
        if MODEL_PATH.exists():
            self._pipeline = joblib.load(MODEL_PATH)
            logger.info("Loaded incident ML model from %s", MODEL_PATH)
            return
        logger.info("No ML model found; training from historical data...")
        self.train()
        self._pipeline = joblib.load(MODEL_PATH)

    def train(self) -> dict[str, float]:
        if not DATA_PATH.exists():
            from scripts.generate_incident_data import generate

            generate()

        df = pd.read_csv(DATA_PATH)
        x = df[FEATURE_COLUMNS]
        y = df[TARGET_COLUMNS]

        preprocessor = ColumnTransformer(
            transformers=[
                (
                    "cat",
                    OneHotEncoder(handle_unknown="ignore"),
                    ["incident_type"],
                ),
                (
                    "num",
                    StandardScaler(),
                    [
                        "caller_latitude",
                        "caller_longitude",
                        "hour",
                        "day_of_week",
                        "traffic_index",
                    ],
                ),
            ]
        )

        model = RandomForestRegressor(
            n_estimators=120,
            max_depth=14,
            min_samples_leaf=4,
            random_state=42,
            n_jobs=-1,
        )

        pipeline = Pipeline(
            steps=[
                ("preprocess", preprocessor),
                ("regressor", model),
            ]
        )

        x_train, x_test, y_train, y_test = train_test_split(
            x, y, test_size=0.2, random_state=42
        )
        pipeline.fit(x_train, y_train)
        preds = pipeline.predict(x_test)
        mae_lat = mean_absolute_error(y_test["incident_latitude"], preds[:, 0])
        mae_lon = mean_absolute_error(y_test["incident_longitude"], preds[:, 1])

        MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(pipeline, MODEL_PATH)
        self._pipeline = pipeline

        metrics = {
            "mae_latitude": round(mae_lat, 5),
            "mae_longitude": round(mae_lon, 5),
            "samples": len(df),
        }
        logger.info("Incident model trained: %s", metrics)
        return metrics

    def predict(
        self,
        caller_latitude: float,
        caller_longitude: float,
        hour: int,
        day_of_week: int,
        traffic_index: float,
        incident_type: str = "general",
    ) -> IncidentPrediction:
        self.ensure_model()
        assert self._pipeline is not None

        if incident_type not in INCIDENT_TYPES:
            incident_type = "general"

        row = pd.DataFrame(
            [
                {
                    "caller_latitude": caller_latitude,
                    "caller_longitude": caller_longitude,
                    "hour": hour,
                    "day_of_week": day_of_week,
                    "traffic_index": traffic_index,
                    "incident_type": incident_type,
                }
            ]
        )
        pred = self._pipeline.predict(row)[0]
        lat, lon = float(pred[0]), float(pred[1])

        # Confidence from forest tree variance (lower spread = higher confidence)
        regressor: RandomForestRegressor = self._pipeline.named_steps["regressor"]
        preprocessed = self._pipeline.named_steps["preprocess"].transform(row)
        tree_preds = np.array([t.predict(preprocessed)[0] for t in regressor.estimators_])
        spread_km = np.mean(
            np.sqrt(
                (tree_preds[:, 0] - lat) ** 2 + (tree_preds[:, 1] - lon) ** 2
            )
        ) * 111  # rough deg->km
        confidence = max(0.35, min(0.98, 1.0 - spread_km / 2.5))

        return IncidentPrediction(
            incident_latitude=round(lat, 6),
            incident_longitude=round(lon, 6),
            confidence=float(round(confidence, 2)),
            model_version=self.MODEL_VERSION,
        )
