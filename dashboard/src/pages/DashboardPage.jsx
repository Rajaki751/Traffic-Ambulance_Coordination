import { useCallback, useEffect, useRef, useState } from 'react';
import LiveMap from '../components/LiveMap';
import StatCard from '../components/StatCard';
import ErrorBanner from '../components/ErrorBanner';
import { analyticsApi, emergencyApi, gpsApi } from '../services/api';
import { useWebSocketContext } from '../hooks/useWebSocket';

function timestampMs(location) {
  return location?.updated_at ? new Date(location.updated_at).getTime() : 0;
}

function upsertLocation(prev, next) {
  const idx = prev.findIndex((a) => a.ambulance_id === next.ambulance_id);
  if (idx >= 0) {
    if (timestampMs(next) < timestampMs(prev[idx])) return prev;
    const merged = [...prev];
    merged[idx] = next;
    return merged;
  }
  return [...prev, next];
}

function mergeLocations(prev, incoming) {
  return incoming.reduce((acc, next) => upsertLocation(acc, next), prev);
}

export default function DashboardPage() {
  const [summary, setSummary] = useState(null);
  const [ambulances, setAmbulances] = useState([]);
  const [liveLocations, setLiveLocations] = useState([]);
  const [emergencies, setEmergencies] = useState([]);
  const [error, setError] = useState('');
  const pollInFlight = useRef(false);
  const { subscribe } = useWebSocketContext();

  const loadData = useCallback(async () => {
    if (pollInFlight.current) return;
    pollInFlight.current = true;
    try {
      const [sumRes, liveRes, emergRes, ambStatsRes] = await Promise.all([
        analyticsApi.summary(),
        gpsApi.liveAll(),
        emergencyApi.active(),
        analyticsApi.ambulances(),
      ]);
      setSummary(sumRes.data);
      setLiveLocations((prev) => mergeLocations(prev, liveRes.data));
      setEmergencies(emergRes.data);
      setAmbulances(ambStatsRes.data);
      setError('');
    } catch (e) {
      console.error(e);
      setError('Failed to load dashboard data');
    } finally {
      pollInFlight.current = false;
    }
  }, []);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 15000);
    return () => clearInterval(interval);
  }, [loadData]);

  useEffect(
    () =>
      subscribe((msg) => {
        if (msg.type === 'gps_update') {
          setLiveLocations((prev) => upsertLocation(prev, msg.data));
        }
        if (msg.type === 'emergency_activated' || msg.type === 'emergency_ended') {
          loadData();
        }
      }),
    [subscribe, loadData]
  );

  const mapCenter =
    liveLocations.length > 0
      ? [liveLocations[0].latitude, liveLocations[0].longitude]
      : [27.7172, 85.3240];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Real-Time Dashboard</h1>
      {error && <ErrorBanner message={error} onRetry={loadData} />}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Emergencies"
          value={summary?.active_emergencies ?? 0}
          icon="🚨"
          color="red"
        />
        <StatCard
          title="Ambulances"
          value={summary?.total_ambulances ?? 0}
          icon="🚑"
          color="blue"
        />
        <StatCard
          title="Traffic Officers"
          value={summary?.total_officers ?? 0}
          icon="👮"
          color="orange"
        />
        <StatCard
          title="Completed Today"
          value={summary?.completed_emergencies_today ?? 0}
          icon="✅"
          color="green"
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <h2 className="mb-3 text-lg font-semibold">Live Ambulance Map</h2>
          <LiveMap ambulances={liveLocations} center={mapCenter} />
        </div>
        <div>
          <h2 className="mb-3 text-lg font-semibold">Active Sessions</h2>
          <div className="space-y-3">
            {emergencies.length === 0 ? (
              <p className="text-gray-500">No active emergencies</p>
            ) : (
              emergencies.map((e) => (
                <div
                  key={e.id}
                  className="rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20"
                >
                  <p className="font-semibold text-emergency">Session #{e.id}</p>
                  <p className="text-sm">{e.destination}</p>
                  <p className="text-xs text-gray-500">
                    ETA: {e.eta_minutes?.toFixed(0) ?? '?'} min
                  </p>
                </div>
              ))
            )}
          </div>
          <div className="mt-6 rounded-lg border p-4 dark:border-gray-700">
            <p className="text-sm text-gray-500">Avg Response Time</p>
            <p className="text-2xl font-bold">
              {summary?.avg_response_time_minutes ?? 0} min
            </p>
          </div>
          <div className="mt-6 rounded-lg border p-4 dark:border-gray-700">
            <p className="mb-3 text-sm font-medium text-gray-500">Ambulance Stats</p>
            {ambulances.length === 0 ? (
              <p className="text-sm text-gray-500">No ambulance data</p>
            ) : (
              <div className="space-y-2">
                {ambulances.map((a) => (
                  <div
                    key={a.ambulance_id}
                    className="flex items-center justify-between text-sm"
                  >
                    <span className="font-medium">{a.vehicle_number}</span>
                    <span className="text-gray-500">
                      {a.total_emergencies} emergencies
                      {a.active_session_id ? ' · active' : ''}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}