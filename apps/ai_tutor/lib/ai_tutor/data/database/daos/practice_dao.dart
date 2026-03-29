import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'practice_dao.g.dart';

@DriftAccessor(tables: [PracticeSessions, PracticeCells])
class PracticeDao extends DatabaseAccessor<AiTutorDatabase>
    with _$PracticeDaoMixin {
  PracticeDao(super.db);

  // ── Sessions ──

  Future<List<PracticeSession>> getRootSessions() =>
      (select(practiceSessions)
            ..where((s) => s.parentSessionId.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
          .get();

  Future<PracticeSession?> getSession(String id) =>
      (select(practiceSessions)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  Future<List<PracticeSession>> getChildSessions(String parentId) =>
      (select(practiceSessions)
            ..where((s) => s.parentSessionId.equals(parentId))
            ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
          .get();

  Future<void> insertSession(PracticeSessionsCompanion session) =>
      into(practiceSessions).insert(session);

  Future<void> updateSession(PracticeSessionsCompanion session) =>
      (update(practiceSessions)
            ..where((s) => s.id.equals(session.id.value)))
          .write(session);

  Future<void> deleteSession(String id) =>
      (delete(practiceSessions)..where((s) => s.id.equals(id))).go();

  // ── Cells ──

  Future<List<PracticeCell>> getCells(String sessionId) =>
      (select(practiceCells)
            ..where((c) => c.sessionId.equals(sessionId))
            ..orderBy([(c) => OrderingTerm.asc(c.cellIndex)]))
          .get();

  Future<void> insertCell(PracticeCellsCompanion cell) =>
      into(practiceCells).insert(cell);

  Future<void> updateCell(PracticeCellsCompanion cell) =>
      (update(practiceCells)..where((c) => c.id.equals(cell.id.value)))
          .write(cell);

  Future<void> deleteCellsForSession(String sessionId) =>
      (delete(practiceCells)
            ..where((c) => c.sessionId.equals(sessionId)))
          .go();
}
