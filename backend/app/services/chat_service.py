"""Group chat service for emergency sessions."""

from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple

from sqlalchemy import func, or_, select
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
                    EmergencySession.ambulance_id,
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
                    EmergencySession.ambulance_id,
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

        sessions = (
            await db.execute(
                session_query.order_by(EmergencySession.id.desc()).limit(limit)
            )
        ).all()
        session_ids = [s[0] for s in sessions]
        if not session_ids:
            return []

        # Batch 1: last message per session (MAX(id) join — ids are monotonic).
        max_id_subq = (
            select(
                ChatMessage.emergency_session_id,
                func.max(ChatMessage.id).label("max_id"),
            )
            .where(ChatMessage.emergency_session_id.in_(session_ids))
            .group_by(ChatMessage.emergency_session_id)
            .subquery()
        )
        last_result = await db.execute(
            select(ChatMessage).join(
                max_id_subq, ChatMessage.id == max_id_subq.c.max_id
            )
        )
        last_by_session = {
            m.emergency_session_id: m for m in last_result.scalars().all()
        }

        # Batch 2: unread counts (LEFT JOIN the per-user read marker).
        unread_result = await db.execute(
            select(ChatMessage.emergency_session_id, func.count(ChatMessage.id))
            .outerjoin(
                ChatLastRead,
                (ChatLastRead.emergency_session_id == ChatMessage.emergency_session_id)
                & (ChatLastRead.user_id == user_id),
            )
            .where(
                ChatMessage.emergency_session_id.in_(session_ids),
                ChatMessage.sender_user_id != user_id,
                or_(
                    ChatLastRead.last_read_at.is_(None),
                    ChatMessage.created_at > ChatLastRead.last_read_at,
                ),
            )
            .group_by(ChatMessage.emergency_session_id)
        )
        unread_by_session = dict(unread_result.all())

        # Batch 3: participants — drivers by ambulance + alerted officers.
        ambulance_ids = [s[4] for s in sessions]
        driver_result = await db.execute(
            select(Ambulance.id, Ambulance.driver_id).where(
                Ambulance.id.in_(ambulance_ids)
            )
        )
        driver_by_ambulance = dict(driver_result.all())

        notif_result = await db.execute(
            select(
                Notification.emergency_session_id,
                Notification.officer_id,
            )
            .where(
                Notification.emergency_session_id.in_(session_ids),
                Notification.notification_type == "emergency_alert",
            )
            .distinct()
        )
        officer_ids_by_session: Dict[int, set] = {}
        for sid, officer_id in notif_result.all():
            if officer_id is not None:
                officer_ids_by_session.setdefault(sid, set()).add(officer_id)

        participant_ids: set = set()
        for sid, driver_ambulance_id in ((s[0], s[4]) for s in sessions):
            driver_id = driver_by_ambulance.get(driver_ambulance_id)
            if driver_id is not None:
                participant_ids.add(driver_id)
            participant_ids.update(officer_ids_by_session.get(sid, set()))

        user_by_id: Dict[int, User] = {}
        if participant_ids:
            user_result = await db.execute(
                select(User).where(User.id.in_(participant_ids))
            )
            user_by_id = {u.id: u for u in user_result.scalars().all()}

        results: List[dict] = []
        for session_id, destination, status, vehicle_number, ambulance_id in sessions:
            driver_id = driver_by_ambulance.get(ambulance_id)
            participants = []
            for uid in sorted(user_by_id):
                if uid in officer_ids_by_session.get(session_id, set()) or (
                    driver_id is not None and uid == driver_id
                ):
                    u = user_by_id[uid]
                    participants.append(
                        {
                            "user_id": uid,
                            "name": u.name or "",
                            "role": (
                                u.role.value
                                if hasattr(u.role, "value")
                                else str(u.role)
                            ),
                        }
                    )
            last = last_by_session.get(session_id)
            results.append(
                {
                    "emergency_session_id": session_id,
                    "vehicle_number": vehicle_number,
                    "destination": destination,
                    "status": status.value if hasattr(status, "value") else str(status),
                    "last_message": last.message if last else None,
                    "last_message_at": last.created_at if last else None,
                    "unread_count": unread_by_session.get(session_id, 0),
                    "participants": participants,
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
