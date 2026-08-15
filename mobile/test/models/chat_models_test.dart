import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/chat_models.dart';

void main() {
  group('ChatModel Unit Tests', () {
    test('ChatMessageModel fromJson parses text and location coordinate', () {
      final json = {
        'id': 55,
        'emergency_session_id': 10,
        'sender_user_id': 3,
        'sender_name': 'Officer Arjun',
        'sender_role': 'officer',
        'message': 'Road blocked at Thapathali bridge',
        'latitude': 27.6930,
        'longitude': 85.3195,
        'created_at': '2026-08-15T12:30:00.000Z',
      };

      final msg = ChatMessageModel.fromJson(json);

      expect(msg.id, 55);
      expect(msg.emergencySessionId, 10);
      expect(msg.senderUserId, 3);
      expect(msg.senderName, 'Officer Arjun');
      expect(msg.senderRole, 'officer');
      expect(msg.message, 'Road blocked at Thapathali bridge');
      expect(msg.isLocation, isTrue);
      expect(msg.latitude, 27.6930);
      expect(msg.longitude, 85.3195);
      expect(msg.isFromDriver, isFalse);
      expect(msg.initials, 'OA');
    });

    test('ChatSessionSummary fromJson parses session data', () {
      final json = {
        'emergency_session_id': 10,
        'destination': 'Civil Hospital',
        'vehicle_number': 'BA-999',
        'status': 'active',
        'last_message': 'Clear now',
        'last_message_at': '2026-08-15T12:35:00.000Z',
        'unread_count': 3,
        'participants': [
          {'user_id': 1, 'name': 'Driver Ramesh', 'role': 'driver'},
          {'user_id': 2, 'name': 'Officer Arjun', 'role': 'officer'},
        ],
      };

      final session = ChatSessionSummary.fromJson(json);

      expect(session.emergencySessionId, 10);
      expect(session.destination, 'Civil Hospital');
      expect(session.vehicleNumber, 'BA-999');
      expect(session.unreadCount, 3);
      expect(session.lastMessage, 'Clear now');
      expect(session.drivers.length, 1);
      expect(session.officers.length, 1);
      expect(session.drivers.first.name, 'Driver Ramesh');
    });
  });
}
