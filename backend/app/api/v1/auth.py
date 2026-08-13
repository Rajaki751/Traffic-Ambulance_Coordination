"""Authentication endpoints: register and login."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import RequireAnyAuth, get_db
from app.core.security import create_access_token, get_password_hash, verify_password
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

    if payload.role == UserRole.DRIVER and not payload.vehicle_number:
        raise HTTPException(status_code=400, detail="vehicle_number required for drivers")
    if payload.role == UserRole.OFFICER and not payload.assigned_zone:
        raise HTTPException(status_code=400, detail="assigned_zone required for officers")

    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=get_password_hash(payload.password),
        role=payload.role,
    )
    db.add(user)
    await db.flush()

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
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    """Authenticate and receive JWT access token."""
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

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
