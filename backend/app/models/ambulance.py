"""Ambulance vehicle model."""

import enum

from sqlalchemy import Enum, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class AmbulanceStatus(str, enum.Enum):
    AVAILABLE = "available"
    ON_DUTY = "on_duty"
    EMERGENCY = "emergency"
    OFFLINE = "offline"


class Ambulance(Base):
    """Registered ambulance unit."""

    __tablename__ = "ambulances"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    driver_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    vehicle_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    status: Mapped[AmbulanceStatus] = mapped_column(
        Enum(
            AmbulanceStatus,
            name="ambulance_status",
            values_callable=lambda x: [e.value for e in x],
            native_enum=False,
        ),
        default=AmbulanceStatus.AVAILABLE,
        nullable=False,
        index=True,
    )

    driver = relationship("User", back_populates="ambulance")
    emergency_sessions = relationship("EmergencySession", back_populates="ambulance")
