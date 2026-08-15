"""FCM Push Notification Service using Firebase Admin SDK (V1 API)."""

import json
from firebase_admin import credentials, initialize_app, messaging
from firebase_admin.exceptions import FirebaseError

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# Initialize Firebase app globally if credentials are provided
settings = get_settings()
_firebase_app = None

if settings.firebase_credentials_json:
    try:
        cred_dict = json.loads(settings.firebase_credentials_json)
        cred = credentials.Certificate(cred_dict)
        _firebase_app = initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully.")
    except Exception as e:
        logger.error("Failed to initialize Firebase Admin SDK: %s", e)
else:
    logger.warning("FIREBASE_CREDENTIALS_JSON not set. Push notifications will be skipped.")


class PushService:
    """Service to send push notifications via Firebase Cloud Messaging V1 API."""

    @staticmethod
    async def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None) -> bool:
        """Send a push notification to a specific FCM token."""
        if not _firebase_app:
            logger.debug("Push Notification skipped (Firebase not initialized): %s - %s", title, body)
            return False

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
            # Platform specific configurations can be added here
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(sound='default'),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound='default', content_available=True)
                ),
            ),
        )

        try:
            # send() is synchronous in firebase_admin, but we run it in async context
            # In a heavy production system, wrap this in asyncio.to_thread
            import asyncio
            response = await asyncio.to_thread(messaging.send, message, app=_firebase_app)
            logger.info("Successfully sent push notification to %s: %s", fcm_token, response)
            return True
        except FirebaseError as e:
            logger.error("Firebase FCM API error: %s", e)
            return False
        except Exception as e:
            logger.exception("Failed to send push notification: %s", e)
            return False
