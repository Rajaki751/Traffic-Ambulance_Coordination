import { IconAlarm, IconClock, IconMapPin } from '@tabler/icons-react';
import Card from '../Card';
import StatusPill from '../StatusPill';
import { Emergency } from '../../types';

interface ActiveSessionsCardProps {
  emergencies: Emergency[];
}

function formatTime(value: string | Date | null | undefined): string {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

export default function ActiveSessionsCard({ emergencies }: ActiveSessionsCardProps) {
  return (
    <Card
      title="Active Sessions"
      subtitle={`${emergencies.length} running right now`}
      icon={IconAlarm}
      bodyClassName="space-y-3 p-4"
    >
      {emergencies.length === 0 ? (
        <div className="rounded-xl border border-dashed p-8 text-center dark:border-gray-700">
          <IconAlarm
            className="mx-auto h-7 w-7 text-gray-300 dark:text-gray-600"
            stroke={1.5}
          />
          <p className="mt-3 text-sm text-gray-500 dark:text-gray-400">
            No active emergencies
          </p>
        </div>
      ) : (
        emergencies.map((e) => (
          <div
            key={e.id}
            className="rounded-xl border border-red-100 bg-red-50/60 p-3.5 transition-shadow hover:shadow-sm dark:border-red-900/40 dark:bg-red-900/15"
          >
            <div className="flex items-center justify-between gap-2">
              <p className="text-sm font-semibold tracking-tight">
                Session <span className="font-mono">#{e.id}</span>
              </p>
              <StatusPill tone="red" label="Active" pulse />
            </div>
            <p className="mt-2 flex items-center gap-1.5 truncate text-sm text-gray-700 dark:text-gray-300">
              <IconMapPin className="h-4 w-4 shrink-0 text-emergency/70" stroke={1.7} />
              <span className="truncate">{e.destination}</span>
            </p>
            <p className="mt-1 flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
              <IconClock className="h-3.5 w-3.5" stroke={1.7} />
              ETA {e.eta_minutes?.toFixed(0) ?? '?'} min
              <span className="text-gray-300 dark:text-gray-600">·</span>
              since {formatTime(e.started_at)}
            </p>
          </div>
        ))
      )}
    </Card>
  );
}
