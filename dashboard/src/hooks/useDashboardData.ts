import { useState, useCallback, useRef, useEffect } from 'react';
import { analyticsApi, emergencyApi, gpsApi } from '../services/api';
import { useWebSocketContext } from './useWebSocket';
import { AnalyticsSummary, AmbulanceStats, LiveLocation, Emergency } from '../types';

function timestampMs(location: LiveLocation) {
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

export function useDashboardData() {
  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [ambulances, setAmbulances] = useState<AmbulanceStats[]>([]);
  const [liveLocations, setLiveLocations] = useState<LiveLocation[]>([]);
  const [emergencies, setEmergencies] = useState<Emergency[]>([]);
  const [trend, setTrend] = useState<any[]>([]);
  const [error, setError] = useState('');
  
  const pollInFlight = useRef(false);
  const { subscribe } = useWebSocketContext();

  const loadData = useCallback(async () => {
    if (pollInFlight.current) return;
    pollInFlight.current = true;
    try {
      const [sumRes, liveRes, emergRes, ambStatsRes, trendRes] = await Promise.all([
        analyticsApi.summary(),
        gpsApi.liveAll(),
        emergencyApi.active(),
        analyticsApi.ambulances(),
        analyticsApi.trend(),
      ]);
      setSummary(sumRes.data);
      setLiveLocations((prev) => mergeLocations(prev, liveRes.data));
      setEmergencies(emergRes.data);
      setAmbulances(ambStatsRes.data);
      setTrend(trendRes.data);
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

  useEffect(() => {
    return subscribe((msg) => {
      if (msg.type === 'gps_update') {
        setLiveLocations((prev) => upsertLocation(prev, msg.data));
      }
      if (msg.type === 'emergency_activated' || msg.type === 'emergency_ended') {
        loadData();
      }
    });
  }, [subscribe, loadData]);

  const mapCenter: [number, number] =
    liveLocations.length > 0
      ? [liveLocations[0].latitude, liveLocations[0].longitude]
      : [27.7172, 85.3240];

  return {
    summary,
    ambulances,
    liveLocations,
    emergencies,
    trend,
    error,
    mapCenter,
    loadData,
  };
}
