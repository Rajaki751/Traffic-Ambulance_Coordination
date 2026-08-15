"""Lightweight SQLite schema migrations for development."""

from sqlalchemy import inspect, text

from app.core.config import get_settings
from app.core.logging import get_logger
from app.database.session import engine

logger = get_logger(__name__)

EMERGENCY_SESSION_COLUMNS = [
    ("use_ai_prediction", "BOOLEAN NOT NULL DEFAULT 0"),
    ("incident_type", "VARCHAR(50)"),
    ("predicted_incident_lat", "FLOAT"),
    ("predicted_incident_lon", "FLOAT"),
    ("prediction_confidence", "FLOAT"),
    ("traffic_factor", "FLOAT"),
    ("trip_stage", "VARCHAR(30)"),
    ("patient_name", "VARCHAR(255)"),
    ("patient_contact", "VARCHAR(30)"),
    ("priority_level", "VARCHAR(20)"),
    ("pickup_latitude", "FLOAT"),
    ("pickup_longitude", "FLOAT"),
    ("hospital_name", "VARCHAR(255)"),
    ("hospital_latitude", "FLOAT"),
    ("hospital_longitude", "FLOAT"),
    ("baseline_duration_min", "FLOAT"),
    ("actual_duration_min", "FLOAT"),
    ("distance_km", "FLOAT"),
    ("congestion_score", "FLOAT"),
]

NOTIFICATION_COLUMNS = [
    ("user_id", "INTEGER"),
    ("notification_type", "VARCHAR(50) NOT NULL DEFAULT 'emergency_alert'"),
    ("acknowledgment", "VARCHAR(20)"),
]


async def run_dev_migrations() -> None:
    """Add missing columns to existing SQLite tables (dev only)."""
    settings = get_settings()
    if "sqlite" not in settings.database_url.lower():
        return

    async with engine.begin() as conn:
        def _existing_columns(sync_conn):
            insp = inspect(sync_conn)
            if not insp.has_table("emergency_sessions"):
                return set()
            return {col["name"] for col in insp.get_columns("emergency_sessions")}

        existing = await conn.run_sync(_existing_columns)
        if not existing:
            return

        for name, ddl in EMERGENCY_SESSION_COLUMNS:
            if name in existing:
                continue
            await conn.execute(
                text(f"ALTER TABLE emergency_sessions ADD COLUMN {name} {ddl}")
            )
            logger.info("Added column emergency_sessions.%s", name)

        def _notification_columns(sync_conn):
            insp = inspect(sync_conn)
            if not insp.has_table("notifications"):
                return set()
            return {col["name"] for col in insp.get_columns("notifications")}

        notif_existing = await conn.run_sync(_notification_columns)
        for name, ddl in NOTIFICATION_COLUMNS:
            if name in notif_existing:
                continue
            await conn.execute(text(f"ALTER TABLE notifications ADD COLUMN {name} {ddl}"))
            logger.info("Added column notifications.%s", name)
