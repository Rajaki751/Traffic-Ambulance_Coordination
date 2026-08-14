"""Group chat service for emergency sessions."""

from datetime import datetime, timezone
from typing import List, Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.ambulance import Ambulance
from app.models.chat import ChatLastRead, ChatMessage
from app.models.emergency import EmergencySession
from app.models.notification import Notification
from app.models.user import User

logger = get_logger(__name__)


class ChatService:
    """Manage per-emergency group chat between driver and officers."""

    @staticmethod
    async def participants(
        db: AsyncSession, emergency_session_id: int
    ) -> Tuple[List[int], Optional[int]]:
        """Return (officer_user_ids, driver_user_id) for a session."""
        session_result = await db.execute(
            select(EmergencySession).where(
                EmergencySession.id == emergency_session_id
            )
        )
        session = session_result.scalar_one_or_none()
        if not session:
            return [], None

        amb_result = await db.execute(
            select(Ambulance).where(Ambulance.id == session.ambulance_id)
        )
        ambulance = amb_result.scalar_one_or_none()
        driver_id = ambulance.driver_id if ambulance else None

        notif_result = await db.execute(
            select(Notification.officer_id)
            .where(
                Notification.emergency_session_id == emergency_session_id,
                Notification.notification_type == "emergency_alert",
            )
            .distinct()
        )
        officer_ids = [row[0] for row in notif_result.all()]
        return officer_ids, driver_id

    @staticmethod
    async def can_participate(
        db: AsyncSession, emergency_session_id: int, user_id: int, role: str
    ) -> bool:
        officer_ids, driver_id = await ChatService.participants(
            db, emergency_session_id
        )
        if role == "driver":
            return driver_id == user_id
        return user_id in officer_ids

    @staticmethod
    async def list_sessions(
        db: AsyncSession, user_id: int, role: str, limit: int = 30
    ) -> List[dict]:
        """List chat sessions for a user with last message and unread count."""
        if role == "driver":
            session_query = (
                select(
                    EmergencySession.id,
                    EmergencySession.destination,
                    EmergencySession.status,
                    Ambulance.vehicle_number,
                )
                .join(Ambulance, Ambulance.id == EmergencySession.ambulance_id)
                .where(Ambulance.driver_id == user_id)
            )
        else:
            session_query = (
                select(
                    EmergencySession.id,
                    EmergencySession.destination,
                    EmergencySession.status,
                    Ambulance.vehicle_number,
                )
                .join(Ambulance, Ambulance.id == EmergencySession.ambulance_id)
                .join(
                    Notification,
                    Notification.emergency_session_id == EmergencySession.id,
                )
                .where(
                    Notification.officer_id == user_id,
                    Notification.notification_type == "emergency_alert",
                )
                .distinct()
            )

        sessions = (await db.execute(session_query.order_by(EmergencySession.id.desc()).limit(limit))).all()

        results: List[dict] = []
        for session_id, destination, status, vehicle_number in sessions:
            last_result = await db.execute(
                select(ChatMessage)
                .where(ChatMessage.emergency_session_id == session_id)
                .order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc())
                .limit(1)
            )
            last = last_result.scalar_one_or_none()

            read_result = await db.execute(
                select(ChatLastRead.last_read_at).where(
                    ChatLastRead.emergency_session_id == session_id,
                    ChatLastRead.user_id == user_id,
                )
            )
            last_read_at = read_result.scalar_one_or_none()

            unread = 0
            if last is not None:
                count_query = select(func.count(ChatMessage.id)).where(
                    ChatMessage.emergency_session_id == session_id,
                    ChatMessage.sender_user_id != user_id,
                )
                if last_read_at is not None:
                    count_query = count_query.where(
                        ChatMessage.created_at > last_read_at
                    )
                unread = (await db.execute(count_query)).scalar() or 0

            results.append(
                {
                    "emergency_session_id": session_id,
                    "vehicle_number": vehicle_number,
                    "destination": destination,
                    "status": status.value if hasattr(status, "value") else str(status),
                    "last_message": last.message if last else None,
                    "last_message_at": last.created_at if last else None,
                    "unread_count": unread,
                    "participants": await ChatService.participant_details(
                        db, session_id
                    ),
                }
            )
        return results

    @staticmethod
    async def participant_details(
        db: AsyncSession, emergency_session_id: int
    ) -> List[dict]:
        """Return participants (user_id, name, role) for a session."""
        officer_ids, driver_id = await ChatService.participants(
            db, emergency_session_id
        )
        ids = [i for i in officer_ids if i is not None]
        if driver_id is not None:
            ids.append(driver_id)
        if not ids:
            return []
        result = await db.execute(select(User.id, User.name, User.role).where(User.id.in_(ids)))
        rows = result.all()
        return [
            {
                "user_id": uid,
                "name": name or "",
                "role": role.value if hasattr(role, "value") else str(role),
            }
            for uid, name, role in rows
        ]

    @staticmethod
    async def list_messages(
        db: AsyncSession, emergency_session_id: int, user_id: int, role: str, limit: int = 100
    ) -> Optional[List[dict]]:
        if not await ChatService.can_participate(db, emergency_session_id, user_id, role):
            return None
        result = await db.execute(
            select(ChatMessage, User.name, User.role)
            .join(User, User.id == ChatMessage.sender_user_id)
            .where(ChatMessage.emergency_session_id == emergency_session_id)
            .order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc())
            .limit(limit)
        )
        rows = result.all()
        return [
            {
                "id": msg.id,
                "emergency_session_id": msg.emergency_session_id,
                "sender_user_id": msg.sender_user_id,
                "sender_name": sender_name or "",
                "sender_role": role.value if hasattr(role, "value") else str(role),
                "message": msg.message,
                "latitude": msg.latitude,
                "longitude": msg.longitude,
                "created_at": msg.created_at,
            }
            for msg, sender_name, role in reversed(rows)
        ]

    @staticmethod
    async def send_message(
        db: AsyncSession,
        emergency_session_id: int,
        user_id: int,
        role: str,
        message: str,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> Optional[ChatMessage]:
        if not await ChatService.can_participate(db, emergency_session_id, user_id, role):
            return None
        msg = ChatMessage(
            emergency_session_id=emergency_session_id,
            sender_user_id=user_id,
            message=message,
            latitude=latitude,
            longitude=longitude,
        )
        db.add(msg)
        await db.flush()
        await db.refresh(msg)
        return msg

    @staticmethod
    async def mark_read(
        db: AsyncSession, emergency_session_id: int, user_id: int, role: str
    ) -> bool:
        if not await ChatService.can_participate(db, emergency_session_id, user_id, role):
            return False
        row = await db.execute(
            select(ChatLastRead).where(
                ChatLastRead.emergency_session_id == emergency_session_id,
                ChatLastRead.user_id == user_id,
            )
        )
        entry = row.scalar_one_or_none()
        if entry:
            entry.last_read_at = datetime.now(timezone.utc)
        else:
            db.add(
                ChatLastRead(
                    emergency_session_id=emergency_session_id,
                    user_id=user_id,
                    last_read_at=datetime.now(timezone.utc),
                )
            )
        return True

    @staticmethod
    async def total_unread(db: AsyncSession, user_id: int, role: str) -> int:
        sessions = await ChatService.list_sessions(db, user_id, role)
        return sum(s["unread_count"] for s in sessions)
