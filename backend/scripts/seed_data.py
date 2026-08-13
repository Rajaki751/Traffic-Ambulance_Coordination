"""
Seed sample data for development and testing.

Usage:
    cd backend
    python -m scripts.seed_data
"""

import asyncio

from sqlalchemy import select

from app.core.security import get_password_hash
from app.database.session import async_session_maker, init_db
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole


async def seed() -> None:
    await init_db()
    async with async_session_maker() as db:
        existing = await db.execute(select(User).where(User.email == "admin@ambulance.gov"))
        if existing.scalar_one_or_none():
            print("Seed data already exists. Skipping.")
            return

        admin = User(
            name="System Admin",
            email="admin@ambulance.gov",
            password_hash=get_password_hash("Admin@12345"),
            role=UserRole.ADMIN,
        )
        driver = User(
            name="John Driver",
            email="driver@ambulance.gov",
            password_hash=get_password_hash("Driver@12345"),
            role=UserRole.DRIVER,
        )
        officer = User(
            name="Sarah Officer",
            email="officer@ambulance.gov",
            password_hash=get_password_hash("Officer@12345"),
            role=UserRole.OFFICER,
        )
        db.add_all([admin, driver, officer])
        await db.flush()

        db.add(
            Ambulance(
                driver_id=driver.id,
                vehicle_number="AMB-001",
                status=AmbulanceStatus.AVAILABLE,
            )
        )
        db.add(
            TrafficOfficer(
                user_id=officer.id,
                assigned_zone="Downtown Central",
                zone_latitude=27.7172,
                zone_longitude=85.3240,
                zone_radius_km=8.0,
            )
        )
        await db.commit()
        print("Seed data created successfully!")
        print("  Admin:   admin@ambulance.gov / Admin@12345")
        print("  Driver:  driver@ambulance.gov / Driver@12345")
        print("  Officer: officer@ambulance.gov / Officer@12345")


if __name__ == "__main__":
    asyncio.run(seed())
