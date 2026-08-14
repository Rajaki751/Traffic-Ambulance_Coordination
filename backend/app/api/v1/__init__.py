"""API v1 router aggregation."""

from fastapi import APIRouter

from app.api.v1 import (
    ai,
    ambulances,
    analytics,
    auth,
    chat,
    emergencies,
    gps,
    junctions,
    notifications,
    profile,
    routes,
    directions,
    users,
)

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(profile.router, prefix="/profile", tags=["Profile"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(ambulances.router, prefix="/ambulances", tags=["Ambulances"])
api_router.include_router(emergencies.router, prefix="/emergencies", tags=["Emergencies"])
api_router.include_router(gps.router, prefix="/gps", tags=["GPS Tracking"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(chat.router, prefix="/chat", tags=["Chat"])
api_router.include_router(junctions.router, prefix="/junctions", tags=["Junction Management"])
api_router.include_router(routes.router, prefix="/routes", tags=["Route Optimization"])
api_router.include_router(directions.router, prefix="/directions", tags=["Directions"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI Route Prediction"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
