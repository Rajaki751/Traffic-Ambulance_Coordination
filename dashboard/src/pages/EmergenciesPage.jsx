import { useCallback, useEffect, useState } from 'react';
import { IconAlarm, IconClock, IconMapPin } from '@tabler/icons-react';
import ErrorBanner from '../components/ErrorBanner';
import { emergencyApi } from '../services/api';

function formatDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString();
}

export default function EmergenciesPage() {
  const [emergencies, setEmergencies] = useState([]);
  const [error, setError] = useState('');

  const loadEmergencies = useCallback(() => {
    setError('');
    emergencyApi.active()
      .then((r) => setEmergencies(r.data))
      .catch(() => setError('Failed to load active emergency sessions'));
  }, []);

  useEffect(() => {
    loadEmergencies();
  }, [loadEmergencies]);

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Active Emergency Sessions</h1>
        {!error && emergencies.length > 0 && (
          <span className="flex items-center gap-1.5 rounded-full bg-emergency/10 px-3 py-1.5 text-sm font-medium text-emergency">
            <IconAlarm className="h-4 w-4" stroke={1.7} />
            {emergencies.length} active
          </span>
        )}
      </div>
      {error && <ErrorBanner message={error} onRetry={loadEmergencies} />}
      <div className="overflow-hidden rounded-xl border dark:border-gray-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-100 dark:bg-gray-800">
            <tr className="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">
              <th className="p-4 font-medium">ID</th>
              <th className="p-4 font-medium">Ambulance</th>
              <th className="p-4 font-medium">Destination</th>
              <th className="p-4 font-medium">ETA</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Started</th>
            </tr>
          </thead>
          <tbody>
            {emergencies.map((e) => (
              <tr
                key={e.id}
                className="border-t transition-colors hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800/60"
              >
                <td className="p-4 font-mono text-xs">{`#${e.id}`}</td>
                <td className="p-4">{e.ambulance_id}</td>
                <td className="p-4">
                  <span className="flex items-center gap-1.5">
                    <IconMapPin className="h-4 w-4 shrink-0 text-gray-400" stroke={1.7} />
                    {e.destination}
                  </span>
                </td>
                <td className="p-4">
                  <span className="flex items-center gap-1.5 tabular-nums">
                    <IconClock className="h-4 w-4 text-gray-400" stroke={1.7} />
                    {e.eta_minutes?.toFixed(0) ?? '-'} min
                  </span>
                </td>
                <td className="p-4">
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-red-100 px-2.5 py-1 text-xs font-medium text-red-700 dark:bg-red-900/30 dark:text-red-300">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emergency" />
                    {e.status}
                  </span>
                </td>
                <td className="p-4 text-gray-500 dark:text-gray-400">
                  {formatDate(e.started_at)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!error && emergencies.length === 0 && (
          <div className="p-10 text-center">
            <IconAlarm className="mx-auto h-8 w-8 text-gray-300 dark:text-gray-600" stroke={1.5} />
            <p className="mt-3 text-sm text-gray-500">No active emergencies right now</p>
          </div>
        )}
      </div>
    </div>
  );
}
