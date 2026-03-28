import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/progress.dart' as model;
import '../database/ai_tutor_database.dart';

class ProgressRepository {
  ProgressRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  // ── Study Sessions ──

  Future<List<model.StudySession>> getAllSessions() async {
    final rows = await (_db.select(_db.studySessions)
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
    return rows.map(_mapSession).toList();
  }

  Future<model.StudySession> startSession({
    required StudyTargetType targetType,
    required String targetId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.studySessions).insert(
      StudySessionsCompanion.insert(
        id: id,
        targetType: targetType.name,
        targetId: targetId,
        startedAt: now,
      ),
    );
    return model.StudySession(
      id: id,
      targetType: targetType,
      targetId: targetId,
      startedAt: now,
    );
  }

  Future<void> endSession(
    String sessionId, {
    int inkStrokeCount = 0,
    int aiInteractionCount = 0,
  }) async {
    await (_db.update(_db.studySessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(StudySessionsCompanion(
      endedAt: Value(DateTime.now()),
      inkStrokeCount: Value(inkStrokeCount),
      aiInteractionCount: Value(aiInteractionCount),
    ));
  }

  // ── Topic Mastery ──

  Future<List<model.TopicMastery>> getAllMasteries() async {
    final rows = await (_db.select(_db.topicMasteries)
          ..orderBy([(m) => OrderingTerm.desc(m.confidenceScore)]))
        .get();
    return rows.map(_mapMastery).toList();
  }

  Future<void> upsertMastery({
    required String topic,
    required double confidenceScore,
    required int evidenceCount,
  }) async {
    // Try to find existing
    final existing = await (_db.select(_db.topicMasteries)
          ..where((m) => m.topic.equals(topic)))
        .getSingleOrNull();

    final id = existing?.id ?? _uuid.v4();
    await _db.into(_db.topicMasteries).insertOnConflictUpdate(
      TopicMasteriesCompanion.insert(
        id: id,
        topic: topic,
        confidenceScore: confidenceScore,
        evidenceCount: Value(evidenceCount),
        updatedAt: DateTime.now(),
      ),
    );
  }

  model.StudySession _mapSession(StudySession row) {
    return model.StudySession(
      id: row.id,
      targetType: StudyTargetType.values.firstWhere(
        (e) => e.name == row.targetType,
      ),
      targetId: row.targetId,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      inkStrokeCount: row.inkStrokeCount,
      aiInteractionCount: row.aiInteractionCount,
    );
  }

  model.TopicMastery _mapMastery(TopicMastery row) {
    return model.TopicMastery(
      id: row.id,
      topic: row.topic,
      confidenceScore: row.confidenceScore,
      evidenceCount: row.evidenceCount,
      updatedAt: row.updatedAt,
    );
  }
}
