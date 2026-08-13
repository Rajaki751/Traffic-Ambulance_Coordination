import 'dart:convert';

import 'package:latlong2/latlong.dart';

List<LatLng> parseRoutePolyline(String? polyline) {
  if (polyline == null || polyline.isEmpty) return [];
  try {
    final decoded = jsonDecode(polyline);
    if (decoded is! List) return [];
    return decoded
        .map((point) {
          if (point is List && point.length >= 2) {
            return LatLng(
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            );
          }
          return null;
        })
        .whereType<LatLng>()
        .toList();
  } catch (_) {
    return [];
  }
}

String formatEta(double? minutes) {
  if (minutes == null || minutes.isNaN || minutes <= 0) return '?';
  if (minutes > 180) return '${(minutes / 60).toStringAsFixed(1)} hr';
  return minutes.round().toString();
}

List<LatLng> collectMapPoints({
  double? ambulanceLat,
  double? ambulanceLon,
  double? destLat,
  double? destLon,
  String? routePolyline,
  List<LatLng> extra = const [],
}) {
  final points = <LatLng>[...extra];
  if (ambulanceLat != null && ambulanceLon != null) {
    points.add(LatLng(ambulanceLat, ambulanceLon));
  }
  if (destLat != null && destLon != null) {
    points.add(LatLng(destLat, destLon));
  }
  points.addAll(parseRoutePolyline(routePolyline));
  return points;
}
