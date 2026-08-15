import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ambulance_coordination/utils/route_utils.dart';

void main() {
  group('RouteUtils Unit Tests', () {
    test('parseRoutePolyline decodes coordinate json arrays', () {
      const polylineJson = '[[27.7172, 85.3240], [27.7350, 85.3300]]';
      final points = parseRoutePolyline(polylineJson);

      expect(points.length, 2);
      expect(points[0].latitude, 27.7172);
      expect(points[0].longitude, 85.3240);
      expect(points[1].latitude, 27.7350);
      expect(points[1].longitude, 85.3300);
    });

    test('parseRoutePolyline gracefully handles null or invalid strings', () {
      expect(parseRoutePolyline(null), isEmpty);
      expect(parseRoutePolyline(''), isEmpty);
      expect(parseRoutePolyline('invalid_json_content'), isEmpty);
    });

    test('formatEta properly formats minutes and hours', () {
      expect(formatEta(null), '?');
      expect(formatEta(0), '?');
      expect(formatEta(-5), '?');
      expect(formatEta(8.4), '8');
      expect(formatEta(14.7), '15');
      expect(formatEta(200), '3.3 hr');
    });

    test('collectMapPoints aggregates vehicle, dest, and polyline points', () {
      final points = collectMapPoints(
        ambulanceLat: 27.7000,
        ambulanceLon: 85.3100,
        destLat: 27.7200,
        destLon: 85.3300,
        routePolyline: '[[27.7100, 85.3200]]',
        extra: [const LatLng(27.6900, 85.3000)],
      );

      expect(points.length, 4);
    });
  });
}
