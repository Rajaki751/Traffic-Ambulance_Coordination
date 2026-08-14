"""Add group chat tables for emergency sessions

Revision ID: 008
Revises: 007
Create Date: 2026-08-14

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "008"
down_revision: Union[str, Sequence[str], None] = "007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _table_exists(table: str) -> bool:
    return table in sa.inspect(op.get_bind()).get_table_names()


def upgrade() -> None:
    if not _table_exists("chat_messages"):
        op.create_table(
            "chat_messages",
            sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column(
                "emergency_session_id",
                sa.Integer(),
                sa.ForeignKey("emergency_sessions.id", ondelete="CASCADE"),
                nullable=False,
                index=True,
            ),
            sa.Column(
                "sender_user_id",
                sa.Integer(),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
                index=True,
            ),
            sa.Column("message", sa.Text(), nullable=False),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                nullable=False,
            ),
        )
    if not _table_exists("chat_last_read"):
        op.create_table(
            "chat_last_read",
            sa.Column(
                "emergency_session_id",
                sa.Integer(),
                sa.ForeignKey("emergency_sessions.id", ondelete="CASCADE"),
                primary_key=True,
            ),
            sa.Column(
                "user_id",
                sa.Integer(),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                primary_key=True,
            ),
            sa.Column(
                "last_read_at",
                sa.DateTime(timezone=True),
                nullable=False,
            ),
        )


def downgrade() -> None:
    if _table_exists("chat_last_read"):
        op.drop_table("chat_last_read")
    if _table_exists("chat_messages"):
        op.drop_table("chat_messages")
