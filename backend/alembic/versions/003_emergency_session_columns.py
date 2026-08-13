"""
Add missing columns to emergency_sessions to match EmergencySession model

Revision ID: 003
Revises: 002
Create Date: 2026-08-13

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, Sequence[str], None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "emergency_sessions",
        sa.Column("use_ai_prediction", sa.Boolean(), nullable=False, server_default="false"),
    )
    op.add_column("emergency_sessions", sa.Column("incident_type", sa.String(50), nullable=True))
    op.add_column("emergency_sessions", sa.Column("predicted_incident_lat", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("predicted_incident_lon", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("prediction_confidence", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("traffic_factor", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("trip_stage", sa.String(30), nullable=True, server_default="en_route"))
    op.add_column("emergency_sessions", sa.Column("patient_name", sa.String(255), nullable=True))
    op.add_column("emergency_sessions", sa.Column("patient_contact", sa.String(30), nullable=True))
    op.add_column("emergency_sessions", sa.Column("priority_level", sa.String(20), nullable=True, server_default="high"))
    op.add_column("emergency_sessions", sa.Column("pickup_latitude", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("pickup_longitude", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("hospital_name", sa.String(255), nullable=True))
    op.add_column("emergency_sessions", sa.Column("hospital_latitude", sa.Float(), nullable=True))
    op.add_column("emergency_sessions", sa.Column("hospital_longitude", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("emergency_sessions", "hospital_longitude")
    op.drop_column("emergency_sessions", "hospital_latitude")
    op.drop_column("emergency_sessions", "hospital_name")
    op.drop_column("emergency_sessions", "pickup_longitude")
    op.drop_column("emergency_sessions", "pickup_latitude")
    op.drop_column("emergency_sessions", "priority_level")
    op.drop_column("emergency_sessions", "patient_contact")
    op.drop_column("emergency_sessions", "patient_name")
    op.drop_column("emergency_sessions", "trip_stage")
    op.drop_column("emergency_sessions", "traffic_factor")
    op.drop_column("emergency_sessions", "prediction_confidence")
    op.drop_column("emergency_sessions", "predicted_incident_lon")
    op.drop_column("emergency_sessions", "predicted_incident_lat")
    op.drop_column("emergency_sessions", "incident_type")
    op.drop_column("emergency_sessions", "use_ai_prediction")
