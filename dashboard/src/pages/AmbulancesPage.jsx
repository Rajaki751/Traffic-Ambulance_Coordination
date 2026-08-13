import { useCallback, useEffect, useState } from 'react';
import { IconAmbulance, IconSteeringWheel } from '@tabler/icons-react';
import Card from '../components/Card';
import PageHeader from '../components/PageHeader';
import StatusPill from '../components/StatusPill';
import ErrorBanner from '../components/ErrorBanner';
import { ambulancesApi } from '../services/api';

const statusMeta = {
  available: { tone: 'green', label: 'Available', accent: 'bg-green-500', icon: 'bg-green-50 text-green-600 dark:bg-green-900/40 dark:text-green-300' },
  on_duty: { tone: 'blue', label: 'On Duty', accent: 'bg-blue-500', icon: 'bg-blue-50 text-blue-600 dark:bg-blue-900/40 dark:text-blue-300' },
  emergency: { tone: 'red', label: 'Emergency', accent: 'bg-red-500', icon: 'bg-red-50 text-red-600 dark:bg-red-900/40 dark:text-red-300' },
  offline: { tone: 'gray', label: 'Offline', accent: 'bg-gray-400', icon: 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400' },
};

const fallback = statusMeta.offline;

export default function AmbulancesPage() {
  const [ambulances, setAmbulances] = useState([]);
  const [error, setError] = useState('');

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
      >
        <div className="flex flex-wrap items-center gap-2">
          {summaryChips.map((chip) => (
            <span
              key={chip.key}
              className="flex items-center gap-2 rounded-full border bg-white px-3.5 py-1.5 text-xs font-medium dark:border-gray-700 dark:bg-gray-800"
            >
              <span className={`h-2 w-2 rounded-full ${statusMeta[chip.key].accent}`} />
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
                className="overflow-hidden rounded-2xl border bg-white shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
              >
                <div className={`h-1 ${meta.accent}`} />
                <div className="p-5">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex min-w-0 items-center gap-3">
                      <span
                        className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${meta.icon}`}
                      >
                        <IconAmbulance className="h-6 w-6" stroke={1.7} />
                      </span>
                      <div className="min-w-0">
                        <h3 className="truncate font-mono text-base font-semibold tracking-tight">
                          {a.vehicle_number}
                        </h3>
                        <p className="text-xs text-gray-400 dark:text-gray-500">
                          Unit #{a.id}
                        </p>
                      </div>
                    </div>
                    <StatusPill tone={meta.tone} label={meta.label} pulse={meta.tone === 'red'} />
                  </div>
                  <div className="mt-4 flex items-center gap-2 border-t border-gray-100 pt-3.5 text-sm text-gray-500 dark:border-gray-700/60 dark:text-gray-400">
                    <IconSteeringWheel className="h-4 w-4 shrink-0" stroke={1.7} />
                    {a.driver_name ?? 'No driver assigned'}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}