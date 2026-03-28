import 'enums.dart';

class StudySession {
  const StudySession({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.startedAt,
    this.endedAt,
    this.inkStrokeCount = 0,
    this.aiInteractionCount = 0,
  });

  final String id;
  final StudyTargetType targetType;
  final String targetId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int inkStrokeCount;
  final int aiInteractionCount;

  int get durationMinutes {
    if (endedAt == null) return 0;
    return endedAt!.difference(startedAt).inMinutes;
  }

  StudySession copyWith({
    String? id,
    StudyTargetType? targetType,
    String? targetId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? inkStrokeCount,
    int? aiInteractionCount,
  }) {
    return StudySession(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      inkStrokeCount: inkStrokeCount ?? this.inkStrokeCount,
      aiInteractionCount: aiInteractionCount ?? this.aiInteractionCount,
    );
  }
}

class TopicMastery {
  const TopicMastery({
    required this.id,
    required this.topic,
    required this.confidenceScore,
    this.evidenceCount = 0,
    required this.updatedAt,
  });

  final String id;
  final String topic;
  final double confidenceScore;
  final int evidenceCount;
  final DateTime updatedAt;

  TopicMastery copyWith({
    String? id,
    String? topic,
    double? confidenceScore,
    int? evidenceCount,
    DateTime? updatedAt,
  }) {
    return TopicMastery(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
