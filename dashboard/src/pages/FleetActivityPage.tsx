import { useEffect, useState, useCallback } from 'react';
import { IconAmbulance, IconActivity } from '@tabler/icons-react';
import { analyticsApi } from '../services/api';
import PageHeader from '../components/PageHeader';
import Card from '../components/Card';
import ErrorBanner from '../components/ErrorBanner';
import { AmbulanceStats } from '../types';

export default function FleetActivityPage() {
  const [ambulances, setAmbulances] = useState<AmbulanceStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const res = await analyticsApi.ambulances();
      setAmbulances(res.data);
      setError('');
    } catch (e) {
      console.error(e);
      setError('Failed to load fleet activity');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 15000);
    return () => clearInterval(interval);
  }, [loadData]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Fleet Activity"
        subtitle="Complete overview of all ambulance operations and emergency counts"
      />
      {error && <ErrorBanner message={error} onRetry={loadData} />}

      <Card
        title="All Ambulances"
        icon={IconActivity}
        bodyClassName="p-4"
      >
        {loading && ambulances.length === 0 ? (
          <p className="text-sm text-gray-500">Loading...</p>
        ) : ambulances.length === 0 ? (
          <p className="text-sm text-gray-500">No ambulance data available</p>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ambulances.map((a) => (
              <div
                key={a.ambulance_id}
                className="flex items-center justify-between gap-3 rounded-xl border border-gray-100 p-4 shadow-sm dark:border-gray-700/60"
              >
                <div className="flex min-w-0 items-center gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-gray-50 dark:bg-gray-700/60">
                    <IconAmbulance
                      className={`h-5 w-5 ${a.active_session_id ? 'text-emergency' : 'text-gray-400 dark:text-gray-500'}`}
                      stroke={1.7}
                    />
                  </span>
                  <div>
                    <div className="truncate font-mono text-sm font-semibold">{a.vehicle_number}</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      {a.total_emergencies} total emergencies
                    </div>
                  </div>
                </div>
                {a.active_session_id && (
                  <span className="shrink-0 rounded-full bg-emergency/10 px-2.5 py-1 text-xs font-medium text-emergency">
                    Active
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
