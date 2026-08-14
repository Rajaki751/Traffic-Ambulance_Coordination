"""Add acknowledgment action to notifications

Revision ID: 007
Revises: 006
Create Date: 2026-08-14

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "007"
down_revision: Union[str, Sequence[str], None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_exists(table: str, column: str) -> bool:
    return column in {
        c["name"] for c in sa.inspect(op.get_bind()).get_columns(table)
    }


def upgrade() -> None:
    if not _column_exists("notifications", "acknowledgment"):
        op.add_column(
            "notifications",
            sa.Column("acknowledgment", sa.String(length=20), nullable=True),
        )


def downgrade() -> None:
    if _column_exists("notifications", "acknowledgment"):
        op.drop_column("notifications", "acknowledgment")