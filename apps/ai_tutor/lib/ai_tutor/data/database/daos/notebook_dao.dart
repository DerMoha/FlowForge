import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'notebook_dao.g.dart';

@DriftAccessor(tables: [Notebooks, NotebookPages, Strokes, StrokePoints])
class NotebookDao extends DatabaseAccessor<AiTutorDatabase>
    with _$NotebookDaoMixin {
  NotebookDao(super.db);

  // ── Notebooks ──

  Future<List<Notebook>> getAllNotebooks() => select(notebooks).get();

  Stream<List<Notebook>> watchAllNotebooks() => select(notebooks).watch();

  Future<Notebook> getNotebook(String id) =>
      (select(notebooks)..where((n) => n.id.equals(id))).getSingle();

  Future<int> insertNotebook(NotebooksCompanion entry) =>
      into(notebooks).insert(entry);

  Future<bool> updateNotebook(NotebooksCompanion entry) =>
      update(notebooks).replace(entry);

  Future<int> deleteNotebook(String id) =>
      (delete(notebooks)..where((n) => n.id.equals(id))).go();

  // ── Pages ──

  Future<List<NotebookPage>> getPagesForNotebook(String notebookId) =>
      (select(notebookPages)
            ..where((p) => p.notebookId.equals(notebookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
          .get();

  Stream<List<NotebookPage>> watchPagesForNotebook(String notebookId) =>
      (select(notebookPages)
            ..where((p) => p.notebookId.equals(notebookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
          .watch();

  Future<int> insertPage(NotebookPagesCompanion entry) =>
      into(notebookPages).insert(entry);

  Future<int> deletePage(String pageId) =>
      (delete(notebookPages)..where((p) => p.id.equals(pageId))).go();

  // ── Strokes ──

  Future<List<Stroke>> getStrokesForPage(String pageId) =>
      (select(strokes)..where((s) => s.pageId.equals(pageId))).get();

  Stream<List<Stroke>> watchStrokesForPage(String pageId) =>
      (select(strokes)..where((s) => s.pageId.equals(pageId))).watch();

  Future<int> insertStroke(StrokesCompanion entry) =>
      into(strokes).insert(entry);

  Future<void> insertStrokeWithPoints(
    StrokesCompanion stroke,
    List<StrokePointsCompanion> points,
  ) async {
    await batch((batch) {
      batch.insert(strokes, stroke);
      batch.insertAll(strokePoints, points);
    });
  }

  Future<int> deleteStroke(String strokeId) =>
      (delete(strokes)..where((s) => s.id.equals(strokeId))).go();

  // ── Stroke Points ──

  Future<List<StrokePoint>> getPointsForStroke(String strokeId) =>
      (select(strokePoints)
            ..where((p) => p.strokeId.equals(strokeId))
            ..orderBy([(p) => OrderingTerm.asc(p.timeOffsetMs)]))
          .get();
}
