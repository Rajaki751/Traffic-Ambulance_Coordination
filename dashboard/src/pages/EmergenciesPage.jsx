import { useEffect, useState } from 'react';
import { emergencyApi } from '../services/api';

export default function EmergenciesPage() {
  const [emergencies, setEmergencies] = useState([]);

  useEffect(() => {
    emergencyApi.active().then((r) => setEmergencies(r.data)).catch(() => {});
  }, []);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Active Emergency Sessions</h1>
      <div className="overflow-hidden rounded-xl border dark:border-gray-700">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th className="p-4">ID</th>
              <th className="p-4">Ambulance</th>
              <th className="p-4">Destination</th>
              <th className="p-4">ETA</th>
              <th className="p-4">Status</th>
              <th className="p-4">Started</th>
            </tr>
          </thead>
          <tbody>
            {emergencies.map((e) => (
              <tr key={e.id} className="border-t dark:border-gray-700">
                <td className="p-4">#{e.id}</td>
                <td className="p-4">{e.ambulance_id}</td>
                <td className="p-4">{e.destination}</td>
                <td className="p-4">{e.eta_minutes?.toFixed(0) ?? '-'} min</td>
                <td className="p-4">
                  <span className="rounded-full bg-red-100 px-2 py-1 text-xs text-red-700">
                    {e.status}
                  </span>
                </td>
                <td className="p-4">{new Date(e.started_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {emergencies.length === 0 && (
          <p className="p-8 text-center text-gray-500">No active emergencies</p>
        )}
      </div>
    </div>
  );
}
