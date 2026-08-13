"""Traffic officer profile model."""

from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class TrafficOfficer(Base):
    """Extended profile for traffic officers with zone assignment."""

    __tablename__ = "traffic_officers"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    assigned_zone: Mapped[str] = mapped_column(String(255), nullable=False)
    # Zone center for proximity matching
    zone_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    zone_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    zone_radius_km: Mapped[float] = mapped_column(Float, default=5.0, nullable=False)

    user = relationship("User", back_populates="officer_profile")
