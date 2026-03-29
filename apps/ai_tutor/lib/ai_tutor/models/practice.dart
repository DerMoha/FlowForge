import 'dart:convert';
import 'enums.dart';

class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.topic,
    this.sourceType,
    this.sourceId,
    this.parentSessionId,
    this.conversationId,
    required this.depth,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String topic;
  final PracticeSourceType? sourceType;
  final String? sourceId;
  final String? parentSessionId;
  final String? conversationId;
  final int depth;
  final PracticeSessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  PracticeSession copyWith({
    String? id,
    String? topic,
    PracticeSourceType? sourceType,
    String? sourceId,
    String? parentSessionId,
    String? conversationId,
    int? depth,
    PracticeSessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      parentSessionId: parentSessionId ?? this.parentSessionId,
      conversationId: conversationId ?? this.conversationId,
      depth: depth ?? this.depth,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class PracticeCell {
  const PracticeCell({
    required this.id,
    required this.sessionId,
    required this.cellIndex,
    required this.cellType,
    required this.content,
    required this.metadata,
    required this.cellStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final int cellIndex;
  final PracticeCellType cellType;
  final String content;
  final Map<String, dynamic> metadata;
  final CellStatus cellStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  PracticeCell copyWith({
    String? id,
    String? sessionId,
    int? cellIndex,
    PracticeCellType? cellType,
    String? content,
    Map<String, dynamic>? metadata,
    CellStatus? cellStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeCell(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      cellIndex: cellIndex ?? this.cellIndex,
      cellType: cellType ?? this.cellType,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      cellStatus: cellStatus ?? this.cellStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convenience getter for action type in feedback cells.
  PracticeAction? get action {
    final raw = metadata['action'] as String?;
    if (raw == null) return null;
    try {
      return PracticeAction.values.firstWhere((a) => a.name == raw);
    } catch (_) {
      return null;
    }
  }

  /// Convenience getter for sub-task topic in feedback cells.
  String? get subtaskTopic => metadata['subtask_topic'] as String?;

  /// Convenience getter for score in feedback cells.
  double? get score {
    final v = metadata['score'];
    if (v is num) return v.toDouble();
    return null;
  }

  static Map<String, dynamic> parseMetadata(String raw) {
    if (raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
