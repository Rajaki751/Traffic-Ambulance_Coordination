class LiveAmbulanceModel {
  final int ambulanceId;
  final String vehicleNumber;
  final int emergencySessionId;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final String destination;
  final double? destLat;
  final double? destLon;
  final String? routePolyline;
  final double? etaMinutes;
  final String status;

  LiveAmbulanceModel({
    required this.ambulanceId,
    required this.vehicleNumber,
    required this.emergencySessionId,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    required this.destination,
    this.destLat,
    this.destLon,
    this.routePolyline,
    this.etaMinutes,
    required this.status,
  });

  factory LiveAmbulanceModel.fromJson(Map<String, dynamic> json) {
    return LiveAmbulanceModel(
      ambulanceId: json['ambulance_id'],
      vehicleNumber: json['vehicle_number'] ?? 'AMB',
      emergencySessionId: json['emergency_session_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: json['speed_kmh']?.toDouble(),
      destination: json['destination'] ?? '',
      destLat: json['dest_latitude']?.toDouble(),
      destLon: json['dest_longitude']?.toDouble(),
      routePolyline: json['route_polyline'] as String?,
      etaMinutes: json['eta_minutes']?.toDouble(),
      status: json['status'] ?? 'emergency',
    );
  }
}
