import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Circle } from 'react-leaflet';
import { IconFlame } from '@tabler/icons-react';
import PageHeader from '../components/PageHeader';
import Card from '../components/Card';
import ErrorBanner from '../components/ErrorBanner';
import { analyticsApi } from '../services/api';

interface HeatmapData {
  latitude: number;
  longitude: number;
  intensity: number;
  radius: number;
}

export default function HeatmapPage() {
  const [data, setData] = useState<HeatmapData[]>([]);
  const [error, setError] = useState('');

  const loadData = async () => {
    try {
      const res = await analyticsApi.heatmap();
      setData(res.data);
      setError('');
    } catch (e) {
      console.error(e);
      setError('Failed to load heatmap data');
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const center: [number, number] = [27.7172, 85.3240];

  return (
    <div className="space-y-6 flex flex-col h-full">
      <PageHeader
        title="Predictive Heatmap"
        subtitle="AI-driven hotspots for emergency occurrences"
      />
      {error && <ErrorBanner message={error} onRetry={loadData} />}

      <Card
        className="flex-1"
        title="Hotspot Map"
        icon={IconFlame}
        bodyClassName="p-0 h-[600px] overflow-hidden"
      >
        <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }}>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/">OSM</a>'
            url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
          />
          {data.map((point, idx) => {
            // intensity is 0 to 1
            // 0 -> yellow, 1 -> deep red
            // rgb: 0 -> (255, 255, 0), 1 -> (255, 0, 0)
            const g = Math.floor(255 * (1 - point.intensity));
            const color = `rgba(255, ${g}, 0, 0.8)`;
            return (
              <Circle
                key={idx}
                center={[point.latitude, point.longitude]}
                radius={point.radius}
                pathOptions={{
                  color: color,
                  fillColor: color,
                  fillOpacity: 0.6,
                }}
              />
            );
          })}
        </MapContainer>
      </Card>
    </div>
  );
}
