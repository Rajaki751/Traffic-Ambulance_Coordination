import asyncio
import os
import sys

# Ensure backend directory is in python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database.session import async_session_maker
from app.models.user import User
from app.models.ambulance import Ambulance, AmbulanceStatus
from app.models.officer import TrafficOfficer
from sqlalchemy import select

async def seed_profiles():
    async with async_session_maker() as session:
        # Driver 1
        driver1 = (await session.execute(select(User).where(User.email == "driver@sajiloroute.com"))).scalar_one_or_none()
        if driver1:
            existing = (await session.execute(select(Ambulance).where(Ambulance.driver_id == driver1.id))).scalar_one_or_none()
            if not existing:
                amb1 = Ambulance(driver_id=driver1.id, vehicle_number="BA 1 J 1234", status=AmbulanceStatus.AVAILABLE)
                session.add(amb1)
                await session.commit()
                print("Added Ambulance for Driver 1 (driver@sajiloroute.com)")

        # Driver 2
        driver2 = (await session.execute(select(User).where(User.email == "driver2@sajiloroute.com"))).scalar_one_or_none()
        if driver2:
            existing = (await session.execute(select(Ambulance).where(Ambulance.driver_id == driver2.id))).scalar_one_or_none()
            if not existing:
                amb2 = Ambulance(driver_id=driver2.id, vehicle_number="BA 2 J 5678", status=AmbulanceStatus.AVAILABLE)
                session.add(amb2)
                await session.commit()
                print("Added Ambulance for Driver 2 (driver2@sajiloroute.com)")
            
        # Officer
        officer = (await session.execute(select(User).where(User.email == "officer@sajiloroute.com"))).scalar_one_or_none()
        if officer:
            existing = (await session.execute(select(TrafficOfficer).where(TrafficOfficer.user_id == officer.id))).scalar_one_or_none()
            if not existing:
                off = TrafficOfficer(user_id=officer.id, assigned_zone="Koteshwor", zone_latitude=27.6756, zone_longitude=85.3459)
                session.add(off)
                await session.commit()
                print("Added Traffic Officer profile")
            
        print("Successfully seeded all profiles!")

if __name__ == "__main__":
    asyncio.run(seed_profiles())
