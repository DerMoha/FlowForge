import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [AiConversations, AiMessages])
class ConversationDao extends DatabaseAccessor<AiTutorDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  // ── Conversations ──

  Future<List<AiConversation>> getConversationsForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(aiConversations)
            ..where((c) =>
                c.targetType.equals(targetType) &
                c.targetId.equals(targetId))
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
          .get();

  Future<AiConversation> getConversation(String id) =>
      (select(aiConversations)..where((c) => c.id.equals(id))).getSingle();

  Future<int> insertConversation(AiConversationsCompanion entry) =>
      into(aiConversations).insert(entry);

  Future<bool> updateConversation(AiConversationsCompanion entry) =>
      update(aiConversations).replace(entry);

  Future<int> deleteConversation(String id) =>
      (delete(aiConversations)..where((c) => c.id.equals(id))).go();

  // ── Messages ──

  Future<List<AiMessage>> getMessagesForConversation(String conversationId) =>
      (select(aiMessages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .get();

  Stream<List<AiMessage>> watchMessagesForConversation(String conversationId) =>
      (select(aiMessages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .watch();

  Future<int> insertMessage(AiMessagesCompanion entry) =>
      into(aiMessages).insert(entry);

  Future<int> deleteMessage(String id) =>
      (delete(aiMessages)..where((m) => m.id.equals(id))).go();
}
