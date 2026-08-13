import { useCallback, useEffect, useState } from 'react';
import { IconAmbulance, IconSteeringWheel } from '@tabler/icons-react';
import Card from '../components/Card';
import PageHeader from '../components/PageHeader';
import StatusPill from '../components/StatusPill';
import ErrorBanner from '../components/ErrorBanner';
import { ambulancesApi } from '../services/api';

const statusMeta = {
  available: {
    tone: 'green',
    label: 'Available',
    dot: 'bg-green-500',
  },
  on_duty: {
    tone: 'blue',
    label: 'On Duty',
    dot: 'bg-blue-500',
  },
  emergency: {
    tone: 'red',
    label: 'Emergency',
    dot: 'bg-red-500',
  },
  offline: {
    tone: 'gray',
    label: 'Offline',
    dot: 'bg-gray-400',
  },
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
              <span className={`h-2 w-2 rounded-full ${statusMeta[chip.key].dot}`} />
              {chip.label}
              <span className="font-bold tabular-nums">{counts[chip.key]}</span>
            </span>
          ))}
        </div>
      </PageHeader>

      {error && <ErrorBanner message={error} onRetry={loadAmbulances} />}

      <Card
        title="Fleet Registry"
        subtitle={`${ambulances.length} vehicles tracked`}
        icon={IconAmbulance}
        bodyClassName="p-0"
      >
        {!error && ambulances.length === 0 ? (
          <div className="p-12 text-center">
            <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-gray-50 dark:bg-gray-700/60">
              <IconAmbulance className="h-7 w-7 text-gray-300 dark:text-gray-600" stroke={1.5} />
            </span>
            <p className="mt-4 text-sm font-medium text-gray-600 dark:text-gray-300">
              No ambulances registered
            </p>
            <p className="mt-1 text-sm text-gray-400 dark:text-gray-500">
              Registered vehicles will appear here
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100 dark:divide-gray-700/60">
            {ambulances.map((a) => {
              const meta = statusMeta[a.status] || fallback;
              return (
                <div
                  key={a.id}
                  className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-gray-50/80 dark:hover:bg-gray-800/40 sm:px-6"
                >
                  <span
                    className={`h-2.5 w-2.5 shrink-0 rounded-full ${meta.dot} ${
                      meta.tone === 'red' ? 'animate-pulse' : ''
                    }`}
                  />
                  <div className="min-w-0 flex-1">
                    <p className="font-mono text-sm font-bold tracking-tight">
                      {a.vehicle_number}
                    </p>
                    <p className="mt-0.5 flex items-center gap-1.5 truncate text-xs text-gray-500 dark:text-gray-400">
                      <IconSteeringWheel className="h-3.5 w-3.5 shrink-0" stroke={1.7} />
                      {a.driver_name ?? 'No driver assigned'}
                    </p>
                  </div>
                  <span className="hidden shrink-0 font-mono text-xs text-gray-400 dark:text-gray-500 md:block">
                    #{a.id}
                  </span>
                  <StatusPill tone={meta.tone} label={meta.label} pulse={meta.tone === 'red'} />
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
}