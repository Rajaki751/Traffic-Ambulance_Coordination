import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/notification_model.dart';

void main() {
  group('NotificationModel Unit Tests', () {
    test('fromJson parses emergency alert notification', () {
      final json = {
        'id': 7,
        'title': 'Emergency Alert',
        'message': 'Ambulance BA-123 heading to Bir Hospital.',
        'notification_type': 'emergency_alert',
        'is_read': false,
        'is_acknowledged': true,
        'acknowledgment': 'accept',
        'emergency_session_id': 14,
        'created_at': '2026-08-15T12:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 7);
      expect(notif.title, 'Emergency Alert');
      expect(notif.notificationType, 'emergency_alert');
      expect(notif.isRead, isFalse);
      expect(notif.isAcknowledged, isTrue);
      expect(notif.acknowledgment, 'accept');
      expect(notif.emergencySessionId, 14);
      expect(notif.createdAt.year, 2026);
    });
  });
}
