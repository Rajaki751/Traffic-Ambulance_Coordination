"""GPS location log model."""

from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class GPSLog(Base):
    """Timestamped GPS coordinate for an emergency session."""

    __tablename__ = "gps_logs"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    emergency_session_id: Mapped[int] = mapped_column(
        ForeignKey("emergency_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    speed_kmh: Mapped[float | None] = mapped_column(Float, nullable=True)
    heading: Mapped[float | None] = mapped_column(Float, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )

    emergency_session = relationship("EmergencySession", back_populates="gps_logs")
