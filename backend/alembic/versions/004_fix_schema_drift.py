"""Fix schema drift: junction_clearances table + notification columns

Revision ID: 004
Revises: 003
Create Date: 2026-08-13

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "004"
down_revision: Union[str, Sequence[str], None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _table_exists(name: str) -> bool:
    return sa.inspect(op.get_bind()).has_table(name)


def _column_exists(table: str, column: str) -> bool:
    return column in {
        c["name"] for c in sa.inspect(op.get_bind()).get_columns(table)
    }


def _index_exists(table: str, index: str) -> bool:
    return index in {
        i["name"] for i in sa.inspect(op.get_bind()).get_indexes(table)
    }


def _fk_exists(table: str, fk_name: str) -> bool:
    return fk_name in {
        fk["name"] for fk in sa.inspect(op.get_bind()).get_foreign_keys(table)
    }


def upgrade() -> None:
    if not _table_exists("junction_clearances"):
        op.create_table(
            "junction_clearances",
            sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
            sa.Column("officer_id", sa.Integer(), nullable=False),
            sa.Column("emergency_session_id", sa.Integer(), nullable=True),
            sa.Column("junction_name", sa.String(255), nullable=False),
            sa.Column("latitude", sa.Float(), nullable=False),
            sa.Column("longitude", sa.Float(), nullable=False),
            sa.Column("notes", sa.Text(), nullable=True),
            sa.Column("cleared_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(
                ["emergency_session_id"],
                ["emergency_sessions.id"],
                ondelete="SET NULL",
            ),
            sa.ForeignKeyConstraint(["officer_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
    if not _index_exists("junction_clearances", "ix_junction_clearances_officer_id"):
        op.create_index(
            "ix_junction_clearances_officer_id", "junction_clearances", ["officer_id"]
        )

    if not _column_exists("notifications", "user_id"):
        op.add_column("notifications", sa.Column("user_id", sa.Integer(), nullable=True))
    if not _index_exists("notifications", "ix_notifications_user_id"):
        op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
    if not _fk_exists("notifications", "fk_notifications_user_id_users"):
        op.create_foreign_key(
            "fk_notifications_user_id_users",
            "notifications",
            "users",
            ["user_id"],
            ["id"],
            ondelete="CASCADE",
        )
    if not _column_exists("notifications", "notification_type"):
        op.add_column(
            "notifications",
            sa.Column("notification_type", sa.String(50), nullable=True),
        )


def downgrade() -> None:
    if _column_exists("notifications", "notification_type"):
        op.drop_column("notifications", "notification_type")
    if _fk_exists("notifications", "fk_notifications_user_id_users"):
        op.drop_constraint(
            "fk_notifications_user_id_users", "notifications", type_="foreignkey"
        )
    if _index_exists("notifications", "ix_notifications_user_id"):
        op.drop_index("ix_notifications_user_id", table_name="notifications")
    if _column_exists("notifications", "user_id"):
        op.drop_column("notifications", "user_id")

    if _table_exists("junction_clearances"):
        if _index_exists("junction_clearances", "ix_junction_clearances_officer_id"):
            op.drop_index(
                "ix_junction_clearances_officer_id", table_name="junction_clearances"
            )
        op.drop_table("junction_clearances")
