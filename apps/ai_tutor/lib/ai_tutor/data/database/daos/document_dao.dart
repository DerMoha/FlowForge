import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [ImportedDocuments, DocumentPages, Annotations])
class DocumentDao extends DatabaseAccessor<AiTutorDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Future<List<ImportedDocument>> getAllDocuments() =>
      select(importedDocuments).get();

  Stream<List<ImportedDocument>> watchAllDocuments() =>
      select(importedDocuments).watch();

  Future<ImportedDocument> getDocument(String id) =>
      (select(importedDocuments)..where((d) => d.id.equals(id))).getSingle();

  Future<int> insertDocument(ImportedDocumentsCompanion entry) =>
      into(importedDocuments).insert(entry);

  Future<bool> updateDocument(ImportedDocumentsCompanion entry) =>
      update(importedDocuments).replace(entry);

  Future<int> deleteDocument(String id) =>
      (delete(importedDocuments)..where((d) => d.id.equals(id))).go();

  // ── Pages ──

  Future<List<DocumentPage>> getPagesForDocument(String documentId) =>
      (select(documentPages)
            ..where((p) => p.documentId.equals(documentId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
          .get();

  Future<int> insertDocumentPage(DocumentPagesCompanion entry) =>
      into(documentPages).insert(entry);

  Future<bool> updateDocumentPage(DocumentPagesCompanion entry) =>
      update(documentPages).replace(entry);

  // ── Annotations ──

  Future<List<Annotation>> getAnnotationsForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(annotations)
            ..where(
                (a) => a.targetType.equals(targetType) & a.targetId.equals(targetId)))
          .get();

  Future<int> insertAnnotation(AnnotationsCompanion entry) =>
      into(annotations).insert(entry);

  Future<int> deleteAnnotation(String id) =>
      (delete(annotations)..where((a) => a.id.equals(id))).go();
}
