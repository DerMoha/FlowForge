// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ProgressDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $StudySessionsTable get studySessions => attachedDatabase.studySessions;
  $TopicMasteriesTable get topicMasteries => attachedDatabase.topicMasteries;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db.attachedDatabase, _db.studySessions);
  $$TopicMasteriesTableTableManager get topicMasteries =>
      $$TopicMasteriesTableTableManager(
        _db.attachedDatabase,
        _db.topicMasteries,
      );
}
