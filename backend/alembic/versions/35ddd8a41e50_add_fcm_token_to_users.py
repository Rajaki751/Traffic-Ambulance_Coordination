"""Add fcm_token to users

Revision ID: 35ddd8a41e50
Revises: 009
Create Date: 2026-08-15 22:11:13.331504

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
"""Add fcm_token to users

Revision ID: 35ddd8a41e50
Revises: 009
Create Date: 2026-08-15 22:11:13.331504

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '35ddd8a41e50'
down_revision: Union[str, None] = '009'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('fcm_token', sa.String(length=512), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'fcm_token')
