/// API and app constants.
class AppConstants {
  /// Compile-time override: `flutter run --dart-define=API_BASE_URL=http://...`
  static const String compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Emulator default. Physical phones should set server URL on the login screen.
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000';

  static String get defaultBaseUrl =>
      compileTimeBaseUrl.isNotEmpty ? compileTimeBaseUrl : emulatorBaseUrl;

  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:8000',
  );

  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';

  static const Duration gpsInterval = Duration(seconds: 5);
}
