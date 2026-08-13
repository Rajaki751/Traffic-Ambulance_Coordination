class TripHistoryItem {
  final int id;
  final String destination;
  final String? incidentType;
  final String? priorityLevel;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? etaMinutes;

  TripHistoryItem({
    required this.id,
    required this.destination,
    this.incidentType,
    this.priorityLevel,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.etaMinutes,
  });

  factory TripHistoryItem.fromJson(Map<String, dynamic> json) {
    return TripHistoryItem(
      id: json['id'] as int,
      destination: json['destination'] as String? ?? '',
      incidentType: json['incident_type'] as String?,
      priorityLevel: json['priority_level'] as String?,
      status: json['status'] as String? ?? 'unknown',
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      etaMinutes: json['eta_minutes'] != null ? (json['eta_minutes'] as num).toDouble() : null,
    );
  }
}
