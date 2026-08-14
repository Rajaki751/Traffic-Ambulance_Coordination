import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useEffect, useMemo, useRef, Fragment } from 'react';

const ambulanceIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

const destinationIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

function decodePolyline(encoded) {
  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  while (index < encoded.length) {
    let b, shift = 0, result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += ((result & 1) ? ~(result >> 1) : (result >> 1));
    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += ((result & 1) ? ~(result >> 1) : (result >> 1));
    points.push([lat / 1e5, lng / 1e5]);
  }
  return points;
}

function parseRoutePolyline(polyline) {
  if (!polyline) return [];
  try {
    const parsed = JSON.parse(polyline);
    if (
      Array.isArray(parsed) &&
      parsed.every(
        (p) =>
          Array.isArray(p) &&
          p.length >= 2 &&
          typeof p[0] === 'number' &&
          typeof p[1] === 'number'
      )
    ) {
      return parsed.map((p) => [p[0], p[1]]);
    }
  } catch {
    // fall through to encoded polyline decode
  }
  return decodePolyline(polyline);
}

function FitBounds({ ambulances }) {
  const map = useMap();
  const hasFitted = useRef(false);

  useEffect(() => {
    if (!map || ambulances.length === 0 || hasFitted.current) return;
    const positions = [];
    ambulances.forEach((amb) => {
      if (amb.route_polyline) {
        positions.push(...parseRoutePolyline(amb.route_polyline));
      }
      positions.push([amb.latitude, amb.longitude]);
      if (amb.dest_latitude && amb.dest_longitude) {
        positions.push([amb.dest_latitude, amb.dest_longitude]);
      }
    });
    map.fitBounds(L.latLngBounds(positions), { padding: [50, 50] });
    hasFitted.current = true;
  }, [map, ambulances]);

  return null;
}

export default function LiveMap({ ambulances = [], center = [27.7172, 85.3240] }) {
  return (
    <div className="h-[400px] w-full overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700">
      <MapContainer center={center} zoom={13} className="h-full w-full">
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {ambulances.length > 0 && <FitBounds ambulances={ambulances} />}
        {ambulances.map((amb) => {
          const routePositions = parseRoutePolyline(amb.route_polyline);
          return (
            <Fragment key={amb.ambulance_id ?? amb.id}>
              {routePositions.length > 1 && (
                <Polyline
                  positions={routePositions}
                  pathOptions={{ color: '#ef4444', weight: 4, opacity: 0.8 }}
                />
              )}
              {amb.dest_latitude && amb.dest_longitude && (
                <Marker
                  position={[amb.dest_latitude, amb.dest_longitude]}
                  icon={destinationIcon}
                >
                  <Popup>
                    <strong>Destination</strong><br />
                    {amb.destination}
                  </Popup>
                </Marker>
              )}
              <Marker
                position={[amb.latitude, amb.longitude]}
                icon={ambulanceIcon}
              >
                <Popup>
                  <strong>{amb.vehicle_number}</strong>
                  <br />
                  Destination: {amb.destination}
                  <br />
                  ETA: {amb.eta_minutes?.toFixed(0) ?? '?'} min
                  <br />
                  Speed: {amb.speed_kmh?.toFixed(0) ?? '-'} km/h
                </Popup>
              </Marker>
            </Fragment>
          );
        })}
      </MapContainer>
    </div>
  );
}