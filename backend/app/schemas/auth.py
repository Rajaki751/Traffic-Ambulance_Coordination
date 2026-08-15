"""Authentication schemas."""

from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRole


class UserRegister(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    role: UserRole
    vehicle_number: str | None = Field(None, description="Required for drivers")
    assigned_zone: str | None = Field(None, description="Required for officers")
    zone_latitude: float | None = None
    zone_longitude: float | None = None


class UserLogin(BaseModel):
    email: str = Field(..., min_length=1, max_length=255)
    password: str = Field(..., min_length=1, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    role: UserRole
    name: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: UserRole
    vehicle_number: str | None = None
    assigned_zone: str | None = None

    model_config = {"from_attributes": True}
