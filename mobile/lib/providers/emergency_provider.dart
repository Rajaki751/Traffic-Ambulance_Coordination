import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_model.dart';
import '../models/trip_history_item.dart';
import '../services/ai_service.dart';
import '../services/emergency_service.dart';
import '../services/gps_service.dart';

class EmergencyProvider extends ChangeNotifier {
  final EmergencyService _emergencyService;
  final GpsTrackingService _gpsService;
  final AiService _aiService;

  EmergencyModel? _activeEmergency;
  IncidentPrediction? _lastPrediction;
  List<TripHistoryItem> _history = [];
  bool _loading = false;
  String? _error;

  EmergencyProvider(
    this._emergencyService,
    this._gpsService,
    this._aiService,
  );

  EmergencyModel? get activeEmergency => _activeEmergency;
  IncidentPrediction? get lastPrediction => _lastPrediction;
  List<TripHistoryItem> get history => _history;
  bool get isEmergencyActive => _activeEmergency?.status == 'active';
  bool get loading => _loading;
  String? get error => _error;

  Future<IncidentPrediction?> previewAiPrediction({
    String incidentType = 'general',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final hasPermission = await _gpsService.requestPermission();
      if (!hasPermission) {
        _error = 'Location permission required for AI prediction';
        _loading = false;
        notifyListeners();
        return null;
      }
      final pos = await _gpsService.getCurrentPosition();
      _lastPrediction = await _aiService.predictIncident(
        callerLat: pos.latitude,
        callerLon: pos.longitude,
        incidentType: incidentType,
      );
      _loading = false;
      notifyListeners();
      return _lastPrediction;
    } catch (e) {
      _error = 'AI prediction failed. Check server connection.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> activateEmergency({
    required String destination,
    bool useAiPrediction = true,
    String incidentType = 'general',
    double? destLat,
    double? destLon,
    double? callerLat,
    double? callerLon,
    String routePreference = 'fastest',
    String? hospitalName,
    double? hospitalLatitude,
    double? hospitalLongitude,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final hasPermission = await _gpsService.requestPermission();
      if (!hasPermission) {
        _error = 'Location permission required';
        _loading = false;
        notifyListeners();
        return false;
      }
      final pos = await _gpsService.getCurrentPosition();
      _activeEmergency = await _emergencyService.activate(
        destination: destination,
        currentLat: pos.latitude,
        currentLon: pos.longitude,
        useAiPrediction: useAiPrediction,
        incidentType: incidentType,
        callerLat: callerLat ?? pos.latitude,
        callerLon: callerLon ?? pos.longitude,
        destLat: destLat,
        destLon: destLon,
        routePreference: routePreference,
        hospitalName: hospitalName,
        hospitalLatitude: hospitalLatitude,
        hospitalLongitude: hospitalLongitude,
      );
      _gpsService.startTracking(_activeEmergency!.id);
      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        _error = detail['detail'].toString();
      } else {
        _error = 'Failed to activate emergency. Check server connection.';
      }
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to activate emergency';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restoreActiveSession() async {
    _activeEmergency = await _emergencyService.getCurrentSession();
    notifyListeners();
  }

  Future<void> refreshActiveEmergency() async {
    final session = await _emergencyService.getCurrentSession();
    if (session != null) {
      _activeEmergency = session;
      notifyListeners();
    }
  }

  Future<void> endEmergency() async {
    if (_activeEmergency == null) return;
    _loading = true;
    notifyListeners();
    try {
      await _emergencyService.endSession(_activeEmergency!.id);
      _gpsService.stopTracking();
      _activeEmergency = null;
      _lastPrediction = null;
    } catch (e) {
      _error = 'Failed to end emergency: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> updateTripStage(String stage) async {
    if (_activeEmergency == null) return;
    _loading = true;
    notifyListeners();
    try {
      double? lat;
      double? lon;
      try {
        final pos = await _gpsService.getCurrentPosition();
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (_) {}
      _activeEmergency = await _emergencyService.updateTripStage(
        _activeEmergency!.id,
        stage,
        currentLat: lat,
        currentLon: lon,
      );
    } catch (e) {
      _error = 'Failed to update trip stage: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _loading = true;
    notifyListeners();
    try {
      _history = await _emergencyService.getDriverHistory();
    } catch (e) {
      _error = 'Failed to load history: $e';
    }
    _loading = false;
    notifyListeners();
  }
}
