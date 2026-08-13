import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/emergency_model.dart';
import '../providers/emergency_provider.dart';
import '../providers/live_ambulance_provider.dart';
import '../utils/route_utils.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  bool _followMode = true;
  bool _showSteps = false;
  double? _currentLat;
  double? _currentLon;
  StreamSubscription<void>? _posSub;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<DriverLocationProvider>();
      _currentLat = loc.lat;
      _currentLon = loc.lon;
      _fitToRoute();
      _listenPosition();
    });
  }

  void _listenPosition() {
    _posSub?.cancel();
    _posSub = null;
    _posSub = Stream.periodic(const Duration(seconds: 2)).listen((_) {
      if (!mounted) return;
      final newLat = context.read<DriverLocationProvider>().lat;
      final newLon = context.read<DriverLocationProvider>().lon;
      if (newLat != null && newLon != null) {
        setState(() {
          _currentLat = newLat;
          _currentLon = newLon;
        });
        _updateNearestStep();
        if (_followMode) _panToCurrent();
      }
    });
  }

  void _updateNearestStep() {
    final emergency = context.read<EmergencyProvider>().activeEmergency;
    if (emergency == null) return;
    final points = parseRoutePolyline(emergency.routePolyline);
    if (points.isEmpty || _currentLat == null || _currentLon == null) return;
    final current = LatLng(_currentLat!, _currentLon!);
    const d = Distance();
    double minDist = double.infinity;
    int nearestIdx = 0;
    for (var i = 0; i < points.length; i++) {
      final dist = d.as(LengthUnit.Meter, current, points[i]);
      if (dist < minDist) {
        minDist = dist;
        nearestIdx = i;
      }
    }
    final steps = emergency.routeSteps;
    if (steps != null && steps.isNotEmpty) {
      final fraction = nearestIdx / math.max(points.length - 1, 1);
      final idx = (fraction * (steps.length - 1)).round();
      if (idx != _currentStepIndex) {
        setState(() => _currentStepIndex = idx);
      }
    }
  }

  void _panToCurrent() {
    if (_currentLat != null && _currentLon != null) {
      _mapController.move(
        LatLng(_currentLat!, _currentLon!),
        _mapController.camera.zoom,
      );
    }
  }

  void _fitToRoute() {
    final emergency = context.read<EmergencyProvider>().activeEmergency;
    if (emergency == null) return;
    final points = <LatLng>[];
    if (_currentLat != null && _currentLon != null) {
      points.add(LatLng(_currentLat!, _currentLon!));
    }
    if (emergency.destLat != null && emergency.destLon != null) {
      points.add(LatLng(emergency.destLat!, emergency.destLon!));
    }
    points.addAll(parseRoutePolyline(emergency.routePolyline));
    if (points.isEmpty) return;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (points.length == 1) {
        _mapController.move(points.first, 16);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat, minLon),
            LatLng(maxLat, maxLon),
          ),
          padding: const EdgeInsets.all(64),
        ),
      );
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>().activeEmergency;
    if (emergency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: const Center(child: Text('No active emergency')),
      );
    }
    final routePoints = parseRoutePolyline(emergency.routePolyline);
    final steps = emergency.routeSteps;
    final destLat = emergency.destLat;
    final destLon = emergency.destLon;
    final center = LatLng(
      _currentLat ?? destLat ?? 27.7172,
      _currentLon ?? destLon ?? 85.3240,
    );

    final markers = <Marker>[];
    if (_currentLat != null && _currentLon != null) {
      markers.add(Marker(
        point: LatLng(_currentLat!, _currentLon!),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 22),
        ),
      ));
    }
    if (destLat != null && destLon != null) {
      markers.add(Marker(
        point: LatLng(destLat, destLon),
        width: 48,
        height: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'DEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 32),
          ],
        ),
      ));
    }

    final polylines = <Polyline>[];
    if (routePoints.isNotEmpty) {
      polylines.add(Polyline(
        points: routePoints,
        color: Colors.blue.shade700,
        strokeWidth: 6,
      ));
    }

    final currentInstruction = (steps != null && _currentStepIndex < steps.length)
        ? steps[_currentStepIndex].instruction
        : null;
    final currentDistance = (steps != null && _currentStepIndex < steps.length)
        ? steps[_currentStepIndex].distanceM
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.emergencyRed,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emergency.destination,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'ETA ${formatEta(emergency.etaMinutes)} min',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_followMode ? Icons.my_location : Icons.location_searching),
            tooltip: _followMode ? 'Following' : 'Re-center',
            onPressed: () {
              setState(() => _followMode = !_followMode);
              if (_followMode) _panToCurrent();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              minZoom: 12,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ambulance.coordination',
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add,
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, math.min(z + 1, 18));
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, math.max(z - 1, 12));
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.fit_screen,
                  onPressed: _fitToRoute,
                ),
              ],
            ),
          ),
          if (currentInstruction != null)
            Positioned(
              top: 12,
              left: 12,
              right: 64,
              child: Card(
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_currentStepIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatInstruction(currentInstruction),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (currentDistance != null)
                              Text(
                                '${currentDistance.round()} m',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(steps),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(List<RouteStepModel>? steps) {
    final totalSteps = steps?.length ?? 0;
    final completedSteps = _currentStepIndex;
    final remaining = totalSteps - completedSteps;

    return GestureDetector(
      onTap: () => setState(() => _showSteps = !_showSteps),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showSteps ? 320 : 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: _showSteps
                  ? _buildStepsList(steps)
                  : _buildCompactInfo(remaining, totalSteps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(int remaining, int totalSteps) {
    final emergency = context.watch<EmergencyProvider>().activeEmergency;
    final eta = emergency?.etaMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.navigation, color: Colors.blue.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ETA ${formatEta(eta)} min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '$remaining steps remaining',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(
            _showSteps ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(List<RouteStepModel>? steps) {
    if (steps == null || steps.isEmpty) {
      return const Center(child: Text('No directions available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final s = steps[i];
        final isCurrent = i == _currentStepIndex;
        final isPast = i < _currentStepIndex;
        return ListTile(
          dense: true,
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.green
                  : isCurrent
                      ? Colors.blue.shade700
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isPast
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          title: Text(
            _formatInstruction(s.instruction),
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isPast ? Colors.grey : null,
              decoration: isPast ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${s.distanceM.round()} m'),
        );
      },
    );
  }

  String _formatInstruction(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Continue';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
