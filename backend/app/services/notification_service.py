"""Notification creation and delivery service."""

from typing import List, Optional

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import NotificationResponse
from app.services.push_service import PushService

logger = get_logger(__name__)


class NotificationService:
    """Manage officer alerts for emergency events."""

    @staticmethod
    async def create_emergency_alert(
        db: AsyncSession,
        officer_ids: List[int],
        emergency_session_id: int,
        vehicle_number: str,
        destination: str,
    ) -> List[NotificationResponse]:
        """Create notifications for nearby traffic officers."""
        notifications: List[Notification] = []
        title = "Emergency Ambulance Alert"
        message = (
            f"Ambulance {vehicle_number} is en route to {destination}. "
            "Please clear traffic and assist priority passage."
        )

        for officer_id in officer_ids:
            notif = Notification(
                officer_id=officer_id,
                notification_type="emergency_alert",
                emergency_session_id=emergency_session_id,
                title=title,
                message=message,
            )
            db.add(notif)
            notifications.append(notif)

        await db.flush()
        logger.info(
            "Created %d emergency notifications for session %d",
            len(notifications),
            emergency_session_id,
        )

        # Trigger push notifications for all officers with FCM tokens
        if officer_ids:
            officers_result = await db.execute(
                select(User).where(User.id.in_(officer_ids), User.fcm_token.is_not(None))
            )
            for officer in officers_result.scalars():
                if officer.fcm_token:
                    import asyncio
                    asyncio.create_task(
                        PushService.send_push_notification(
                            fcm_token=officer.fcm_token,
                            title=title,
                            body=message,
                            data={"emergency_session_id": str(emergency_session_id), "type": "emergency_alert"},
                        )
                    )

        return [
            NotificationResponse.model_validate(n) for n in notifications
        ]

    @staticmethod
    async def get_officer_notifications(
        db: AsyncSession, officer_id: int, unread_only: bool = False
    ) -> List[Notification]:
        query = select(Notification).where(Notification.officer_id == officer_id)
        if unread_only:
            query = query.where(Notification.is_read == False)  # noqa: E712
        query = query.order_by(Notification.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

    @staticmethod
    async def create_driver_notification(
        db: AsyncSession,
        driver_user_id: int,
        emergency_session_id: int | None,
        title: str,
        message: str,
    ) -> NotificationResponse:
        notif = Notification(
            officer_id=driver_user_id,
            user_id=driver_user_id,
            notification_type="driver_update",
            emergency_session_id=emergency_session_id,
            title=title,
            message=message,
        )
        db.add(notif)
        await db.flush()

        driver_result = await db.execute(
            select(User).where(User.id == driver_user_id)
        )
        driver = driver_result.scalar_one_or_none()
        if driver and driver.fcm_token:
            import asyncio
            asyncio.create_task(
                PushService.send_push_notification(
                    fcm_token=driver.fcm_token,
                    title=title,
                    body=message,
                    data={"emergency_session_id": str(emergency_session_id) if emergency_session_id else "", "type": "driver_update"},
                )
            )

        return NotificationResponse.model_validate(notif)

    @staticmethod
    async def create_driver_reply(
        db: AsyncSession,
        officer_ids: List[int],
        driver_user_id: int,
        emergency_session_id: int | None,
        title: str,
        message: str,
    ) -> List[NotificationResponse]:
        """Create driver reply notifications for all traffic officers."""
        notifications: List[Notification] = []
        for officer_id in officer_ids:
            notif = Notification(
                officer_id=officer_id,
                user_id=driver_user_id,
                notification_type="driver_reply",
                emergency_session_id=emergency_session_id,
                title=title,
                message=message,
            )
            db.add(notif)
            notifications.append(notif)
        await db.flush()

        if officer_ids:
            officers_result = await db.execute(
                select(User).where(User.id.in_(officer_ids), User.fcm_token.is_not(None))
            )
            for officer in officers_result.scalars():
                if officer.fcm_token:
                    import asyncio
                    asyncio.create_task(
                        PushService.send_push_notification(
                            fcm_token=officer.fcm_token,
                            title=title,
                            body=message,
                            data={"emergency_session_id": str(emergency_session_id) if emergency_session_id else "", "type": "driver_reply"},
                        )
                    )

        return [NotificationResponse.model_validate(n) for n in notifications]

    @staticmethod
    async def list_officer_user_ids(db: AsyncSession) -> List[int]:
        """Return user ids of all traffic officers."""
        from app.models.user import User, UserRole

        result = await db.execute(
            select(User.id).where(User.role == UserRole.OFFICER)
        )
        return [row[0] for row in result.all()]

    @staticmethod
    async def get_user_notifications(
        db: AsyncSession, user_id: int, unread_only: bool = False
    ) -> List[Notification]:
        query = select(Notification).where(Notification.user_id == user_id)
        if unread_only:
            query = query.where(Notification.is_read == False)  # noqa: E712
        query = query.order_by(Notification.created_at.desc())
        result = await db.execute(query)
        return list(result.scalars().all())

    @staticmethod
    async def mark_read(db: AsyncSession, notification_id: int, user_id: int) -> bool:
        result = await db.execute(
            select(Notification).where(
                Notification.id == notification_id,
                or_(
                    Notification.user_id == user_id,
                    Notification.officer_id == user_id,
                ),
            )
        )
        notif = result.scalar_one_or_none()
        if not notif:
            return False
        notif.is_read = True
        await db.flush()
        return True

    @staticmethod
    async def acknowledge(
        db: AsyncSession, notification_id: int, user_id: int, action: Optional[str] = None
    ) -> Optional[Notification]:
        result = await db.execute(
            select(Notification).where(
                Notification.id == notification_id,
                or_(
                    Notification.user_id == user_id,
                    Notification.officer_id == user_id,
                ),
            )
        )
        notif = result.scalar_one_or_none()
        if not notif:
            return None
        notif.is_read = True
        notif.is_acknowledged = True
        if action in ("accept", "reject", "ack"):
            notif.acknowledgment = action
        return notif

    @staticmethod
    async def count_unread(db: AsyncSession, officer_id: Optional[int] = None) -> int:
        query = select(Notification).where(Notification.is_read == False)  # noqa: E712
        if officer_id:
            query = query.where(Notification.officer_id == officer_id)
        result = await db.execute(query)
        return len(result.scalars().all())
