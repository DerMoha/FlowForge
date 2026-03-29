// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_dao.dart';

// ignore_for_file: type=lint
mixin _$PracticeDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $AiConversationsTable get aiConversations => attachedDatabase.aiConversations;
  $PracticeSessionsTable get practiceSessions =>
      attachedDatabase.practiceSessions;
  $PracticeCellsTable get practiceCells => attachedDatabase.practiceCells;
  PracticeDaoManager get managers => PracticeDaoManager(this);
}

class PracticeDaoManager {
  final _$PracticeDaoMixin _db;
  PracticeDaoManager(this._db);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConversations,
      );
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(
        _db.attachedDatabase,
        _db.practiceSessions,
      );
  $$PracticeCellsTableTableManager get practiceCells =>
      $$PracticeCellsTableTableManager(_db.attachedDatabase, _db.practiceCells);
}
