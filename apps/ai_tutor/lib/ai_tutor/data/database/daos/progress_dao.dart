import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [StudySessions, TopicMasteries])
class ProgressDao extends DatabaseAccessor<AiTutorDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  // ── Study Sessions ──

  Future<List<StudySession>> getAllSessions() =>
      (select(studySessions)
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  Future<List<StudySession>> getSessionsForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(studySessions)
            ..where((s) =>
                s.targetType.equals(targetType) &
                s.targetId.equals(targetId))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  Future<int> insertSession(StudySessionsCompanion entry) =>
      into(studySessions).insert(entry);

  Future<bool> updateSession(StudySessionsCompanion entry) =>
      update(studySessions).replace(entry);

  // ── Topic Mastery ──

  Future<List<TopicMastery>> getAllMasteries() =>
      (select(topicMasteries)
            ..orderBy([(m) => OrderingTerm.desc(m.confidenceScore)]))
          .get();

  Future<int> upsertMastery(TopicMasteriesCompanion entry) =>
      into(topicMasteries).insertOnConflictUpdate(entry);
}
