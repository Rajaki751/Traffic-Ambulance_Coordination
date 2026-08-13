import 'api_service.dart';

class IncidentPrediction {
  final double incidentLat;
  final double incidentLon;
  final double confidence;
  final String modelVersion;
  final double trafficFactor;
  final String trafficLabel;
  final String incidentType;

  IncidentPrediction({
    required this.incidentLat,
    required this.incidentLon,
    required this.confidence,
    required this.modelVersion,
    required this.trafficFactor,
    required this.trafficLabel,
    this.incidentType = 'general',
  });

  factory IncidentPrediction.fromJson(Map<String, dynamic> json) {
    return IncidentPrediction(
      incidentLat: (json['incident_latitude'] as num).toDouble(),
      incidentLon: (json['incident_longitude'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      modelVersion: json['model_version'] as String? ?? 'unknown',
      trafficFactor: (json['traffic_factor'] as num?)?.toDouble() ?? 1.0,
      trafficLabel: json['traffic_label'] as String? ?? '',
      incidentType: json['incident_type'] as String? ?? 'general',
    );
  }

  String get incidentDescription {
    switch (incidentType) {
      case 'cardiac':
        return 'Cardiac Emergency - Predicted location where the cardiac incident is most likely occurring based on caller position, time patterns, and historical data';
      case 'accident':
        return 'Traffic Accident - Predicted accident location based on caller report, road conditions, and historical incident data';
      case 'fire':
        return 'Fire Emergency - Predicted fire incident location based on caller position and environmental factors';
      case 'respiratory':
        return 'Respiratory Emergency - Predicted location of the respiratory emergency based on caller position and health patterns';
      case 'trauma':
        return 'Trauma Case - Predicted trauma incident location based on caller report and area incident history';
      default:
        return 'General Emergency - Predicted incident location based on caller position, time of day, traffic conditions, and historical emergency data';
    }
  }

  String get confidenceDescription {
    if (confidence >= 0.8) return 'High confidence - Strong match with historical patterns';
    if (confidence >= 0.5) return 'Moderate confidence - Some uncertainty in prediction';
    return 'Low confidence - Limited historical data for this area/type';
  }
}

class AiService {
  final ApiService _api;
  AiService(this._api);

  Future<IncidentPrediction> predictIncident({
    required double callerLat,
    required double callerLon,
    String incidentType = 'general',
  }) async {
    final res = await _api.post('/api/v1/ai/predict-incident', data: {
      'caller_latitude': callerLat,
      'caller_longitude': callerLon,
      'incident_type': incidentType,
    });
    final data = res.data as Map<String, dynamic>;
    data['incident_type'] = incidentType;
    return IncidentPrediction.fromJson(data);
  }
}
