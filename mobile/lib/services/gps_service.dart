import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class GpsTrackingService {
  final ApiService _api;
  StreamSubscription<Position>? _subscription;
  int? _sessionId;
  Future<void> _lastSend = Future.value();
  Position? _lastPosition;
  final _positionController = StreamController<Position>.broadcast();
  late final AppLifecycleListener _lifecycleListener;

  GpsTrackingService(this._api) {
    _lifecycleListener = AppLifecycleListener(
      onPause: pauseTracking,
      onResume: resumeTracking,
    );
  }

  Stream<Position> get positionStream => _positionController.stream;

  Position? get lastKnownPosition => _lastPosition;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // If permission is denied forever, open app settings so user can manually enable it
      await Geolocator.openAppSettings();
      // Optionally re-check after returning, but generally we return false and let them retry
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> startTracking(int emergencySessionId) async {
    final ok = await requestPermission();
    if (!ok) return false;
    _sessionId = emergencySessionId;
    _startStream();
    return true;
  }

  void _startStream() {
    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _positionController.add(position);
        _sendUpdate(position);
      },
      onError: (Object error) {
        debugPrint('GPS stream error: $error');
        _subscription?.cancel();
        _subscription = null;
      },
    );
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _sessionId = null;
  }

  void pauseTracking() {
    _subscription?.pause();
  }

  Future<void> resumeTracking() async {
    if (_sessionId == null) return;
    final ok = await requestPermission();
    if (!ok) {
      _subscription?.cancel();
      _subscription = null;
      _sessionId = null;
      return;
    }
    if (_subscription != null) {
      _subscription!.resume();
    } else {
      _startStream();
    }
  }

  void _sendUpdate(Position position) {
    if (_sessionId == null) return;
    _lastSend = _lastSend.then((_) => _doSend(position)).catchError((_) {});
  }

  Future<void> _doSend(Position position) async {
    try {
      await _api.post('/api/v1/gps/update', data: {
        'emergency_session_id': _sessionId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed_kmh': (position.speed * 3.6),
        'heading': position.heading,
      });
    } catch (_) {}
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Position?> bestPosition({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      final fresh = last != null &&
          DateTime.now().difference(last.timestamp).inMinutes < 5;
      if (fresh) return last;
    } catch (_) {}
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _lifecycleListener.dispose();
    stopTracking();
    _positionController.close();
  }
}
