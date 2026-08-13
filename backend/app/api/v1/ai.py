"""AI incident prediction and traffic-aware routing APIs."""

from fastapi import APIRouter, HTTPException

from app.ai.incident_predictor import INCIDENT_TYPES, MODEL_PATH, IncidentLocationPredictor
from app.ai.route_prediction import RoutePredictionService
from app.api.deps import RequireAnyAuth
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
    """Return ML model metadata and training status."""
    loaded = MODEL_PATH.exists()
    return ModelInfoResponse(
        model_loaded=loaded,
        model_version=IncidentLocationPredictor.MODEL_VERSION if loaded else None,
        model_path=str(MODEL_PATH),
        supported_incident_types=INCIDENT_TYPES,
        description=(
            "Random Forest (scikit-learn) forecasts incident coordinates from "
            "caller location, time, traffic index, and incident type. "
            "OSRM provides shortest-path routing with traffic-adjusted ETA."
        ),
    )


@router.post("/predict-incident", response_model=IncidentPredictResponse)
async def predict_incident(payload: IncidentPredictRequest, _: RequireAnyAuth):
    """Forecast incident location using scikit-learn ML model."""
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
    Predict incident location (ML) and compute fastest ambulance route (OSRM)
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
async def retrain_model(_: RequireAnyAuth):
    """Retrain incident location model from historical CSV data."""
    try:
        metrics = incident_predictor.train()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Training failed: {exc}") from exc
    return {"status": "ok", "metrics": metrics}
