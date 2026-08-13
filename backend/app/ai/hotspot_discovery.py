"""
Discover recurrent incident hotspots from completed emergency sessions.

Once enough real incidents have been recorded, KMeans clustering of their
actual locations reveals accident zones the curated table never listed.
Discovered clusters join the curated hotspots inside the incident
estimator, so predictions tune themselves to observed reality.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from app.ai.incident_predictor import INCIDENT_TYPES

logger = logging.getLogger(__name__)

_MODELS_DIR = Path(__file__).resolve().parents[2] / "models"
HOTSPOTS_PATH = _MODELS_DIR / "hotspots.json"

MIN_RECORDS = 20
MIN_CLUSTER_SIZE = 3

# Dominant incident type -> hotspot kinds offered to the estimator.
_DOMINANT_KIND = {
    "accident": {"junction"},
    "trauma": {"junction"},
    "fire": {"market", "junction"},
    "cardiac": {"hospital"},
    "respiratory": {"hospital"},
    "general": {"junction", "arterial", "market", "hospital"},
}


def discover_hotspots(records: list[tuple[float, float, str]]) -> list[dict]:
    """Cluster (lat, lon, incident_type) records; returns learner hotspots."""
    try:
        from sklearn.cluster import KMeans
        from sklearn.metrics import silhouette_score
    except ImportError as exc:
        logger.warning("scikit-learn unavailable; hotspot discovery skipped")
        raise RuntimeError("scikit-learn is required for hotspot discovery") from exc

    if len(records) < MIN_RECORDS:
        return []

    points = [[latitude, longitude] for latitude, longitude, _ in records]
    max_k = min(12, len(records) // MIN_CLUSTER_SIZE)
    if max_k < 2:
        return []

    best: Optional[tuple[float, int, object]] = None
    for k in range(2, max_k + 1):
        km = KMeans(n_clusters=k, n_init=10, random_state=42).fit(points)
        labels = km.labels_
        if len(set(labels.tolist())) < 2:
            continue
        score = float(silhouette_score(points, labels))
        if best is None or score > best[0]:
            best = (score, k, km)

    if best is None:
        return []

    _, k, km = best
    hotspots: list[dict] = []
    for i in range(k):
        members = [
            records[j] for j in range(len(records)) if int(km.labels_[j]) == i
        ]
        size = len(members)
        if size < MIN_CLUSTER_SIZE:
            continue
        types = [t for _, _, t in members if t in INCIDENT_TYPES]
        dominant = max(set(types), key=types.count) if types else "general"
        kinds = _DOMINANT_KIND.get(dominant, _DOMINANT_KIND["general"])
        centroid = km.cluster_centers_[i]
        hotspots.append(
            {
                "name": f"Learned cluster {i + 1}",
                "lat": round(float(centroid[0]), 6),
                "lon": round(float(centroid[1]), 6),
                "kinds": sorted(kinds),
                "size": size,
                "dominant_type": dominant,
            }
        )

    hotspots.sort(key=lambda h: h["size"], reverse=True)
    logger.info("Discovered %d hotspot clusters from %d records", len(hotspots), len(records))
    return hotspots


def save_hotspots(hotspots: list[dict], records_used: int) -> None:
    """Persist discovered hotspots as models/hotspots.json."""
    payload = {
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "records_used": records_used,
        "hotspots": hotspots,
    }
    HOTSPOTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    HOTSPOTS_PATH.write_text(json.dumps(payload, indent=2))
    logger.info("Saved %d discovered hotspots to %s", len(hotspots), HOTSPOTS_PATH)


def load_hotspots() -> list[dict]:
    """Read discovered hotspots; kinds come back as sets for the estimator."""
    try:
        if not HOTSPOTS_PATH.exists():
            return []
        data = json.loads(HOTSPOTS_PATH.read_text())
        hotspots = data.get("hotspots", [])
        for hotspot in hotspots:
            hotspot["kinds"] = set(hotspot.get("kinds", []))
        return hotspots
    except Exception as exc:
        logger.warning("Failed to load discovered hotspots: %s", exc)
        return []