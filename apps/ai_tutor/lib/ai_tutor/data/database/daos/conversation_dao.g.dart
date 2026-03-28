// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $AiConversationsTable get aiConversations => attachedDatabase.aiConversations;
  $AiMessagesTable get aiMessages => attachedDatabase.aiMessages;
  ConversationDaoManager get managers => ConversationDaoManager(this);
}

class ConversationDaoManager {
  final _$ConversationDaoMixin _db;
  ConversationDaoManager(this._db);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConversations,
      );
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db.attachedDatabase, _db.aiMessages);
}
