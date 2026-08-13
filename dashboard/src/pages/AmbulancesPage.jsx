import { useEffect, useState } from 'react';
import { ambulancesApi } from '../services/api';

export default function AmbulancesPage() {
  const [ambulances, setAmbulances] = useState([]);

  useEffect(() => {
    ambulancesApi.list().then((r) => setAmbulances(r.data)).catch(() => {});
  }, []);

  const statusColor = {
    available: 'bg-green-100 text-green-700',
    on_duty: 'bg-blue-100 text-blue-700',
    emergency: 'bg-red-100 text-red-700',
    offline: 'bg-gray-100 text-gray-700',
  };

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Ambulance Fleet</h1>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {ambulances.map((a) => (
          <div
            key={a.id}
            className="rounded-xl border p-5 dark:border-gray-700 dark:bg-gray-800"
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">{a.vehicle_number}</h3>
              <span
                className={`rounded-full px-2 py-1 text-xs ${statusColor[a.status] || ''}`}
              >
                {a.status}
              </span>
            </div>
            <p className="mt-2 text-sm text-gray-500">Driver: {a.driver_name ?? '-'}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
