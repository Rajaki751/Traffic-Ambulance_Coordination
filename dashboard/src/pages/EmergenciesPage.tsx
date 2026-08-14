import { useCallback, useEffect, useState } from 'react';
import {
  IconAlarm,
  IconAmbulance,
  IconCalendarEvent,
  IconClock,
  IconMapPin,
  IconDownload,
} from '@tabler/icons-react';
import Card from '../components/Card';
import PageHeader from '../components/PageHeader';
import StatusPill from '../components/StatusPill';
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

  const handleExportCSV = useCallback(() => {
    if (emergencies.length === 0) return;
    const header = ['ID', 'Vehicle Number', 'Destination', 'Status', 'ETA', 'Started At'];
    const rows = emergencies.map(e => [
      e.id,
      e.ambulance_id || '',
      `"${(e.destination || '').replace(/"/g, '""')}"`,
      e.status || '',
      e.eta_minutes != null ? e.eta_minutes.toFixed(0) : '',
      formatDate(e.started_at)
    ]);
    const csvContent = [header, ...rows].map(e => e.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'emergencies_report.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }, [emergencies]);

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
      <PageHeader
        title="Emergencies"
        subtitle="Active emergency sessions across the city"
        action={
          <button
            onClick={handleExportCSV}
            disabled={emergencies.length === 0}
            className="flex items-center gap-1.5 rounded-lg bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm border border-gray-200 hover:bg-gray-50 disabled:opacity-50 dark:bg-gray-800 dark:text-gray-200 dark:border-gray-700 dark:hover:bg-gray-700"
          >
            <IconDownload className="h-4 w-4" stroke={1.7} />
            Export CSV
          </button>
        }
      >
        {!error && emergencies.length > 0 && (
          <span className="flex items-center gap-1.5 rounded-full bg-emergency px-3.5 py-1.5 text-sm font-medium text-white shadow-sm">
            <IconAlarm className="h-4 w-4" stroke={1.7} />
            {emergencies.length} active
          </span>
        )}
      </PageHeader>

      {error && <ErrorBanner message={error} onRetry={loadEmergencies} />}

      <Card bodyClassName="p-0">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 dark:bg-gray-800/60">
              <tr className="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">
                <th className="px-5 py-3.5 font-semibold">Session</th>
                <th className="px-5 py-3.5 font-semibold">Ambulance</th>
                <th className="px-5 py-3.5 font-semibold">Destination</th>
                <th className="px-5 py-3.5 font-semibold">ETA</th>
                <th className="px-5 py-3.5 font-semibold">Status</th>
                <th className="px-5 py-3.5 font-semibold">Started</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-700/60">
              {emergencies.map((e) => {
                const eta = e.eta_minutes?.toFixed(0);
                const urgent = e.eta_minutes != null && e.eta_minutes <= 5;
                return (
                  <tr
                    key={e.id}
                    className="transition-colors hover:bg-gray-50/80 dark:hover:bg-gray-800/40"
                  >
                    <td className="px-5 py-4">
                      <span className="inline-flex rounded-lg bg-gray-100 px-2 py-1 font-mono text-xs text-gray-600 dark:bg-gray-700 dark:text-gray-300">
                        #{e.id}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <span className="flex items-center gap-1.5 font-medium">
                        <IconAmbulance className="h-4 w-4 shrink-0 text-gray-400" stroke={1.7} />
                        {e.ambulance_id}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <span className="flex items-center gap-1.5">
                        <IconMapPin className="h-4 w-4 shrink-0 text-gray-400" stroke={1.7} />
                        {e.destination}
                      </span>
                    </td>
                    <td
                      className={`px-5 py-4 tabular-nums ${urgent ? 'font-semibold text-emergency' : ''}`}
                    >
                      <span className="flex items-center gap-1.5">
                        <IconClock className="h-4 w-4 text-gray-400" stroke={1.7} />
                        {eta ?? '-'} min
                        {urgent && (
                          <span className="ml-1 rounded-full bg-emergency/10 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide">
                            Urgent
                          </span>
                        )}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <StatusPill tone="red" label={e.status} pulse />
                    </td>
                    <td className="px-5 py-4 text-gray-500 dark:text-gray-400">
                      <span className="flex items-center gap-1.5">
                        <IconCalendarEvent className="h-4 w-4 text-gray-400" stroke={1.7} />
                        {formatDate(e.started_at)}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {!error && emergencies.length === 0 && (
          <div className="p-12 text-center">
            <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-gray-50 dark:bg-gray-700/60">
              <IconAlarm className="h-7 w-7 text-gray-300 dark:text-gray-600" stroke={1.5} />
            </span>
            <p className="mt-4 text-sm font-medium text-gray-600 dark:text-gray-300">
              No active emergencies
            </p>
            <p className="mt-1 text-sm text-gray-400 dark:text-gray-500">
              New sessions will appear here as soon as they are activated
            </p>
          </div>
        )}
      </Card>
    </div>
  );
}