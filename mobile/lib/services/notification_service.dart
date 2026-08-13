import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationApiService {
  final ApiService _api;
  NotificationApiService(this._api);

  Future<List<NotificationModel>> fetchNotifications({bool unreadOnly = false}) async {
    final res = await _api.get('/api/v1/notifications/', query: {
      'unread_only': unreadOnly,
    });
    return (res.data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<List<NotificationModel>> fetchDriverNotifications({
    bool unreadOnly = false,
  }) async {
    final res = await _api.get('/api/v1/notifications/driver', query: {
      'unread_only': unreadOnly,
    });
    return (res.data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<void> acknowledge(int notificationId) async {
    await _api.post('/api/v1/notifications/acknowledge', data: {
      'notification_id': notificationId,
    });
  }

  Future<void> markRead(int notificationId) async {
    await _api.patch('/api/v1/notifications/$notificationId/read');
  }

  Future<void> sendToDriver({
    required int emergencySessionId,
    required String title,
    required String message,
  }) async {
    await _api.post('/api/v1/notifications/send-to-driver', data: {
      'emergency_session_id': emergencySessionId,
      'title': title,
      'message': message,
    });
  }
}
