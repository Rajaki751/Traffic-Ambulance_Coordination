"""AI incident prediction, learned ETA, and hotspot management APIs."""

import asyncio

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.eta_predictor import ETAPredictor, MIN_TRAINING_SAMPLES
from app.ai.hotspot_discovery import (
    MIN_RECORDS,
    discover_hotspots,
    load_hotspots,
    save_hotspots,
)
from app.ai.incident_predictor import (
    INCIDENT_TYPES,
    IncidentLocationPredictor,
)
from app.ai.learning import fetch_completed_trips
from app.ai.route_prediction import RoutePredictionService
from app.api.deps import RequireAdmin, RequireAnyAuth
from app.database.session import get_db
from app.schemas.ai import (
    IncidentPredictRequest,
    IncidentPredictResponse,
    ModelInfoResponse,
    RouteToIncidentRequest,
    RouteToIncidentResponse,
)

router = APIRouter()
route_prediction_service = RoutePredictionService()
incident_predictor = IncidentLocationPredictor()


@router.get("/model-info", response_model=ModelInfoResponse)
async def model_info(_: RequireAnyAuth):
    """Return estimator metadata and supported incident types."""
    eta_predictor = ETAPredictor()
    eta_ready = eta_predictor.ensure_model()
    return ModelInfoResponse(
        model_loaded=True,
        model_version=IncidentLocationPredictor.MODEL_VERSION,
        model_path="built-in hotspot-anchored algorithm (no model file)",
        supported_incident_types=INCIDENT_TYPES,
        description=(
            "Deterministic hotspot-anchored estimator: caller position, "
            "per-type reach profiles, and a curated Kathmandu risk hotspot "
            "table produce the incident estimate; learned hotspots refine it. "
            "A gradient-boosted ETA model, trained on completed trips, "
            "corrects OSRM baseline durations. OSRM provides shortest-path "
            "routing with traffic-adjusted ETA."
        ),
        eta_ready=eta_ready,
        eta_model_version=ETAPredictor.MODEL_VERSION if eta_ready else None,
        eta_training_samples=(
            MIN_TRAINING_SAMPLES if not eta_ready else None
        ),
        discovered_hotspots=len(load_hotspots()),
    )


@router.post("/predict-incident", response_model=IncidentPredictResponse)
async def predict_incident(payload: IncidentPredictRequest, _: RequireAnyAuth):
    """Forecast incident location using the hotspot-anchored estimator."""
    try:
        prediction, traffic = await route_prediction_service.predict_incident(
            payload.caller_latitude,
            payload.caller_longitude,
            payload.incident_type,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc

    return IncidentPredictResponse(
        incident_latitude=prediction.incident_latitude,
        incident_longitude=prediction.incident_longitude,
        confidence=prediction.confidence,
        model_version=prediction.model_version,
        traffic_factor=traffic.factor,
        traffic_index=traffic.index,
        traffic_label=traffic.label,
    )


@router.post("/route-to-incident", response_model=RouteToIncidentResponse)
async def route_to_incident(payload: RouteToIncidentRequest, _: RequireAnyAuth):
    """
    Predict incident location and compute fastest ambulance route (OSRM)
    with real-time traffic adjustment.
    """
    try:
        result = await route_prediction_service.predict_and_route(
            ambulance_latitude=payload.ambulance_latitude,
            ambulance_longitude=payload.ambulance_longitude,
            caller_latitude=payload.caller_latitude,
            caller_longitude=payload.caller_longitude,
            incident_type=payload.incident_type,
            manual_incident_lat=payload.manual_incident_lat,
            manual_incident_lon=payload.manual_incident_lon,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Route prediction failed: {exc}") from exc

    return RouteToIncidentResponse(
        used_ai_prediction=result.used_ai_prediction,
        incident_latitude=result.prediction.incident_latitude,
        incident_longitude=result.prediction.incident_longitude,
        prediction_confidence=result.prediction.confidence,
        model_version=result.prediction.model_version,
        traffic_factor=result.traffic.factor,
        traffic_index=result.traffic.index,
        traffic_label=result.traffic.label,
        route=result.route,
    )


@router.post("/retrain-model")
async def retrain_model(_: RequireAdmin, db: AsyncSession = Depends(get_db)):
    """Train the learned ETA model and discover hotspots from completed trips (admin)."""
    trips = await fetch_completed_trips(db)

    if len(trips) < MIN_TRAINING_SAMPLES:
        return {
            "status": "info",
            "note": (
                f"need at least {MIN_TRAINING_SAMPLES} completed trips to train "
                f"the ETA model, have {len(trips)}"
            ),
            "eta": None,
            "hotspots": None,
        }

    try:
        metrics = await asyncio.to_thread(ETAPredictor().train, trips)
    except ValueError as exc:
        return {"status": "info", "note": str(exc), "eta": None, "hotspots": None}
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    records = [
        (t["dest_latitude"], t["dest_longitude"], t["incident_type"])
        for t in trips
        if t.get("dest_latitude") is not None and t.get("dest_longitude") is not None
    ]
    discovered: list[dict] = []
    if len(records) >= MIN_RECORDS:
        discovered = await asyncio.to_thread(discover_hotspots, records)
        if discovered:
            await asyncio.to_thread(save_hotspots, discovered, len(records))
            incident_predictor.ensure_model()

    return {
        "status": "ok",
        "eta": metrics,
        "hotspots": {
            "clusters": len(discovered),
            "records_used": len(records),
            "discovered": discovered,
        },
    }