"""Initial database schema

Revision ID: 001
Revises:
Create Date: 2026-05-29

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.Enum("admin", "driver", "officer", name="user_role"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_role", "users", ["role"])

    op.create_table(
        "ambulances",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("driver_id", sa.Integer(), nullable=False),
        sa.Column("vehicle_number", sa.String(50), nullable=False),
        sa.Column(
            "status",
            sa.Enum("available", "on_duty", "emergency", "offline", name="ambulance_status"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["driver_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("driver_id"),
        sa.UniqueConstraint("vehicle_number"),
    )
    op.create_index("ix_ambulances_status", "ambulances", ["status"])

    op.create_table(
        "traffic_officers",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("assigned_zone", sa.String(255), nullable=False),
        sa.Column("zone_latitude", sa.Float(), nullable=True),
        sa.Column("zone_longitude", sa.Float(), nullable=True),
        sa.Column("zone_radius_km", sa.Float(), nullable=False, server_default="5.0"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )

    op.create_table(
        "emergency_sessions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("ambulance_id", sa.Integer(), nullable=False),
        sa.Column("destination", sa.String(500), nullable=False),
        sa.Column("dest_latitude", sa.Float(), nullable=True),
        sa.Column("dest_longitude", sa.Float(), nullable=True),
        sa.Column(
            "status",
            sa.Enum("active", "completed", "cancelled", name="emergency_status"),
            nullable=False,
        ),
        sa.Column("route_polyline", sa.Text(), nullable=True),
        sa.Column("eta_minutes", sa.Float(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["ambulance_id"], ["ambulances.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_emergency_sessions_ambulance_id", "emergency_sessions", ["ambulance_id"])
    op.create_index("ix_emergency_sessions_status", "emergency_sessions", ["status"])

    op.create_table(
        "gps_logs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("emergency_session_id", sa.Integer(), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("speed_kmh", sa.Float(), nullable=True),
        sa.Column("heading", sa.Float(), nullable=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["emergency_session_id"], ["emergency_sessions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_gps_logs_emergency_session_id", "gps_logs", ["emergency_session_id"])
    op.create_index("ix_gps_logs_timestamp", "gps_logs", ["timestamp"])

    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("officer_id", sa.Integer(), nullable=False),
        sa.Column("emergency_session_id", sa.Integer(), nullable=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_acknowledged", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["officer_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["emergency_session_id"], ["emergency_sessions.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_notifications_officer_id", "notifications", ["officer_id"])


def downgrade() -> None:
    op.drop_table("notifications")
    op.drop_table("gps_logs")
    op.drop_table("emergency_sessions")
    op.drop_table("traffic_officers")
    op.drop_table("ambulances")
    op.drop_table("users")
    op.execute("DROP TYPE IF EXISTS user_role")
    op.execute("DROP TYPE IF EXISTS ambulance_status")
    op.execute("DROP TYPE IF EXISTS emergency_status")
