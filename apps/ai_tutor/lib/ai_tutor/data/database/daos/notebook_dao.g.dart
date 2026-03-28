// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_dao.dart';

// ignore_for_file: type=lint
mixin _$NotebookDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $NotebookPagesTable get notebookPages => attachedDatabase.notebookPages;
  $StrokesTable get strokes => attachedDatabase.strokes;
  $StrokePointsTable get strokePoints => attachedDatabase.strokePoints;
  NotebookDaoManager get managers => NotebookDaoManager(this);
}

class NotebookDaoManager {
  final _$NotebookDaoMixin _db;
  NotebookDaoManager(this._db);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$NotebookPagesTableTableManager get notebookPages =>
      $$NotebookPagesTableTableManager(_db.attachedDatabase, _db.notebookPages);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db.attachedDatabase, _db.strokes);
  $$StrokePointsTableTableManager get strokePoints =>
      $$StrokePointsTableTableManager(_db.attachedDatabase, _db.strokePoints);
}
