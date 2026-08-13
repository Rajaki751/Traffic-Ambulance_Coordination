"""Junction clearance records by traffic officers."""

from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class JunctionClearance(Base):
    """Officer marks a Kathmandu junction as cleared for ambulance passage."""

    __tablename__ = "junction_clearances"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    officer_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    emergency_session_id: Mapped[int | None] = mapped_column(
        ForeignKey("emergency_sessions.id", ondelete="SET NULL"), nullable=True
    )
    junction_name: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    cleared_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
