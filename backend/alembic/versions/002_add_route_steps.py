"""
Add route_steps JSON column to emergency_sessions

Revision ID: 002
Revises: 001
Create Date: 2026-07-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, Sequence[str], None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add JSON column to store route steps
    op.add_column(
        "emergency_sessions",
        sa.Column("route_steps", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("emergency_sessions", "route_steps")
