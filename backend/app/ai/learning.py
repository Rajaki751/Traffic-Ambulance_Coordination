"""
Startup-time model provisioning: learned ETA + hotspot discovery.

Reads completed emergency sessions and, when enough ground truth exists,
trains the ETA model and discovers hotspot clusters. Best-effort by design:
a missing dependency or a small dataset can never block startup.
"""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from sqlalchemy import select

from app.ai.hotspot_discovery import (
    HOTSPOTS_PATH,
    MIN_RECORDS,
    discover_hotspots,
    load_hotspots,
    save_hotspots,
)
from app.ai.incident_predictor import IncidentLocationPredictor
from app.database.session import async_session_maker
from app.models.emergency import EmergencySession, EmergencyStatus

logger = logging.getLogger(__name__)

_SESSION_COLUMNS = (
    EmergencySession.distance_km,
    EmergencySession.baseline_duration_min,
    EmergencySession.actual_duration_min,
    EmergencySession.traffic_factor,
    EmergencySession.incident_type,
    EmergencySession.started_at,
    EmergencySession.dest_latitude,
    EmergencySession.dest_longitude,
)


async def fetch_completed_trips(db: Any) -> list[dict]:
    """All completed sessions as plain dicts, null-safe."""
    result = await db.execute(
        select(*_SESSION_COLUMNS).where(
            EmergencySession.status == EmergencyStatus.COMPLETED
        )
    )
    return [dict(row._mapping) for row in result.all()]


async def ensure_learning_models() -> dict:
    """Train/persist learned models when ground truth exists (idempotent)."""
    eta = {"trained": False}
    hotspots = {"discovered": 0}

    async with async_session_maker() as db:
        trips = await fetch_completed_trips(db)

    from app.ai.eta_predictor import ETA_MODEL_PATH, ETAPredictor, MIN_TRAINING_SAMPLES

    eta_predictor = ETAPredictor()
    if eta_predictor.ensure_model():
        eta = {"trained": True, "source": "cached"}
    else:
        usable = [
            t
            for t in trips
            if t.get("baseline_duration_min") and t.get("actual_duration_min")
        ]
        if len(usable) >= MIN_TRAINING_SAMPLES:
            try:
                metrics = await asyncio.to_thread(eta_predictor.train, usable)
                eta = {"trained": True, "source": "trained", **metrics}
            except Exception as exc:
                logger.warning("ETA training at startup failed: %s", exc)
                eta = {"trained": False, "error": str(exc)}
        else:
            eta = {
                "trained": False,
                "samples": len(usable),
                "need": MIN_TRAINING_SAMPLES,
            }

    if HOTSPOTS_PATH.exists():
        hotspots = {"discovered": len(load_hotspots()), "source": "cached"}
    else:
        records = [
            (t["dest_latitude"], t["dest_longitude"], t["incident_type"])
            for t in trips
            if t.get("dest_latitude") is not None
            and t.get("dest_longitude") is not None
        ]
        if len(records) >= MIN_RECORDS:
            try:
                found = await asyncio.to_thread(discover_hotspots, records)
                if found:
                    await asyncio.to_thread(save_hotspots, found, len(records))
                    hotspots = {"discovered": len(found), "source": "trained"}
            except Exception as exc:
                logger.warning("Hotspot discovery at startup failed: %s", exc)
        else:
            hotspots = {"samples": len(records), "need": MIN_RECORDS}

    IncidentLocationPredictor().ensure_model()
    return {"eta": eta, "hotspots": hotspots}