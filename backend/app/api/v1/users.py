"""User management (admin only)."""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import RequireAdmin, get_db
from app.core.security import hash_password
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole
from app.schemas.auth import UserResponse

router = APIRouter()


class UserUpdateRequest(BaseModel):
    name: str | None = Field(None, min_length=2, max_length=255)
    email: EmailStr | None = None
    role: UserRole | None = None
    password: str | None = Field(None, min_length=8, max_length=128)
    vehicle_number: str | None = Field(None, max_length=50)
    assigned_zone: str | None = Field(None, max_length=255)


class UserCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    role: UserRole


@router.get("/", response_model=List[UserResponse])
async def list_users(
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
):
    """List all system users (admin only)."""
    result = await db.execute(select(User).offset(skip).limit(limit))
    return [UserResponse.model_validate(u) for u in result.scalars().all()]


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)


@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    payload: UserCreateRequest,
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """Create a new user (admin only)."""
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=await hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return UserResponse.model_validate(user)


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    payload: UserUpdateRequest,
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """Update a user (admin only)."""
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
        raise HTTPException(status_code=404, detail="User not found")

    if payload.name is not None:
        user.name = payload.name
    if payload.email is not None:
        existing = await db.execute(
            select(User).where(User.email == payload.email, User.id != user_id)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = payload.email

    if payload.role is not None and payload.role != user.role:
        if payload.role == UserRole.DRIVER:
            if not payload.vehicle_number:
                raise HTTPException(
                    status_code=400, detail="vehicle_number required to assign driver role"
                )
            if user.officer_profile:
                await db.delete(user.officer_profile)
            if not user.ambulance:
                db.add(
                    Ambulance(
                        driver_id=user.id,
                        vehicle_number=payload.vehicle_number,
                        status=AmbulanceStatus.AVAILABLE,
                    )
                )
        elif payload.role == UserRole.OFFICER:
            if not payload.assigned_zone:
                raise HTTPException(
                    status_code=400, detail="assigned_zone required to assign officer role"
                )
            if user.ambulance:
                await db.delete(user.ambulance)
            if not user.officer_profile:
                db.add(
                    TrafficOfficer(
                        user_id=user.id,
                        assigned_zone=payload.assigned_zone,
                    )
                )
        elif payload.role == UserRole.ADMIN:
            if user.ambulance:
                await db.delete(user.ambulance)
            if user.officer_profile:
                await db.delete(user.officer_profile)
        user.role = payload.role

    if payload.password is not None:
        user.password_hash = await hash_password(payload.password)

    await db.flush()
    await db.refresh(user)
    return UserResponse.model_validate(user)


@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: int,
    current_user: RequireAdmin,
    db: AsyncSession = Depends(get_db),
):
    """Delete a user (admin only)."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    await db.delete(user)
    await db.flush()
