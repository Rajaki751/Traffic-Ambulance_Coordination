import { useCallback, useEffect, useState } from 'react';
import LiveMap from '../components/LiveMap';
import StatCard from '../components/StatCard';
import { analyticsApi, emergencyApi, gpsApi } from '../services/api';
import { useAdminWebSocket } from '../hooks/useWebSocket';

export default function DashboardPage() {
  const [summary, setSummary] = useState(null);
  const [ambulances, setAmbulances] = useState([]);
  const [liveLocations, setLiveLocations] = useState([]);
  const [emergencies, setEmergencies] = useState([]);

  const loadData = useCallback(async () => {
    try {
      const [sumRes, liveRes, emergRes] = await Promise.all([
        analyticsApi.summary(),
        gpsApi.liveAll(),
        emergencyApi.active(),
      ]);
      setSummary(sumRes.data);
      setLiveLocations(liveRes.data);
      setEmergencies(emergRes.data);
    } catch (e) {
      console.error(e);
    }
  }, []);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 15000);
    return () => clearInterval(interval);
  }, [loadData]);

  useAdminWebSocket(
    useCallback(
      (msg) => {
        if (msg.type === 'gps_update') {
          setLiveLocations((prev) => {
            const updated = [...prev];
            const idx = updated.findIndex(
              (a) => a.ambulance_id === msg.data.ambulance_id
            );
            if (idx >= 0) updated[idx] = msg.data;
            else updated.push(msg.data);
            return updated;
          });
        }
        if (msg.type === 'emergency_activated' || msg.type === 'emergency_ended') {
          loadData();
        }
      },
      [loadData]
    )
  );

  useEffect(() => {
    analyticsApi.ambulances().then((r) => setAmbulances(r.data)).catch(() => {});
  }, []);

  const mapCenter =
    liveLocations.length > 0
      ? [liveLocations[0].latitude, liveLocations[0].longitude]
      : [27.7172, 85.3240];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Real-Time Dashboard</h1>

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
        </div>
      </div>
    </div>
  );
}
