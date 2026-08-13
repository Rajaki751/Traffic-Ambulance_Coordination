import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/auth_widgets.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String? label;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}

class LocationPickScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;

  const LocationPickScreen({
    super.key,
    required this.initialLat,
    required this.initialLon,
  });

  @override
  State<LocationPickScreen> createState() => _LocationPickScreenState();
}

class _LocationPickScreenState extends State<LocationPickScreen> {
  final _mapController = MapController();
  final _text = GoogleFonts.inter();
  GeocodingService? _geocoding;
  Timer? _reverseDebounce;
  String? _label;
  bool _resolving = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _geocoding = GeocodingService(context.read<ApiService?>() ?? ApiService());
    _label = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleReverse(widget.initialLat, widget.initialLon, delay: 900);
    });
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) return;
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      if (!mounted || !_mapReady) return;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom < 15 ? 16 : _mapController.camera.zoom,
      );
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || !_mapReady) return;
    _scheduleReverse(camera.center.latitude, camera.center.longitude);
  }

  void _scheduleReverse(double lat, double lon, {int delay = 450}) {
    _reverseDebounce?.cancel();
    setState(() => _resolving = true);
    _reverseDebounce = Timer(Duration(milliseconds: delay), () {
      _reverse(lat, lon);
    });
  }

  Future<void> _reverse(double lat, double lon) async {
    String? name;
    try {
      name = await _geocoding?.reverse(lat, lon);
    } catch (_) {
      name = null;
    }
    if (!mounted) return;
    setState(() {
      _label = (name == null || name.trim().isEmpty) ? null : name;
      _resolving = false;
    });
  }

  void _confirm() {
    final center = _mapController.camera.center;
    Navigator.pop(
      context,
      PickedLocation(
        latitude: center.latitude,
        longitude: center.longitude,
        label: _label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.initialLat, widget.initialLon);
    return Scaffold(
      backgroundColor: kAuthBg,
      appBar: AppBar(
        backgroundColor: kAuthCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Pick incident location',
          style: _text.copyWith(
            color: kAuthText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              minZoom: 10,
              maxZoom: 19,
              backgroundColor: kAuthBg,
              onPositionChanged: _onPositionChanged,
              onMapReady: () => _mapReady = true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ambulance_coordination',
              ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: kAuthCard.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: kAuthRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: Material(
              color: kAuthCard,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: IconButton(
                tooltip: 'My location',
                onPressed: _locate,
                icon: const Icon(Icons.my_location, color: kAuthRed, size: 22),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: kAuthCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(
                  top: BorderSide(color: kAuthBorder, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _resolving
                              ? Icons.hourglass_top_rounded
                              : Icons.place_outlined,
                          size: 16,
                          color: _resolving ? kAuthIcon : kAuthRedLink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resolving
                                ? 'Resolving place name…'
                                : (_label ?? 'Pinned point'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _text.copyWith(
                              color: kAuthText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Drag the map so the pin sits on the incident spot.',
                      style: _text.copyWith(
                        color: kAuthFaint,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAuthRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _confirm,
                        child: Text(
                          'Use this location',
                          style: _text.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}