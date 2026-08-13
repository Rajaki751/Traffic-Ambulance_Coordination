import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/kathmandu.dart';
import '../providers/settings_provider.dart';
import '../services/traffic_service.dart';
import '../utils/route_utils.dart';

class AmbulanceMap extends StatefulWidget {
  final double? ambulanceLat;
  final double? ambulanceLon;
  final double? destLat;
  final double? destLon;
  final String? routePolyline;
  final List<LiveAmbulanceMarker> extraAmbulances;
  final bool showKathmanduHospitals;
  final bool showTrafficOverlay;

  const AmbulanceMap({
    super.key,
    this.ambulanceLat,
    this.ambulanceLon,
    this.destLat,
    this.destLon,
    this.routePolyline,
    this.extraAmbulances = const [],
    this.showKathmanduHospitals = true,
    this.showTrafficOverlay = true,
  });

  @override
  State<AmbulanceMap> createState() => _AmbulanceMapState();
}

class LiveAmbulanceMarker {
  final double lat;
  final double lon;
  final String label;
  final String? routePolyline;
  final double? destLat;
  final double? destLon;

  LiveAmbulanceMarker({
    required this.lat,
    required this.lon,
    required this.label,
    this.routePolyline,
    this.destLat,
    this.destLon,
  });
}

class _AmbulanceMapState extends State<AmbulanceMap> {
  final MapController _mapController = MapController();
  List<CircleMarker> _trafficCircles = [];
  bool _loadingTraffic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToContent();
      if (widget.showTrafficOverlay) _loadTraffic();
    });
  }

  Future<void> _loadTraffic() async {
    setState(() => _loadingTraffic = true);
    try {
      final svc = TrafficService();
      final pts = await svc.fetchKathmanduTraffic();
      final circles = pts.map((p) {
        final color = _colorForIndex(p.index);
        final radius = 18.0 + p.index * 32.0; // radius in pixels
        return CircleMarker(
          point: LatLng(p.lat, p.lon),
          color: color.withOpacity(0.55),
          radius: radius,
          useRadiusInMeter: false,
        );
      }).toList();
      setState(() => _trafficCircles = circles);
    } catch (_) {
      setState(() => _trafficCircles = []);
    }
    setState(() => _loadingTraffic = false);
  }

  @override
  void didUpdateWidget(covariant AmbulanceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coordsChanged = widget.ambulanceLat != oldWidget.ambulanceLat ||
        widget.ambulanceLon != oldWidget.ambulanceLon ||
        widget.destLat != oldWidget.destLat ||
        widget.destLon != oldWidget.destLon ||
        widget.routePolyline != oldWidget.routePolyline ||
        widget.extraAmbulances.length != oldWidget.extraAmbulances.length;
    if (coordsChanged) _fitToContent();
    if (widget.showTrafficOverlay && !oldWidget.showTrafficOverlay) _loadTraffic();
  }

  void _fitToContent() {
    final points = <LatLng>[];
    if (widget.ambulanceLat != null && widget.ambulanceLon != null) {
      points.add(LatLng(widget.ambulanceLat!, widget.ambulanceLon!));
    }
    if (widget.destLat != null && widget.destLon != null) {
      points.add(LatLng(widget.destLat!, widget.destLon!));
    }
    for (final a in widget.extraAmbulances) {
      points.add(LatLng(a.lat, a.lon));
      if (a.destLat != null && a.destLon != null) {
        points.add(LatLng(a.destLat!, a.destLon!));
      }
    }
    if (points.isEmpty) return;

    final center = LatLng(
      widget.ambulanceLat ?? widget.destLat ?? KathmanduLocation.centerLat,
      widget.ambulanceLon ?? widget.destLon ?? KathmanduLocation.centerLon,
    );

    const d = Distance();
    bool tooFar = false;
    for (final p in points) {
      if (d.as(LengthUnit.Meter, center, p) > 50000) {
        tooFar = true;
        break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tooFar) {
        _mapController.move(center, 14);
        return;
      }
      if (points.length == 1) {
        _mapController.move(points.first, 16);
        return;
      }
      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLon = points.first.longitude;
      var maxLon = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat, minLon),
            LatLng(maxLat, maxLon),
          ),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final routePoints = parseRoutePolyline(widget.routePolyline);
    final markers = <Marker>[];

    if (widget.ambulanceLat != null && widget.ambulanceLon != null) {
      markers.add(_marker(
        widget.ambulanceLat!,
        widget.ambulanceLon!,
        Icons.local_shipping,
        Colors.red,
        'Ambulance',
      ));
    }
    if (widget.destLat != null && widget.destLon != null) {
      markers.add(_marker(
        widget.destLat!,
        widget.destLon!,
        Icons.emergency,
        Colors.orange,
        'Incident',
      ));
    }

    for (final a in widget.extraAmbulances) {
      markers.add(_marker(a.lat, a.lon, Icons.local_shipping, Colors.red, a.label));
      if (a.destLat != null && a.destLon != null) {
        markers.add(_marker(
          a.destLat!,
          a.destLon!,
          Icons.emergency,
          Colors.orange,
          '${a.label} dest',
        ));
      }
    }
    if (widget.showKathmanduHospitals) {
      for (final h in kathmanduHospitals) {
        markers.add(_marker(h.lat, h.lon, Icons.local_hospital, Colors.green, h.name));
      }
    }

    final polylines = <Polyline>[
      if (routePoints.isNotEmpty)
        Polyline(points: routePoints, color: Colors.red, strokeWidth: 5),
      for (final a in widget.extraAmbulances)
        if (parseRoutePolyline(a.routePolyline).isNotEmpty)
          Polyline(
            points: parseRoutePolyline(a.routePolyline),
            color: Colors.blue,
            strokeWidth: 4,
          ),
    ];

    final center = LatLng(
      widget.ambulanceLat ?? widget.destLat ?? KathmanduLocation.centerLat,
      widget.ambulanceLon ?? widget.destLon ?? KathmanduLocation.centerLon,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        minZoom: 12,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ambulance.coordination',
        ),
        if ((widget.showTrafficOverlay && _trafficCircles.isNotEmpty) && settings.showTrafficOverlay)
          CircleLayer(circles: _trafficCircles),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Marker _marker(
    double lat,
    double lon,
    IconData icon,
    Color color,
    String label,
  ) {
    return Marker(
      point: LatLng(lat, lon),
      width: 80,
      height: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForIndex(double i) {
  // green (0) -> yellow (0.5) -> red (1)
  final clamped = i.clamp(0.0, 1.0);
  if (clamped < 0.5) {
    final t = clamped / 0.5;
    return Color.lerp(Colors.green, Colors.yellow, t)!;
  }
  final t = (clamped - 0.5) / 0.5;
  return Color.lerp(Colors.yellow, Colors.red, t)!;
}
