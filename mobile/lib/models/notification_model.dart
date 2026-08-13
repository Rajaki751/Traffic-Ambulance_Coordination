class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final bool isAcknowledged;
  final int? emergencySessionId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.isAcknowledged,
    this.emergencySessionId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      isAcknowledged: json['is_acknowledged'] ?? false,
      emergencySessionId: json['emergency_session_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
