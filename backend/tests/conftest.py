"""Global pytest test configuration and database bootstrap fixtures."""

import os
import pytest
import pytest_asyncio
from sqlalchemy import select

from app.core.security import hash_password
from app.database.migrate import run_dev_migrations
from app.database.session import async_session_maker, engine, init_db
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.officer import TrafficOfficer
from app.models.user import User, UserRole


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_test_database():
    """Ensure database schema, dev migrations, and baseline users exist for tests."""
    await init_db()
    await run_dev_migrations()

    async with async_session_maker() as db:
        pw_hash = await hash_password("Password@123")

        # 1. Ensure Admin (id=1)
        res = await db.execute(select(User).where(User.id == 1))
        admin = res.scalar_one_or_none()
        if not admin:
            admin = User(
                id=1,
                name="System Administrator",
                email="admin@emergency.gov.np",
                password_hash=pw_hash,
                role=UserRole.ADMIN,
            )
            db.add(admin)

        # 2. Ensure Driver (id=2)
        res = await db.execute(select(User).where(User.id == 2))
        driver = res.scalar_one_or_none()
        if not driver:
            driver = User(
                id=2,
                name="Primary Driver",
                email="driver@emergency.gov.np",
                password_hash=pw_hash,
                role=UserRole.DRIVER,
            )
            db.add(driver)
            await db.flush()

            amb = Ambulance(
                driver_id=driver.id,
                vehicle_number="BA-1-JHA-0001",
                status=AmbulanceStatus.AVAILABLE,
            )
            db.add(amb)

        # 3. Ensure Officer (id=3)
        res = await db.execute(select(User).where(User.id == 3))
        officer = res.scalar_one_or_none()
        if not officer:
            officer = User(
                id=3,
                name="Field Officer",
                email="officer@emergency.gov.np",
                password_hash=pw_hash,
                role=UserRole.OFFICER,
            )
            db.add(officer)
            await db.flush()

            off_prof = TrafficOfficer(
                user_id=officer.id,
                assigned_zone="Maitighar",
                zone_latitude=27.6934,
                zone_longitude=85.3206,
                zone_radius_km=1.5,
            )
            db.add(off_prof)

        await db.commit()

    yield
