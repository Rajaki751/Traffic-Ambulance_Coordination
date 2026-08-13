import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class GpsTrackingService {
  final ApiService _api;
  StreamSubscription<Position>? _subscription;
  int? _sessionId;
  final _positionController = StreamController<Position>.broadcast();

  GpsTrackingService(this._api);

  Stream<Position> get positionStream => _positionController.stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void startTracking(int emergencySessionId) {
    _sessionId = emergencySessionId;
    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _positionController.add(position);
      _sendUpdate(position);
    });
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _sessionId = null;
  }

  Future<void> _sendUpdate(Position position) async {
    if (_sessionId == null) return;
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

  Future<Position> getCurrentPosition() =>
      Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ));
}
