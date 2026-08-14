import { useCallback, useEffect, useState } from 'react';
import { IconAmbulance, IconSteeringWheel, IconDownload } from '@tabler/icons-react';
import Card from '../components/Card';
import PageHeader from '../components/PageHeader';
import ErrorBanner from '../components/ErrorBanner';
import { ambulancesApi } from '../services/api';

const statusMeta = {
  available: {
    label: 'Available',
    dot: 'bg-green-500',
    text: 'text-green-600 dark:text-green-400',
    alert: false,
  },
  on_duty: {
    label: 'On Duty',
    dot: 'bg-blue-500',
    text: 'text-blue-600 dark:text-blue-400',
    alert: false,
  },
  emergency: {
    label: 'Emergency',
    dot: 'bg-red-500',
    text: 'text-red-600 dark:text-red-400',
    alert: true,
  },
  offline: {
    label: 'Offline',
    dot: 'bg-gray-400',
    text: 'text-gray-500 dark:text-gray-400',
    alert: false,
  },
};

const fallback = statusMeta.offline;

export default function AmbulancesPage() {
  const [ambulances, setAmbulances] = useState([]);
  const [error, setError] = useState('');

  const handleExportCSV = useCallback(() => {
    if (ambulances.length === 0) return;
    const header = ['ID', 'Vehicle Number', 'Driver Name', 'Status'];
    const rows = ambulances.map(a => [
      a.id,
      a.vehicle_number || '',
      `"${(a.driver_name || '').replace(/"/g, '""')}"`,
      a.status || ''
    ]);
    const csvContent = [header, ...rows].map(e => e.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'ambulances_report.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }, [ambulances]);

  const loadAmbulances = useCallback(() => {
    setError('');
    ambulancesApi.list()
      .then((r) => setAmbulances(r.data))
      .catch(() => setError('Failed to load ambulances'));
  }, []);

  useEffect(() => {
    loadAmbulances();
  }, [loadAmbulances]);

  const counts = ambulances.reduce(
    (acc, a) => {
      const key = statusMeta[a.status] ? a.status : 'offline';
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    },
    { available: 0, on_duty: 0, emergency: 0, offline: 0 }
  );

  const summaryChips = [
    { key: 'available', label: 'Available' },
    { key: 'on_duty', label: 'On Duty' },
    { key: 'emergency', label: 'Emergency' },
    { key: 'offline', label: 'Offline' },
  ];

  return (
    <div>
      <PageHeader
        title="Ambulance Fleet"
        subtitle="All registered ambulances and driver assignments"
        action={
          <button
            onClick={handleExportCSV}
            disabled={ambulances.length === 0}
            className="flex items-center gap-1.5 rounded-lg bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm border border-gray-200 hover:bg-gray-50 disabled:opacity-50 dark:bg-gray-800 dark:text-gray-200 dark:border-gray-700 dark:hover:bg-gray-700"
          >
            <IconDownload className="h-4 w-4" stroke={1.7} />
            Export CSV
          </button>
        }
      >
        <div className="flex flex-wrap items-center gap-2">
          {summaryChips.map((chip) => (
            <span
              key={chip.key}
              className="flex items-center gap-2 rounded-full border bg-white px-3.5 py-1.5 text-xs font-medium dark:border-gray-700 dark:bg-gray-800"
            >
              <span className={`h-2 w-2 rounded-full ${statusMeta[chip.key].dot}`} />
              {chip.label}
              <span className="font-bold tabular-nums">{counts[chip.key]}</span>
            </span>
          ))}
        </div>
      </PageHeader>

      {error && <ErrorBanner message={error} onRetry={loadAmbulances} />}

      {!error && ambulances.length === 0 ? (
        <Card bodyClassName="p-12 text-center">
          <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-gray-50 dark:bg-gray-700/60">
            <IconAmbulance className="h-7 w-7 text-gray-300 dark:text-gray-600" stroke={1.5} />
          </span>
          <p className="mt-4 text-sm font-medium text-gray-600 dark:text-gray-300">
            No ambulances registered
          </p>
          <p className="mt-1 text-sm text-gray-400 dark:text-gray-500">
            Registered vehicles will appear here
          </p>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {ambulances.map((a) => {
            const meta = statusMeta[a.status] || fallback;
            return (
              <div
                key={a.id}
                className={`rounded-2xl border p-5 shadow-sm transition-shadow hover:shadow-md ${
                  meta.alert
                    ? 'border-red-200 bg-red-50/40 dark:border-red-900/40 dark:bg-red-900/10'
                    : 'border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800'
                }`}
              >
                <div className="flex items-center justify-between gap-3">
                  <span className="inline-flex items-center rounded-lg bg-gray-900 px-2.5 py-1.5 font-mono text-sm font-bold tracking-wide text-white">
                    {a.vehicle_number}
                  </span>
                  <span
                    className={`flex shrink-0 items-center gap-1.5 text-xs font-medium ${meta.text}`}
                  >
                    <span
                      className={`h-2 w-2 rounded-full ${meta.dot} ${
                        meta.alert ? 'animate-pulse' : ''
                      }`}
                    />
                    {meta.label}
                  </span>
                </div>
                <div className="mt-4 flex items-center gap-2 border-t border-gray-100 pt-3.5 text-sm dark:border-gray-700/60">
                  <IconSteeringWheel
                    className="h-4 w-4 shrink-0 text-gray-400 dark:text-gray-500"
                    stroke={1.7}
                  />
                  <span className="text-gray-500 dark:text-gray-400">
                    Driver:{' '}
                    <span className="font-medium text-gray-700 dark:text-gray-200">
                      {a.driver_name ?? 'Unassigned'}
                    </span>
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}