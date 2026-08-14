import '../models/emergency_model.dart';
import '../models/trip_history_item.dart';
import 'api_service.dart';

class EmergencyService {
  final ApiService _api;
  EmergencyService(this._api);

  Future<EmergencyModel> activate({
    required String destination,
    required double currentLat,
    required double currentLon,
    bool useAiPrediction = true,
    String incidentType = 'general',
    double? callerLat,
    double? callerLon,
    double? destLat,
    double? destLon,
    String routePreference = 'fastest',
    String? hospitalName,
    double? hospitalLatitude,
    double? hospitalLongitude,
  }) async {
    final data = <String, dynamic>{
      'destination': destination,
      'current_latitude': currentLat,
      'current_longitude': currentLon,
      'use_ai_prediction': useAiPrediction,
      'incident_type': incidentType,
      'route_preference': routePreference,
    };
    if (callerLat != null) data['caller_latitude'] = callerLat;
    if (callerLon != null) data['caller_longitude'] = callerLon;
    if (!useAiPrediction && destLat != null && destLon != null) {
      data['dest_latitude'] = destLat;
      data['dest_longitude'] = destLon;
    }
    if (hospitalName != null) data['hospital_name'] = hospitalName;
    if (hospitalLatitude != null) data['hospital_latitude'] = hospitalLatitude;
    if (hospitalLongitude != null) {
      data['hospital_longitude'] = hospitalLongitude;
    }

    final res = await _api.post('/api/v1/emergencies/activate', data: data);
    return EmergencyModel.fromJson(res.data);
  }

  Future<EmergencyModel> endSession(int sessionId) async {
    final res = await _api.post('/api/v1/emergencies/$sessionId/end', data: {
      'reason': 'completed',
    });
    return EmergencyModel.fromJson(res.data);
  }

  Future<EmergencyModel?> getCurrentSession() async {
    try {
      final res = await _api.get('/api/v1/emergencies/current');
      return EmergencyModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<EmergencyModel> updateTripStage(
    int sessionId,
    String tripStage, {
    double? currentLat,
    double? currentLon,
  }) async {
    final data = <String, dynamic>{
      'trip_stage': tripStage,
    };
    if (currentLat != null) data['current_latitude'] = currentLat;
    if (currentLon != null) data['current_longitude'] = currentLon;
    final res = await _api.patch('/api/v1/emergencies/$sessionId/trip-stage',
        data: data);
    return EmergencyModel.fromJson(res.data);
  }

  Future<List<TripHistoryItem>> getDriverHistory({int limit = 30}) async {
    final res = await _api.get('/api/v1/emergencies/history/driver', query: {
      'limit': limit,
    });
    return (res.data as List)
        .map((e) => TripHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
