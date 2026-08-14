export interface AnalyticsSummary {
  total_users: number;
  total_ambulances: number;
  active_emergencies: number;
  completed_emergencies_today: number;
  total_officers: number;
  unread_notifications: number;
  avg_response_time_minutes: number;
}

export interface AmbulanceStats {
  ambulance_id: number;
  vehicle_number: string;
  status: string;
  total_emergencies: number;
  active_session_id: number | null;
}

export interface LiveLocation {
  ambulance_id: number;
  vehicle_number?: string;
  latitude: number;
  longitude: number;
  heading?: number;
  speed?: number;
  updated_at: string;
}

export interface Emergency {
  id: number;
  ambulance_id: number;
  destination: string;
  eta_minutes: number | null;
  started_at: string;
  status: string;
}
