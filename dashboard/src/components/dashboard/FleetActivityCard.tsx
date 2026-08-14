import { Link } from 'react-router-dom';
import { IconAmbulance, IconArrowRight } from '@tabler/icons-react';
import Card from '../Card';
import { AmbulanceStats } from '../../types';

interface FleetActivityCardProps {
  ambulances: AmbulanceStats[];
}

export default function FleetActivityCard({ ambulances }: FleetActivityCardProps) {
  return (
    <Card
      title="Fleet Activity"
      subtitle="Emergency count per ambulance"
      icon={IconAmbulance}
      action={
        <Link
          to="/fleet"
          className="flex h-8 w-8 items-center justify-center rounded-lg hover:bg-gray-100 text-gray-500 transition-colors dark:hover:bg-gray-700"
          title="View all fleet activity"
        >
          <IconArrowRight className="h-4 w-4" />
        </Link>
      }
      bodyClassName="p-4"
    >
      {ambulances.length === 0 ? (
        <p className="text-sm text-gray-500">No ambulance data</p>
      ) : (
        <div className="space-y-2.5">
          {ambulances.slice(0, 6).map((a) => (
            <div
              key={a.ambulance_id}
              className="flex items-center justify-between gap-3 text-sm"
            >
              <span className="flex min-w-0 items-center gap-2 font-medium">
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-gray-50 dark:bg-gray-700/60">
                  <IconAmbulance
                    className={`h-4 w-4 ${a.active_session_id ? 'text-emergency' : 'text-gray-400 dark:text-gray-500'}`}
                    stroke={1.7}
                  />
                </span>
                <span className="truncate font-mono text-xs">{a.vehicle_number}</span>
              </span>
              <span className="shrink-0 text-xs tabular-nums text-gray-500 dark:text-gray-400">
                {a.total_emergencies} emergencies
                {a.active_session_id && (
                  <span className="ml-1.5 inline-flex items-center gap-1 text-emergency">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emergency" />
                    active
                  </span>
                )}
              </span>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}
