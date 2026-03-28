// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $ImportedDocumentsTable get importedDocuments =>
      attachedDatabase.importedDocuments;
  $DocumentPagesTable get documentPages => attachedDatabase.documentPages;
  $AnnotationsTable get annotations => attachedDatabase.annotations;
  DocumentDaoManager get managers => DocumentDaoManager(this);
}

class DocumentDaoManager {
  final _$DocumentDaoMixin _db;
  DocumentDaoManager(this._db);
  $$ImportedDocumentsTableTableManager get importedDocuments =>
      $$ImportedDocumentsTableTableManager(
        _db.attachedDatabase,
        _db.importedDocuments,
      );
  $$DocumentPagesTableTableManager get documentPages =>
      $$DocumentPagesTableTableManager(_db.attachedDatabase, _db.documentPages);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db.attachedDatabase, _db.annotations);
}
