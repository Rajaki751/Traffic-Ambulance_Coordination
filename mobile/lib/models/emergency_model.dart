class EmergencyModel {
  final int id;
  final int ambulanceId;
  final String destination;
  final double? destLat;
  final double? destLon;
  final String status;
  final String? routePolyline;
  final double? etaMinutes;
  final bool useAiPrediction;
  final String? incidentType;
  final double? predictionConfidence;
  final double? trafficFactor;
  final String? tripStage;
  final String? patientName;
  final String? patientContact;
  final String? priorityLevel;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? hospitalName;
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final List<RouteStepModel>? routeSteps;
  final List<List<double>>? routeCoordinates;
  final String? routePreference;

  EmergencyModel({
    required this.id,
    required this.ambulanceId,
    required this.destination,
    this.destLat,
    this.destLon,
    required this.status,
    this.routePolyline,
    this.etaMinutes,
    this.useAiPrediction = false,
    this.incidentType,
    this.predictionConfidence,
    this.trafficFactor,
    this.tripStage,
    this.patientName,
    this.patientContact,
    this.priorityLevel,
    this.pickupLatitude,
    this.pickupLongitude,
    this.hospitalName,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.routeSteps,
    this.routeCoordinates,
    this.routePreference,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id'],
      ambulanceId: json['ambulance_id'],
      destination: json['destination'],
      destLat: json['dest_latitude']?.toDouble(),
      destLon: json['dest_longitude']?.toDouble(),
      status: json['status'],
      routePolyline: json['route_polyline'],
      etaMinutes: json['eta_minutes']?.toDouble(),
      useAiPrediction: json['use_ai_prediction'] == true,
      incidentType: json['incident_type'] as String?,
      predictionConfidence: json['prediction_confidence']?.toDouble(),
      trafficFactor: json['traffic_factor']?.toDouble(),
      tripStage: json['trip_stage'] as String?,
      patientName: json['patient_name'] as String?,
      patientContact: json['patient_contact'] as String?,
      priorityLevel: json['priority_level'] as String?,
      pickupLatitude: json['pickup_latitude']?.toDouble(),
      pickupLongitude: json['pickup_longitude']?.toDouble(),
      hospitalName: json['hospital_name'] as String?,
      hospitalLatitude: json['hospital_latitude']?.toDouble(),
      hospitalLongitude: json['hospital_longitude']?.toDouble(),
      routeSteps: json['route_steps'] != null
          ? (json['route_steps'] as List)
              .map((e) => RouteStepModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      routeCoordinates: json['route_coordinates'] != null
          ? (json['route_coordinates'] as List)
              .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
              .toList()
          : null,
      routePreference: json['route_preference'] as String?,
    );
  }
}

class RouteStepModel {
  final String instruction;
  final double distanceM;
  final double durationS;

  RouteStepModel({required this.instruction, required this.distanceM, required this.durationS});

  factory RouteStepModel.fromJson(Map<String, dynamic> json) {
    return RouteStepModel(
      instruction: json['instruction'] as String? ?? '',
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0.0,
      durationS: (json['duration_s'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
