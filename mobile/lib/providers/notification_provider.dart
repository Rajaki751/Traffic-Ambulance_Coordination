import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _service;
  List<NotificationModel> _notifications = [];
  bool _loading = false;
  bool _isDriverMode = false;

  NotificationProvider(this._service);

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> setMode({required bool driver}) async {
    _isDriverMode = driver;
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _notifications = _isDriverMode
          ? await _service.fetchDriverNotifications()
          : await _service.fetchNotifications();
    } catch (e) {
      _notifications = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> acknowledge(int id, {String? action}) async {
    await _service.acknowledge(id, action: action);
    await load();
  }

  Future<void> markRead(int id) async {
    try {
      await _service.markRead(id);
      await load();
    } catch (_) {
      // read may fail (e.g. officer-only endpoint on a driver); keep the list as-is
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    await load();
  }

  Future<void> sendToDriver({
    required int emergencySessionId,
    required String title,
    required String message,
  }) async {
    await _service.sendToDriver(
      emergencySessionId: emergencySessionId,
      title: title,
      message: message,
    );
  }

  Future<void> replyToOfficer({
    required int emergencySessionId,
    required String message,
  }) async {
    await _service.replyToOfficer(
      emergencySessionId: emergencySessionId,
      message: message,
    );
    await load();
  }
}
