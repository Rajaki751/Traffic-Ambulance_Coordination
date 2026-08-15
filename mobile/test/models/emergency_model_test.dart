import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/emergency_model.dart';

void main() {
  group('EmergencyModel Unit Tests', () {
    test('fromJson parses complete active session', () {
      final json = {
        'id': 12,
        'ambulance_id': 3,
        'destination': 'Norvic International Hospital',
        'dest_latitude': 27.6915,
        'dest_longitude': 85.3188,
        'status': 'active',
        'route_polyline': '[[27.70, 85.31], [27.69, 85.32]]',
        'eta_minutes': 8.5,
        'use_ai_prediction': true,
        'incident_type': 'cardiac',
        'prediction_confidence': 0.88,
        'traffic_factor': 1.25,
        'trip_stage': 'en_route',
        'patient_name': 'Gita Rai',
        'patient_contact': '9841000000',
        'priority_level': 'high',
        'hospital_name': 'Norvic Hospital',
      };

      final model = EmergencyModel.fromJson(json);

      expect(model.id, 12);
      expect(model.ambulanceId, 3);
      expect(model.destination, 'Norvic International Hospital');
      expect(model.destLat, 27.6915);
      expect(model.destLon, 85.3188);
      expect(model.status, 'active');
      expect(model.etaMinutes, 8.5);
      expect(model.useAiPrediction, isTrue);
      expect(model.incidentType, 'cardiac');
      expect(model.predictionConfidence, 0.88);
      expect(model.trafficFactor, 1.25);
      expect(model.tripStage, 'en_route');
      expect(model.patientName, 'Gita Rai');
      expect(model.priorityLevel, 'high');
      expect(model.hospitalName, 'Norvic Hospital');
    });

    test('copyWith properly updates fields', () {
      final initial = EmergencyModel(
        id: 1,
        ambulanceId: 2,
        destination: 'Patan Hospital',
        status: 'active',
        tripStage: 'en_route',
      );

      final updated = initial.copyWith(
        tripStage: 'arrived_hospital',
        status: 'completed',
      );

      expect(updated.id, 1);
      expect(updated.ambulanceId, 2);
      expect(updated.destination, 'Patan Hospital');
      expect(updated.tripStage, 'arrived_hospital');
      expect(updated.status, 'completed');
    });
  });
}
