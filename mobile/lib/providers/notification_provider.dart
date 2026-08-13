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

  Future<void> acknowledge(int id) async {
    await _service.acknowledge(id);
    await load();
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
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
}
