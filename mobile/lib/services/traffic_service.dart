import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../core/kathmandu.dart';
import 'api_service.dart';

class TrafficPoint {
  final double lat;
  final double lon;
  final double index; // 0.0 (free) - 1.0 (severe)

  TrafficPoint({required this.lat, required this.lon, required this.index});
}

class TrafficService {
  final ApiService? _api;
  TrafficService([this._api]);

  /// Try to fetch traffic points from backend; if it fails, return synthetic data.
  Future<List<TrafficPoint>> fetchKathmanduTraffic() async {
    if (_api != null) {
      try {
        final res = await _api!.get('/api/v1/ai/model-info');
        if (res.statusCode == 200) {
          return _generateSyntheticKathmanduTraffic();
        }
      } catch (_) {
        // ignore and fall back to synthetic
      }
    }
    return _generateSyntheticKathmanduTraffic();
  }

  List<TrafficPoint> _generateSyntheticKathmanduTraffic() {
    final rng = Random(42);
    const radiusKm = 8.0;
    final points = <TrafficPoint>[];
    final cellCount = 9;
    for (var i = 0; i < cellCount; i++) {
      for (var j = 0; j < cellCount; j++) {
        final lat = KathmanduLocation.centerLat + (i - cellCount / 2) * (radiusKm / 110.0);
        final lon = KathmanduLocation.centerLon + (j - cellCount / 2) * (radiusKm / (110.0 * cos(KathmanduLocation.centerLat * pi / 180)));
        final distKm = sqrt(pow(lat - KathmanduLocation.centerLat, 2) + pow(lon - KathmanduLocation.centerLon, 2)) * 110.0;
        final base = (1.0 - (distKm / radiusKm)).clamp(0.0, 1.0);
        final hour = DateTime.now().hour;
        final peak = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 19) ? 0.25 : 0.0;
        final jitter = (rng.nextDouble() - 0.5) * 0.15;
        final idx = (base * 0.7 + peak + jitter).clamp(0.0, 1.0);
        points.add(TrafficPoint(lat: lat, lon: lon, index: idx));
      }
    }
    return points;
  }
}
