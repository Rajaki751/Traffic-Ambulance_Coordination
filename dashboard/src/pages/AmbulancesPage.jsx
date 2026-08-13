import { useCallback, useEffect, useState } from 'react';
import { IconAmbulance, IconUser } from '@tabler/icons-react';
import ErrorBanner from '../components/ErrorBanner';
import { ambulancesApi } from '../services/api';

const statusColor = {
  available: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
  on_duty: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  emergency: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  offline: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
};

const statusDot = {
  available: 'bg-green-500',
  on_duty: 'bg-blue-500',
  emergency: 'bg-red-500 animate-pulse',
  offline: 'bg-gray-400',
};

const statusLabel = {
  available: 'Available',
  on_duty: 'On Duty',
  emergency: 'Emergency',
  offline: 'Offline',
};

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

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold tracking-tight">Ambulance Fleet</h1>
      {error && <ErrorBanner message={error} onRetry={loadAmbulances} />}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {ambulances.map((a) => (
          <div
            key={a.id}
            className="rounded-xl border p-5 transition-shadow hover:shadow-sm dark:border-gray-700 dark:bg-gray-800"
          >
            <div className="flex items-center justify-between gap-3">
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-emergency/10 text-emergency">
                  <IconAmbulance className="h-6 w-6" stroke={1.7} />
                </div>
                <h3 className="truncate text-lg font-bold tracking-tight">
                  {a.vehicle_number}
                </h3>
              </div>
              <span
                className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${statusColor[a.status] || statusColor.offline}`}
              >
                <span className={`h-1.5 w-1.5 rounded-full ${statusDot[a.status] || statusDot.offline}`} />
                {statusLabel[a.status] || a.status}
              </span>
            </div>
            <div className="mt-4 flex items-center gap-1.5 border-t pt-3 text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400">
              <IconUser className="h-4 w-4 shrink-0" stroke={1.7} />
              {a.driver_name ?? 'No driver assigned'}
            </div>
          </div>
        ))}
      </div>
      {!error && ambulances.length === 0 && (
        <div className="p-10 text-center">
          <IconAmbulance className="mx-auto h-8 w-8 text-gray-300 dark:text-gray-600" stroke={1.5} />
          <p className="mt-3 text-sm text-gray-500">No ambulances registered</p>
        </div>
      )}
    </div>
  );
}
