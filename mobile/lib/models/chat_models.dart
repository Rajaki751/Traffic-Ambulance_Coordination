class ChatSessionSummary {
  final int emergencySessionId;
  final String vehicleNumber;
  final String destination;
  final String status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatSessionSummary({
    required this.emergencySessionId,
    required this.vehicleNumber,
    required this.destination,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      emergencySessionId: json['emergency_session_id'],
      vehicleNumber: json['vehicle_number'] ?? '',
      destination: json['destination'] ?? '',
      status: json['status'] ?? '',
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatMessageModel {
  final int id;
  final int emergencySessionId;
  final int senderUserId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.emergencySessionId,
    required this.senderUserId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      emergencySessionId: json['emergency_session_id'],
      senderUserId: json['sender_user_id'],
      senderName: json['sender_name'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
