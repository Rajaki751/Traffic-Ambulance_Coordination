import { useCallback, useEffect, useRef, useState } from 'react';
import {
  IconAlarm,
  IconAmbulance,
  IconCircleCheck,
  IconClock,
  IconMapPin,
  IconMapPin2,
  IconShieldCheck,
} from '@tabler/icons-react';
import LiveMap from '../components/LiveMap';
import StatCard from '../components/StatCard';
import Card from '../components/Card';
import PageHeader from '../components/PageHeader';
import StatusPill from '../components/StatusPill';
import ErrorBanner from '../components/ErrorBanner';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { analyticsApi, emergencyApi, gpsApi } from '../services/api';
import { useWebSocketContext } from '../hooks/useWebSocket';
import {
  AnalyticsSummary,
  AmbulanceStats,
  LiveLocation,
  Emergency,
} from '../types';

function timestampMs(location) {
  return location?.updated_at ? new Date(location.updated_at).getTime() : 0;
}

function upsertLocation(prev: LiveLocation[], next: LiveLocation): LiveLocation[] {
  const idx = prev.findIndex((a) => a.ambulance_id === next.ambulance_id);
  if (idx >= 0) {
    if (timestampMs(next) < timestampMs(prev[idx])) return prev;
    const merged = [...prev];
    merged[idx] = next;
    return merged;
  }
  return [...prev, next];
}

function mergeLocations(prev: LiveLocation[], incoming: LiveLocation[]): LiveLocation[] {
  const merged = incoming.reduce((acc, next) => upsertLocation(acc, next), prev);
  const cutoff = Date.now() - 5 * 60 * 1000; // 5 minutes
  return merged.filter((loc) => timestampMs(loc) > cutoff);
}

function formatTime(value: string | Date | null | undefined): string {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

export default function DashboardPage() {
  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [ambulances, setAmbulances] = useState<AmbulanceStats[]>([]);
  const [liveLocations, setLiveLocations] = useState<LiveLocation[]>([]);

  const [emergencies, setEmergencies] = useState<Emergency[]>([]);
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

  const mapCenter: [number, number] =
    liveLocations.length > 0
      ? [liveLocations[0].latitude, liveLocations[0].longitude]
      : [27.7172, 85.3240];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Real-Time Dashboard"
        subtitle="Live status of the fleet, active emergencies and response performance"
      />
      {error && <ErrorBanner message={error} onRetry={loadData} />}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Emergencies"
          value={summary?.active_emergencies ?? 0}
          icon={IconAlarm}
          color="red"
        />
        <StatCard
          title="Ambulances"
          value={summary?.total_ambulances ?? 0}
          icon={IconAmbulance}
          color="blue"
        />
        <StatCard
          title="Traffic Officers"
          value={summary?.total_officers ?? 0}
          icon={IconShieldCheck}
          color="orange"
        />
        <StatCard
          title="Completed Today"
          value={summary?.completed_emergencies_today ?? 0}
          icon={IconCircleCheck}
          color="green"
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card
          className="lg:col-span-2"
          title="Live Map"
          subtitle="Ambulance positions updated in real time"
          icon={IconMapPin}
          bodyClassName="p-3"
          action={
            <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
              <span className="flex items-center gap-1.5">
                <IconAmbulance className="h-4 w-4 text-emergency" stroke={1.7} />
                Ambulance
              </span>
              <span className="flex items-center gap-1.5">
                <IconMapPin2 className="h-4 w-4 text-green-600" stroke={1.7} />
                Destination
              </span>
            </div>
          }
        >
          <div className="h-[440px] overflow-hidden rounded-xl">
            <LiveMap ambulances={liveLocations} center={mapCenter} />
          </div>
        </Card>

        <div className="space-y-6">
          <Card
            title="Active Sessions"
            subtitle={`${emergencies.length} running right now`}
            icon={IconAlarm}
            bodyClassName="space-y-3 p-4"
          >
            {emergencies.length === 0 ? (
              <div className="rounded-xl border border-dashed p-8 text-center dark:border-gray-700">
                <IconAlarm
                  className="mx-auto h-7 w-7 text-gray-300 dark:text-gray-600"
                  stroke={1.5}
                />
                <p className="mt-3 text-sm text-gray-500 dark:text-gray-400">
                  No active emergencies
                </p>
              </div>
            ) : (
              emergencies.map((e) => (
                <div
                  key={e.id}
                  className="rounded-xl border border-red-100 bg-red-50/60 p-3.5 transition-shadow hover:shadow-sm dark:border-red-900/40 dark:bg-red-900/15"
                >
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-semibold tracking-tight">
                      Session <span className="font-mono">#{e.id}</span>
                    </p>
                    <StatusPill tone="red" label="Active" pulse />
                  </div>
                  <p className="mt-2 flex items-center gap-1.5 truncate text-sm text-gray-700 dark:text-gray-300">
                    <IconMapPin className="h-4 w-4 shrink-0 text-emergency/70" stroke={1.7} />
                    <span className="truncate">{e.destination}</span>
                  </p>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
                    <IconClock className="h-3.5 w-3.5" stroke={1.7} />
                    ETA {e.eta_minutes?.toFixed(0) ?? '?'} min
                    <span className="text-gray-300 dark:text-gray-600">·</span>
                    since {formatTime(e.started_at)}
                  </p>
                </div>
              ))
            )}
          </Card>

          <Card
            title="Response Time Trend"
            subtitle="Historical 7-day average (mocked)"
            icon={IconClock}
            bodyClassName="p-5"
          >
            <div className="mb-4 flex items-baseline gap-2">
              <p className="text-4xl font-bold tabular-nums tracking-tight text-emergency">
                {summary?.avg_response_time_minutes ?? 0}
              </p>
              <span className="text-base font-medium text-gray-500 dark:text-gray-400">
                min (Current)
              </span>
            </div>
            
            <div className="h-[140px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart
                  data={[
                    { name: 'Mon', time: 14.2 },
                    { name: 'Tue', time: 12.8 },
                    { name: 'Wed', time: 15.1 },
                    { name: 'Thu', time: 11.5 },
                    { name: 'Fri', time: 10.9 },
                    { name: 'Sat', time: 9.2 },
                    { name: 'Sun', time: 8.5 },
                  ]}
                  margin={{ top: 5, right: 0, left: -25, bottom: 0 }}
                >
                  <defs>
                    <linearGradient id="colorTime" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#E53935" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#E53935" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} strokeOpacity={0.2} />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#888' }} />
                  <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#888' }} />
                  <Tooltip 
                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  />
                  <Area
                    type="monotone"
                    dataKey="time"
                    stroke="#E53935"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#colorTime)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </Card>

          <Card
            title="Fleet Activity"
            subtitle="Emergency count per ambulance"
            icon={IconAmbulance}
            bodyClassName="p-4"
          >
            {ambulances.length === 0 ? (
              <p className="text-sm text-gray-500">No ambulance data</p>
            ) : (
              <div className="space-y-2.5">
                {ambulances.map((a) => (
                  <div
                    key={a.ambulance_id}
                    className="flex items-center justify-between gap-3 text-sm"
                  >
                    <span className="flex min-w-0 items-center gap-2 font-medium">
                      <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-gray-50 dark:bg-gray-700/60">
                        <IconAmbulance
                          className={`h-4 w-4 ${a.active_session_id ? 'text-emergency' : 'text-gray-400 dark:text-gray-500'}`}
                          stroke={1.7}
                        />
                      </span>
                      <span className="truncate font-mono text-xs">{a.vehicle_number}</span>
                    </span>
                    <span className="shrink-0 text-xs tabular-nums text-gray-500 dark:text-gray-400">
                      {a.total_emergencies} emergencies
                      {a.active_session_id && (
                        <span className="ml-1.5 inline-flex items-center gap-1 text-emergency">
                          <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emergency" />
                          active
                        </span>
                      )}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}