class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final bool isAcknowledged;
  final String? acknowledgment;
  final int? emergencySessionId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.notificationType = 'emergency_alert',
    required this.isRead,
    required this.isAcknowledged,
    this.acknowledgment,
    this.emergencySessionId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      notificationType: json['notification_type'] ?? 'emergency_alert',
      isRead: json['is_read'] ?? false,
      isAcknowledged: json['is_acknowledged'] ?? false,
      acknowledgment: json['acknowledgment'],
      emergencySessionId: json['emergency_session_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
