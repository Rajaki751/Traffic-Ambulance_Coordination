"""Authentication endpoints: register and login."""

from datetime import datetime, timedelta, timezone

import sqlalchemy.exc
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAnyAuth, get_db
from app.core.config import get_settings
from app.core.ratelimit import rate_limit
from app.core.security import create_access_token, hash_password, verify_password
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole
from app.schemas.auth import TokenResponse, UserLogin, UserRegister, UserResponse

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user. Drivers and officers require extra profile fields."""
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    if payload.role == UserRole.ADMIN:
        raise HTTPException(status_code=400, detail="Admin accounts cannot be self-registered")

    if payload.role == UserRole.DRIVER and not payload.vehicle_number:
        raise HTTPException(status_code=400, detail="vehicle_number required for drivers")
    if payload.role == UserRole.DRIVER:
        existing_ambulance = await db.execute(
            select(Ambulance).where(Ambulance.vehicle_number == payload.vehicle_number)
        )
        if existing_ambulance.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="vehicle_number already registered")
    if payload.role == UserRole.OFFICER and not payload.assigned_zone:
        raise HTTPException(status_code=400, detail="assigned_zone required for officers")

    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=await hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    try:
        await db.flush()
    except sqlalchemy.exc.IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Email or vehicle number already registered")

    if payload.role == UserRole.DRIVER:
        db.add(
            Ambulance(
                driver_id=user.id,
                vehicle_number=payload.vehicle_number,
                status=AmbulanceStatus.AVAILABLE,
            )
        )
    elif payload.role == UserRole.OFFICER:
        db.add(
            TrafficOfficer(
                user_id=user.id,
                assigned_zone=payload.assigned_zone,
                zone_latitude=payload.zone_latitude,
                zone_longitude=payload.zone_longitude,
            )
        )

    await db.refresh(user)
    return UserResponse.model_validate(user)


@router.post("/login", response_model=TokenResponse)
async def login(
    payload: UserLogin,
    db: AsyncSession = Depends(get_db),
    _: None = Depends(
        rate_limit(
            get_settings().login_rate_limit_max,
            get_settings().login_rate_limit_window_seconds,
        )
    ),
):
    """Authenticate and receive JWT access token."""
    raw_email = payload.email or payload.username
    if not raw_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username is required",
        )
    clean_email = raw_email.strip().lower()
    result = await db.execute(
        select(User).where(func.lower(User.email) == clean_email)
    )
    user = result.scalar_one_or_none()

    now = datetime.now(timezone.utc)
    if user and user.locked_until:
        locked_until = (
            user.locked_until
            if user.locked_until.tzinfo is not None
            else user.locked_until.replace(tzinfo=timezone.utc)
        )
        if locked_until > now:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Account temporarily locked due to too many failed attempts. Try again later.",
            )

    if not user or not await verify_password(payload.password, user.password_hash):
        if user:
            settings = get_settings()
            user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
            if user.failed_login_attempts >= settings.max_login_attempts:
                user.failed_login_attempts = 0
                user.locked_until = now + timedelta(
                    minutes=settings.login_lockout_minutes
                )
            await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if user.failed_login_attempts or user.locked_until:
        user.failed_login_attempts = 0
        user.locked_until = None
        await db.commit()

    token = create_access_token(subject=user.id, role=user.role.value)
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        role=user.role,
        name=user.name,
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: RequireAnyAuth):
    """Get current authenticated user profile."""
    return UserResponse.model_validate(current_user)
