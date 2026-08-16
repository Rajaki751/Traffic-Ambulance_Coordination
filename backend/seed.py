import asyncio
import os
import sys

# Ensure backend directory is in python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.security import hash_password
from app.database.session import async_session_maker
from app.models.user import User, UserRole

async def seed_users():
    async with async_session_maker() as session:
        users = [
            User(
                name="Admin User",
                email="admin@sajiloroute.com",
                password_hash=await hash_password("admin123"),
                role=UserRole.ADMIN
            ),
            User(
                name="Driver John",
                email="driver@sajiloroute.com",
                password_hash=await hash_password("driver123"),
                role=UserRole.DRIVER
            ),
            User(
                name="Officer Sarah",
                email="officer@sajiloroute.com",
                password_hash=await hash_password("officer123"),
                role=UserRole.OFFICER
            )
        ]
        for u in users:
            try:
                session.add(u)
                await session.commit()
            except Exception as e:
                await session.rollback()
                print(f"Skipped adding {u.name} (maybe exists?): {e}")
        
        print("Finished seeding users in the Neon Database!")

if __name__ == "__main__":
    asyncio.run(seed_users())
