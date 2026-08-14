import { IconAmbulance, IconMapPin, IconMapPin2 } from '@tabler/icons-react';
import Card from '../Card';
import LiveMap from '../LiveMap';
import { LiveLocation } from '../../types';

interface DashboardMapCardProps {
  liveLocations: LiveLocation[];
  mapCenter: [number, number];
}

export default function DashboardMapCard({ liveLocations, mapCenter }: DashboardMapCardProps) {
  return (
    <Card
      className="lg:col-span-2"
      title="Live Map"
      subtitle="Ambulance positions updated in real time"
      icon={IconMapPin}
      bodyClassName="p-3"
      action={
        <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
          <span className="flex items-center gap-1.5">
            <IconAmbulance className="h-4 w-4 text-emergency" stroke={1.7} />
            Ambulance
          </span>
          <span className="flex items-center gap-1.5">
            <IconMapPin2 className="h-4 w-4 text-green-600" stroke={1.7} />
            Destination
          </span>
        </div>
      }
    >
      <div className="h-[440px] overflow-hidden rounded-xl">
        <LiveMap ambulances={liveLocations} center={mapCenter} />
      </div>
    </Card>
  );
}
