import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/trip_history_item.dart';

void main() {
  group('TripHistoryItem Unit Tests', () {
    test('fromJson parses complete trip history record', () {
      final json = {
        'id': 101,
        'destination': 'Bir Hospital Emergency Ward',
        'incident_type': 'accident',
        'priority_level': 'critical',
        'status': 'completed',
        'started_at': '2026-08-15T10:00:00.000Z',
        'ended_at': '2026-08-15T10:14:30.000Z',
        'eta_minutes': 12.0,
      };

      final item = TripHistoryItem.fromJson(json);

      expect(item.id, 101);
      expect(item.destination, 'Bir Hospital Emergency Ward');
      expect(item.incidentType, 'accident');
      expect(item.priorityLevel, 'critical');
      expect(item.status, 'completed');
      expect(item.startedAt.hour, 10);
      expect(item.endedAt?.minute, 14);
      expect(item.etaMinutes, 12.0);
    });

    test('fromJson handles active or unfinished trip without ended_at', () {
      final json = {
        'id': 102,
        'destination': 'Civil Service Hospital',
        'status': 'active',
        'started_at': '2026-08-15T11:00:00.000Z',
      };

      final item = TripHistoryItem.fromJson(json);

      expect(item.id, 102);
      expect(item.endedAt, isNull);
      expect(item.incidentType, isNull);
      expect(item.status, 'active');
    });
  });
}
