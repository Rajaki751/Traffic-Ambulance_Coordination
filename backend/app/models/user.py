"""User model with role-based access."""

import enum
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    DRIVER = "driver"
    OFFICER = "officer"


class User(Base):
    """System user account."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        Enum(
            UserRole,
            name="user_role",
            values_callable=lambda x: [e.value for e in x],
            native_enum=False,
        ),
        nullable=False,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    ambulance = relationship("Ambulance", back_populates="driver", uselist=False)
    officer_profile = relationship(
        "TrafficOfficer", back_populates="user", uselist=False
    )
    notifications = relationship(
        "Notification",
        back_populates="officer",
        foreign_keys="Notification.officer_id",
    )
