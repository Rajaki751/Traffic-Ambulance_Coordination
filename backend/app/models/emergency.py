"""Emergency session model."""

import enum
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, String, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class EmergencyStatus(str, enum.Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class TripStage(str, enum.Enum):
    """Driver trip progress through an emergency run."""

    EN_ROUTE = "en_route"
    ARRIVED_PATIENT = "arrived_patient"
    PATIENT_PICKED_UP = "patient_picked_up"
    ARRIVED_HOSPITAL = "arrived_hospital"
    COMPLETED = "completed"


class EmergencySession(Base):
    """Active or historical emergency run."""

    __tablename__ = "emergency_sessions"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    ambulance_id: Mapped[int] = mapped_column(
        ForeignKey("ambulances.id", ondelete="CASCADE"), nullable=False, index=True
    )
    destination: Mapped[str] = mapped_column(String(500), nullable=False)
    dest_latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    dest_longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    status: Mapped[EmergencyStatus] = mapped_column(
        Enum(
            EmergencyStatus,
            name="emergency_status",
            values_callable=lambda x: [e.value for e in x],
            native_enum=False,
        ),
        default=EmergencyStatus.ACTIVE,
        nullable=False,
        index=True,
    )
    route_polyline: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    route_steps: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    eta_minutes: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    use_ai_prediction: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    incident_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    predicted_incident_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    predicted_incident_lon: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prediction_confidence: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    traffic_factor: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    baseline_duration_min: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    actual_duration_min: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    distance_km: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    congestion_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    trip_stage: Mapped[Optional[str]] = mapped_column(String(30), nullable=True, default="en_route")
    patient_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    patient_contact: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    priority_level: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, default="high")
    pickup_latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pickup_longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    hospital_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    hospital_latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    hospital_longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    ended_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    ambulance = relationship("Ambulance", back_populates="emergency_sessions")
    gps_logs = relationship(
        "GPSLog", back_populates="emergency_session", cascade="all, delete-orphan"
    )
