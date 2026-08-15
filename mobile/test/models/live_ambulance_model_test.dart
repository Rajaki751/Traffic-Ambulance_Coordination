import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/live_ambulance_model.dart';

void main() {
  group('LiveAmbulanceModel Unit Tests', () {
    test('fromJson correctly parses live vehicle state and coordinates', () {
      final json = {
        'ambulance_id': 5,
        'vehicle_number': 'BA-1-JHA-5555',
        'emergency_session_id': 19,
        'latitude': 27.7172,
        'longitude': 85.3240,
        'speed_kmh': 55.4,
        'destination': 'Tribhuvan University Teaching Hospital',
        'dest_latitude': 27.7350,
        'dest_longitude': 85.3300,
        'route_polyline': '[[27.7172, 85.3240], [27.7350, 85.3300]]',
        'eta_minutes': 6.2,
        'status': 'emergency',
      };

      final amb = LiveAmbulanceModel.fromJson(json);

      expect(amb.ambulanceId, 5);
      expect(amb.vehicleNumber, 'BA-1-JHA-5555');
      expect(amb.emergencySessionId, 19);
      expect(amb.latitude, 27.7172);
      expect(amb.longitude, 85.3240);
      expect(amb.speedKmh, 55.4);
      expect(amb.destination, 'Tribhuvan University Teaching Hospital');
      expect(amb.destLat, 27.7350);
      expect(amb.destLon, 85.3300);
      expect(amb.etaMinutes, 6.2);
      expect(amb.status, 'emergency');
    });

    test('fromJson handles optional speed and polyline values', () {
      final json = {
        'ambulance_id': 6,
        'vehicle_number': 'BA-2-CHA-7777',
        'emergency_session_id': 20,
        'latitude': 27.7000,
        'longitude': 85.3000,
        'destination': 'Patan Hospital',
      };

      final amb = LiveAmbulanceModel.fromJson(json);

      expect(amb.ambulanceId, 6);
      expect(amb.speedKmh, isNull);
      expect(amb.routePolyline, isNull);
      expect(amb.etaMinutes, isNull);
      expect(amb.status, 'emergency');
    });
  });
}
