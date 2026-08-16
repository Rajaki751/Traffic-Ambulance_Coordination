/// API and app constants.
class AppConstants {
  /// Compile-time override: `flutter run --dart-define=API_BASE_URL=http://...`
  static const String compileTimeBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  /// Production server URL
  static const String emulatorBaseUrl = 'https://sajiloroute-api.onrender.com';

  static String get defaultBaseUrl =>
      compileTimeBaseUrl.isNotEmpty ? compileTimeBaseUrl : emulatorBaseUrl;

  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://sajiloroute-api.onrender.com',
  );

  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';

  static const Duration gpsInterval = Duration(seconds: 5);
}
