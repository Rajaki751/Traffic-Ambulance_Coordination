import 'api_service.dart';

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final String placeType;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.placeType,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      displayName: json['display_name'] as String? ?? '',
      placeType: json['place_type'] as String? ?? 'unknown',
    );
  }
}

class GeocodingService {
  final ApiService _api;
  GeocodingService(this._api);

  Future<List<GeocodingResult>> search(String query, {double? lat, double? lon}) async {
    final params = <String, dynamic>{'q': query, 'limit': 5};
    if (lat != null) params['lat'] = lat;
    if (lon != null) params['lon'] = lon;
    final res = await _api.get('/api/v1/directions/geocode', query: params);
    final data = res.data as List;
    return data
        .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
