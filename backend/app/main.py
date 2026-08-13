"""
AI-Driven Traffic Ambulance Coordination System - FastAPI Application Entry Point.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import api_router
from app.core.config import get_settings
from app.core.logging import get_logger, setup_logging
from app.database.session import init_db
from app.database.migrate import run_dev_migrations
from app.websocket.routes import router as ws_router

setup_logging()
logger = get_logger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    logger.info("Starting %s v%s", settings.app_name, settings.app_version)
    if settings.environment == "development":
        await init_db()
        await run_dev_migrations()
        logger.info("Database tables initialized (development mode)")
    try:
        from app.ai.incident_predictor import IncidentLocationPredictor

        IncidentLocationPredictor().ensure_model()
        logger.info("Incident location ML model ready")
    except Exception as exc:
        logger.warning("ML model not loaded at startup: %s", exc)
    yield
    logger.info("Shutting down application")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "AI-Driven Traffic Ambulance Coordination API. "
        "Real-time GPS tracking, route optimization, and traffic officer alerts."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """Security headers, with a CSP that keeps Swagger UI working."""
    response = await call_next(request)
    response.headers.setdefault(
        "Strict-Transport-Security", "max-age=15552000; includeSubDomains"
    )
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "no-referrer")
    response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
    response.headers.setdefault(
        "Content-Security-Policy",
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "img-src 'self' data:; "
        "connect-src 'self' ws: wss:; "
        "frame-ancestors 'none'",
    )
    return response

app.include_router(api_router)
app.include_router(ws_router, prefix="/ws", tags=["WebSocket"])


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


@app.get("/health")
async def health_check():
    """Health check endpoint for deployment probes."""
    return {
        "status": "healthy",
        "app": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
    }


@app.get("/")
async def root():
    return {
        "message": "Ambulance Coordination API",
        "docs": "/docs",
        "health": "/health",
    }
