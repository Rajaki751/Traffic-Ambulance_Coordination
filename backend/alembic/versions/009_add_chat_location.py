"""Add location payload to chat messages.

Revision ID: 009_add_chat_location
Revises: 008_add_chat_tables
Create Date: 2026-08-14
"""

from alembic import op
import sqlalchemy as sa

revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("chat_messages", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("chat_messages", sa.Column("longitude", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("chat_messages", "longitude")
    op.drop_column("chat_messages", "latitude")