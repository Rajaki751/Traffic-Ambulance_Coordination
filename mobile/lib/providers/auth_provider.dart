import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/live_service.dart';
import '../services/server_config_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ServerConfigService _serverConfig;
  final LiveService _liveService;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._authService, this._serverConfig, this._liveService);

  Future<void> configureServer(String url) async {
    await _serverConfig.saveApiBaseUrl(url);
    _authService.setBaseUrl(await _serverConfig.getApiBaseUrl());
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _user = await _authService.autoLogin();
    _loading = false;
    notifyListeners();
    if (_user != null) _connectLive();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authService.login(email, password);
      if (user.role == UserRole.admin) {
        await _authService.logout();
        _error =
            'Admin accounts use the web dashboard. Use driver or officer credentials here.';
        _loading = false;
        notifyListeners();
        return false;
      }
      _user = user;
      _loading = false;
      notifyListeners();
      _connectLive();
      return true;
    } on DioException catch (e) {
      _error = _messageForDioError(e);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Check credentials and try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? vehicleNumber,
    String? assignedZone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        vehicleNumber: vehicleNumber,
        assignedZone: assignedZone,
      );
      _user = user;
      _loading = false;
      notifyListeners();
      _connectLive();
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        _error = detail['detail'].toString();
      } else {
        _error = 'Registration failed. Please try again.';
      }
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Check server connection.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  String _messageForDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      final baseUrl = _authService.baseUrl;
      if (baseUrl.contains('10.0.2.2')) {
        return 'Cannot reach the server at $baseUrl. '
            'On a physical phone, set Server URL to your PC IP, e.g. '
            'http://192.168.18.88:8000';
      }
      return 'Cannot reach the server at $baseUrl. '
          'Check the Server URL, ensure the backend is running, and use the same Wi‑Fi.';
    }
    if (e.response?.statusCode == 401) {
      return 'Invalid email or password.';
    }
    return 'Login failed (${e.response?.statusCode ?? e.type.name}).';
  }

  Future<void> logout() async {
    _liveService.disconnect();
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _connectLive() async {
    final user = _user;
    if (user == null || user.token == null) return;
    _liveService.connect(
      baseUrl: _authService.baseUrl,
      token: user.token!,
      channel: user.role.name,
    );

    // Register FCM token for push notifications
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _authService.registerFcmToken(fcmToken);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _authService.registerFcmToken(newToken);
      });
    } catch (e) {
      // Ignored if firebase fails to initialize or get token
    }
  }

  Future<bool> updateAmbulanceStatus(String status) async {
    try {
      await _authService.updateAmbulanceStatus(status);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateLocalName(String name) async {
    final user = _user;
    if (user == null) return;
    _user = UserModel(
      id: user.id,
      name: name,
      email: user.email,
      role: user.role,
      token: user.token,
    );
    await _authService.saveName(name);
    notifyListeners();
  }
}
