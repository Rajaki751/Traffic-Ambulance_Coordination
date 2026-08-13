"""Analytics dashboard schemas."""

from pydantic import BaseModel


class AnalyticsSummary(BaseModel):
    total_users: int
    total_ambulances: int
    active_emergencies: int
    completed_emergencies_today: int
    total_officers: int
    unread_notifications: int
    avg_response_time_minutes: float


class AmbulanceStats(BaseModel):
    ambulance_id: int
    vehicle_number: str
    status: str
    total_emergencies: int
    active_session_id: int | None
