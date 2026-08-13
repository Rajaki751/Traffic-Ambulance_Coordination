"""FastAPI dependencies for auth and database."""

from typing import Annotated, Callable, List

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import decode_access_token
from app.database.session import get_db
from app.models.user import User, UserRole

security_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(security_scheme)
    ],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Resolve authenticated user from JWT bearer token."""
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_access_token(credentials.credentials)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    return await _get_user_from_payload(db, payload)


async def _get_user_from_payload(
    db: AsyncSession, payload: dict
) -> User:
    """Resolve a User from a validated token payload."""
    try:
        user_id = int(payload["sub"])
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(
            selectinload(User.ambulance),
            selectinload(User.officer_profile),
        )
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user


def require_roles(*roles: UserRole) -> Callable:
    """Factory for role-based authorization dependency."""

    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {[r.value for r in roles]}",
            )
        return current_user

    return role_checker


# Typed role dependencies
RequireAdmin = Annotated[User, Depends(require_roles(UserRole.ADMIN))]
RequireDriver = Annotated[User, Depends(require_roles(UserRole.DRIVER))]
RequireOfficer = Annotated[User, Depends(require_roles(UserRole.OFFICER))]
RequireDriverOrOfficer = Annotated[
    User, Depends(require_roles(UserRole.DRIVER, UserRole.OFFICER))
]
RequireAnyAuth = Annotated[User, Depends(get_current_user)]
