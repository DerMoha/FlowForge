import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/practice.dart' as model;
import '../database/ai_tutor_database.dart';

class PracticeRepository {
  PracticeRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  // ── Sessions ──

  Future<List<model.PracticeSession>> getRootSessions() async {
    final rows = await (_db.select(_db.practiceSessions)
          ..where((s) => s.parentSessionId.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
    return rows.map(_mapSession).toList();
  }

  Future<model.PracticeSession?> getSession(String id) async {
    final row = await (_db.select(_db.practiceSessions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapSession(row);
  }

  Future<List<model.PracticeSession>> getAncestors(String sessionId) async {
    final result = <model.PracticeSession>[];
    String? currentId = sessionId;
    while (currentId != null) {
      final session = await getSession(currentId);
      if (session == null) break;
      result.insert(0, session);
      currentId = session.parentSessionId;
    }
    return result;
  }

  Future<model.PracticeSession> createSession({
    required String topic,
    PracticeSourceType? sourceType,
    String? sourceId,
    String? parentSessionId,
    String? conversationId,
    int depth = 0,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.practiceSessions).insert(
          PracticeSessionsCompanion.insert(
            id: id,
            topic: topic,
            sourceType: Value(sourceType?.name),
            sourceId: Value(sourceId),
            parentSessionId: Value(parentSessionId),
            conversationId: Value(conversationId),
            depth: Value(depth),
            status: Value(PracticeSessionStatus.notStarted.name),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return model.PracticeSession(
      id: id,
      topic: topic,
      sourceType: sourceType,
      sourceId: sourceId,
      parentSessionId: parentSessionId,
      conversationId: conversationId,
      depth: depth,
      status: PracticeSessionStatus.notStarted,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateSessionStatus(
    String id,
    PracticeSessionStatus status, {
    String? conversationId,
    DateTime? completedAt,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.practiceSessions)..where((s) => s.id.equals(id)))
        .write(PracticeSessionsCompanion(
      status: Value(status.name),
      conversationId:
          conversationId != null ? Value(conversationId) : const Value.absent(),
      updatedAt: Value(now),
      completedAt:
          completedAt != null ? Value(completedAt) : const Value.absent(),
    ));
  }

  // ── Cells ──

  Future<List<model.PracticeCell>> getCells(String sessionId) async {
    final rows = await (_db.select(_db.practiceCells)
          ..where((c) => c.sessionId.equals(sessionId))
          ..orderBy([(c) => OrderingTerm.asc(c.cellIndex)]))
        .get();
    return rows.map(_mapCell).toList();
  }

  Future<model.PracticeCell> addCell({
    required String sessionId,
    required int cellIndex,
    required PracticeCellType cellType,
    required String content,
    Map<String, dynamic> metadata = const {},
    CellStatus cellStatus = CellStatus.active,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final metaJson = metadata.isEmpty ? '' : jsonEncode(metadata);
    await _db.into(_db.practiceCells).insert(
          PracticeCellsCompanion.insert(
            id: id,
            sessionId: sessionId,
            cellIndex: cellIndex,
            cellType: cellType.name,
            content: content,
            metadata: Value(metaJson),
            cellStatus: Value(cellStatus.name),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return model.PracticeCell(
      id: id,
      sessionId: sessionId,
      cellIndex: cellIndex,
      cellType: cellType,
      content: content,
      metadata: metadata,
      cellStatus: cellStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateCellContent(String cellId, String content) async {
    final now = DateTime.now();
    await (_db.update(_db.practiceCells)
          ..where((c) => c.id.equals(cellId)))
        .write(PracticeCellsCompanion(
      content: Value(content),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateCellStatus(String cellId, CellStatus status) async {
    final now = DateTime.now();
    await (_db.update(_db.practiceCells)
          ..where((c) => c.id.equals(cellId)))
        .write(PracticeCellsCompanion(
      cellStatus: Value(status.name),
      updatedAt: Value(now),
    ));
  }

  Future<void> addFeedbackCell({
    required String sessionId,
    required int cellIndex,
    required String content,
    required Map<String, dynamic> metadata,
  }) async {
    await addCell(
      sessionId: sessionId,
      cellIndex: cellIndex,
      cellType: PracticeCellType.feedback,
      content: content,
      metadata: metadata,
    );
  }

  // ── Mappers ──

  model.PracticeSession _mapSession(PracticeSession row) {
    return model.PracticeSession(
      id: row.id,
      topic: row.topic,
      sourceType: row.sourceType != null
          ? PracticeSourceType.values
              .firstWhere((e) => e.name == row.sourceType)
          : null,
      sourceId: row.sourceId,
      parentSessionId: row.parentSessionId,
      conversationId: row.conversationId,
      depth: row.depth,
      status: PracticeSessionStatus.values
          .firstWhere((e) => e.name == row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
    );
  }

  model.PracticeCell _mapCell(PracticeCell row) {
    return model.PracticeCell(
      id: row.id,
      sessionId: row.sessionId,
      cellIndex: row.cellIndex,
      cellType:
          PracticeCellType.values.firstWhere((e) => e.name == row.cellType),
      content: row.content,
      metadata: model.PracticeCell.parseMetadata(row.metadata),
      cellStatus:
          CellStatus.values.firstWhere((e) => e.name == row.cellStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
