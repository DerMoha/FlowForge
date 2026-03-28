import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/document.dart' as model;
import '../../models/enums.dart';
import '../database/ai_tutor_database.dart';

class DocumentRepository {
  DocumentRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  Stream<List<model.ImportedDocument>> watchAll() {
    return (_db.select(_db.importedDocuments)
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_mapDocument).toList());
  }

  Future<model.ImportedDocument> create({
    required String title,
    required String sourceUri,
    required String mimeType,
    required int pageCount,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.importedDocuments).insert(
      ImportedDocumentsCompanion.insert(
        id: id,
        title: title,
        sourceUri: sourceUri,
        mimeType: mimeType,
        pageCount: pageCount,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return model.ImportedDocument(
      id: id,
      title: title,
      sourceUri: sourceUri,
      mimeType: mimeType,
      pageCount: pageCount,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> deleteDocument(String id) async {
    await (_db.delete(_db.importedDocuments)..where((d) => d.id.equals(id)))
        .go();
  }

  Future<List<model.DocumentPage>> getPages(String documentId) async {
    final rows = await (_db.select(_db.documentPages)
          ..where((p) => p.documentId.equals(documentId))
          ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
        .get();
    return rows.map(_mapPage).toList();
  }

  Future<void> upsertPage(model.DocumentPage page) async {
    await _db.into(_db.documentPages).insertOnConflictUpdate(
      DocumentPagesCompanion.insert(
        id: page.id,
        documentId: page.documentId,
        pageIndex: page.pageIndex,
        extractedText: Value(page.extractedText),
        ocrConfidence: Value(page.ocrConfidence),
      ),
    );
  }

  model.ImportedDocument _mapDocument(ImportedDocument row) {
    return model.ImportedDocument(
      id: row.id,
      title: row.title,
      sourceUri: row.sourceUri,
      mimeType: row.mimeType,
      pageCount: row.pageCount,
      extractedTextStatus: ExtractedTextStatus.values.firstWhere(
        (e) => e.name == row.extractedTextStatus,
        orElse: () => ExtractedTextStatus.notExtracted,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  model.DocumentPage _mapPage(DocumentPage row) {
    return model.DocumentPage(
      id: row.id,
      documentId: row.documentId,
      pageIndex: row.pageIndex,
      extractedText: row.extractedText,
      ocrConfidence: row.ocrConfidence,
    );
  }
}
