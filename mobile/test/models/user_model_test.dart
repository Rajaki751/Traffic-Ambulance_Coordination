import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_coordination/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('fromJson correctly parses driver user and token', () {
      final json = {
        'user_id': 42,
        'name': 'Ram Bahadur',
        'email': 'ram@example.com',
        'role': 'driver',
        'access_token': 'test_token_123',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.name, 'Ram Bahadur');
      expect(user.email, 'ram@example.com');
      expect(user.role, UserRole.driver);
      expect(user.isDriver, isTrue);
      expect(user.isOfficer, isFalse);
      expect(user.token, 'test_token_123');
    });

    test('fromJson correctly parses officer user', () {
      final json = {
        'id': 101,
        'name': 'Sita Shrestha',
        'email': 'sita@example.com',
        'role': 'officer',
      };

      final user = UserModel.fromJson(json, token: 'custom_bearer');

      expect(user.id, 101);
      expect(user.name, 'Sita Shrestha');
      expect(user.role, UserRole.officer);
      expect(user.isOfficer, isTrue);
      expect(user.isDriver, isFalse);
      expect(user.token, 'custom_bearer');
    });

    test('fromJson defaults unknown role to admin', () {
      final json = {
        'id': 1,
        'name': 'Admin User',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, UserRole.admin);
      expect(user.isDriver, isFalse);
      expect(user.isOfficer, isFalse);
    });
  });
}
