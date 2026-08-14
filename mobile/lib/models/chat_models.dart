class ChatParticipant {
  final int userId;
  final String name;
  final String role;

  ChatParticipant({
    required this.userId,
    required this.name,
    required this.role,
  });

  bool get isDriver => role == 'driver';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'],
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class ChatSessionSummary {
  final int emergencySessionId;
  final String vehicleNumber;
  final String destination;
  final String status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<ChatParticipant> participants;

  ChatSessionSummary({
    required this.emergencySessionId,
    required this.vehicleNumber,
    required this.destination,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participants = const [],
  });

  List<ChatParticipant> get drivers =>
      participants.where((p) => p.isDriver).toList();

  List<ChatParticipant> get officers =>
      participants.where((p) => !p.isDriver).toList();

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
      participants: (json['participants'] as List? ?? [])
          .map((e) => ChatParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatMessageModel {
  final int id;
  final int emergencySessionId;
  final int senderUserId;
  final String senderName;
  final String senderRole;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.emergencySessionId,
    required this.senderUserId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  bool get isFromDriver => senderRole == 'driver';

  bool get isLocation => latitude != null && longitude != null;

  String get initials {
    final parts = senderName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      emergencySessionId: json['emergency_session_id'],
      senderUserId: json['sender_user_id'],
      senderName: json['sender_name'] ?? '',
      senderRole: json['sender_role'] ?? '',
      message: json['message'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
