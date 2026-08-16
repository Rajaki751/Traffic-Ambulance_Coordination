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
        # Find driver
        driver = (await session.execute(select(User).where(User.email == "driver@sajiloroute.com"))).scalar_one_or_none()
        if driver:
            amb = Ambulance(driver_id=driver.id, vehicle_number="BA 1 J 1234", status=AmbulanceStatus.AVAILABLE)
            session.add(amb)
            print("Added Ambulance for Driver")
            
        # Find officer
        officer = (await session.execute(select(User).where(User.email == "officer@sajiloroute.com"))).scalar_one_or_none()
        if officer:
            off = TrafficOfficer(user_id=officer.id, assigned_zone="Koteshwor", zone_latitude=27.6756, zone_longitude=85.3459)
            session.add(off)
            print("Added Traffic Officer profile")
            
        try:
            await session.commit()
            print("Successfully seeded profiles!")
        except Exception as e:
            print(f"Failed (might already exist): {e}")

if __name__ == "__main__":
    asyncio.run(seed_profiles())
