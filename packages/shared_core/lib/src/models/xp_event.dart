/// Cross-app XP event for synchronizing gamification data between apps.
class XpEvent {
  const XpEvent({
    required this.id,
    required this.source,
    required this.eventType,
    required this.xpAmount,
    required this.durationMinutes,
    required this.timestamp,
    this.metadata,
  });

  /// Unique event ID.
  final String id;

  /// Which app generated this event: 'flowforge' or 'ai_tutor'.
  final String source;

  /// Type of event: 'focus_complete', 'task_done', 'quiz_passed', 'study_session'.
  final String eventType;

  /// XP earned from this event.
  final int xpAmount;

  /// Duration of the activity in minutes.
  final int durationMinutes;

  /// When this event occurred.
  final DateTime timestamp;

  /// Source-specific details.
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'event_type': eventType,
      'xp_amount': xpAmount,
      'duration_minutes': durationMinutes,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory XpEvent.fromJson(Map<String, dynamic> json) {
    return XpEvent(
      id: json['id'] as String,
      source: json['source'] as String,
      eventType: json['event_type'] as String,
      xpAmount: json['xp_amount'] as int,
      durationMinutes: json['duration_minutes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
