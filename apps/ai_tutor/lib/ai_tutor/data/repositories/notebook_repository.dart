import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/notebook.dart' as model;
import '../../models/stroke.dart' as model;
import '../database/ai_tutor_database.dart';

class NotebookRepository {
  NotebookRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  // ── Notebooks ──

  Stream<List<model.Notebook>> watchAll() {
    return ((_db.select(_db.notebooks))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_mapNotebook).toList());
  }

  Future<model.Notebook> create({required String title, String? subject}) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.notebooks).insert(NotebooksCompanion.insert(
      id: id,
      title: title,
      subject: Value(subject),
      createdAt: now,
      updatedAt: now,
    ));
    // Create first page
    await addPage(id);
    return model.Notebook(
      id: id,
      title: title,
      subject: subject,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateNotebook(model.Notebook notebook) async {
    await (_db.update(_db.notebooks)
          ..where((n) => n.id.equals(notebook.id)))
        .write(NotebooksCompanion(
      title: Value(notebook.title),
      subject: Value(notebook.subject),
      tags: Value(notebook.tags.join(',')),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteNotebook(String id) async {
    await (_db.delete(_db.notebooks)..where((n) => n.id.equals(id))).go();
  }

  // ── Pages ──

  Future<List<model.NotebookPage>> getPages(String notebookId) async {
    final rows = await (_db.select(_db.notebookPages)
          ..where((p) => p.notebookId.equals(notebookId))
          ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
        .get();
    return rows.map(_mapPage).toList();
  }

  Future<model.NotebookPage> addPage(
    String notebookId, {
    PageBackgroundStyle backgroundStyle = PageBackgroundStyle.ruled,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    // Get next index
    final pages = await getPages(notebookId);
    final nextIndex = pages.isEmpty ? 0 : pages.last.index + 1;

    await _db.into(_db.notebookPages).insert(NotebookPagesCompanion.insert(
      id: id,
      notebookId: notebookId,
      pageIndex: nextIndex,
      backgroundStyle: Value(backgroundStyle.name),
      createdAt: now,
      updatedAt: now,
    ));

    return model.NotebookPage(
      id: id,
      notebookId: notebookId,
      index: nextIndex,
      backgroundStyle: backgroundStyle,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ── Strokes ──

  Future<List<model.Stroke>> getStrokes(String pageId) async {
    final strokeRows = await (_db.select(_db.strokes)
          ..where((s) => s.pageId.equals(pageId)))
        .get();

    final result = <model.Stroke>[];
    for (final row in strokeRows) {
      final pointRows = await (_db.select(_db.strokePoints)
            ..where((p) => p.strokeId.equals(row.id))
            ..orderBy([(p) => OrderingTerm.asc(p.timeOffsetMs)]))
          .get();
      result.add(_mapStroke(row, pointRows));
    }
    return result;
  }

  Future<void> addStroke(model.Stroke stroke) async {
    await _db.batch((batch) {
      batch.insert(
        _db.strokes,
        StrokesCompanion.insert(
          id: stroke.id,
          pageId: stroke.pageId,
          tool: stroke.tool.name,
          colorArgb: stroke.colorArgb,
          width: stroke.width,
          createdAt: stroke.createdAt,
        ),
      );
      batch.insertAll(
        _db.strokePoints,
        stroke.points
            .map((p) => StrokePointsCompanion.insert(
                  strokeId: stroke.id,
                  x: p.x,
                  y: p.y,
                  pressure: Value(p.pressure),
                  tilt: Value(p.tilt),
                  timeOffsetMs: p.timeOffsetMs,
                ))
            .toList(),
      );
    });
  }

  Future<void> deleteStroke(String strokeId) async {
    await (_db.delete(_db.strokes)..where((s) => s.id.equals(strokeId))).go();
  }

  // ── Mappers ──

  model.Notebook _mapNotebook(Notebook row) {
    return model.Notebook(
      id: row.id,
      title: row.title,
      subject: row.subject,
      tags: row.tags.isEmpty ? [] : row.tags.split(','),
      coverStyle: row.coverStyle,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      archivedAt: row.archivedAt,
    );
  }

  model.NotebookPage _mapPage(NotebookPage row) {
    return model.NotebookPage(
      id: row.id,
      notebookId: row.notebookId,
      index: row.pageIndex,
      backgroundStyle: PageBackgroundStyle.values.firstWhere(
        (e) => e.name == row.backgroundStyle,
        orElse: () => PageBackgroundStyle.ruled,
      ),
      derivedText: row.derivedText,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  model.Stroke _mapStroke(Stroke row, List<StrokePoint> pointRows) {
    return model.Stroke(
      id: row.id,
      pageId: row.pageId,
      tool: InkTool.values.firstWhere(
        (e) => e.name == row.tool,
        orElse: () => InkTool.pen,
      ),
      colorArgb: row.colorArgb,
      width: row.width,
      points: pointRows
          .map((p) => model.StrokePoint(
                x: p.x,
                y: p.y,
                pressure: p.pressure,
                tilt: p.tilt,
                timeOffsetMs: p.timeOffsetMs,
              ))
          .toList(),
      createdAt: row.createdAt,
    );
  }
}
