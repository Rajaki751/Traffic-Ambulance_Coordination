"""Add ETA learning columns to emergency_sessions

Revision ID: 006
Revises: 005
Create Date: 2026-08-13

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "006"
down_revision: Union[str, Sequence[str], None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_exists(table: str, column: str) -> bool:
    return column in {
        c["name"] for c in sa.inspect(op.get_bind()).get_columns(table)
    }


def upgrade() -> None:
    for name in (
        "baseline_duration_min",
        "actual_duration_min",
        "distance_km",
        "congestion_score",
    ):
        if not _column_exists("emergency_sessions", name):
            op.add_column(
                "emergency_sessions",
                sa.Column(name, sa.Float(), nullable=True),
            )


def downgrade() -> None:
    for name in (
        "baseline_duration_min",
        "actual_duration_min",
        "distance_km",
        "congestion_score",
    ):
        if _column_exists("emergency_sessions", name):
            op.drop_column("emergency_sessions", name)