import 'api_service.dart';

class JunctionPoint {
  final String name;
  final double lat;
  final double lon;

  JunctionPoint({
    required this.name,
    required this.lat,
    required this.lon,
  });

  factory JunctionPoint.fromJson(Map<String, dynamic> json) {
    return JunctionPoint(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}

class JunctionClearanceRecord {
  final int id;
  final String junctionName;
  final double latitude;
  final double longitude;
  final String? notes;
  final String clearedAt;

  JunctionClearanceRecord({
    required this.id,
    required this.junctionName,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.clearedAt,
  });

  factory JunctionClearanceRecord.fromJson(Map<String, dynamic> json) {
    return JunctionClearanceRecord(
      id: json['id'] as int,
      junctionName: json['junction_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
      clearedAt: json['cleared_at'] as String? ?? '',
    );
  }
}

class JunctionService {
  final ApiService _api;
  JunctionService(this._api);

  Future<List<JunctionPoint>> getKathmanduJunctions() async {
    final res = await _api.get('/api/v1/junctions/kathmandu');
    final data =
        res.data is List ? res.data as List : (res.data['value'] as List);
    return data
        .map((e) => JunctionPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markCleared({
    required String junctionName,
    required double latitude,
    required double longitude,
    int? emergencySessionId,
    String? notes,
  }) async {
    await _api.post('/api/v1/junctions/clear', data: {
      'junction_name': junctionName,
      'latitude': latitude,
      'longitude': longitude,
      'emergency_session_id': emergencySessionId,
      'notes': notes,
    });
  }

  Future<List<JunctionClearanceRecord>> getMyClearanceHistory(
      {int limit = 50}) async {
    final res =
        await _api.get('/api/v1/junctions/history', query: {'limit': limit});
    return (res.data as List)
        .map((e) => JunctionClearanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
