import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/conversation.dart' as model;
import '../../models/enums.dart';
import '../database/ai_tutor_database.dart';

class AiRepository {
  AiRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  Future<model.AiConversation> getOrCreateConversation({
    required ConversationTargetType targetType,
    required String targetId,
  }) async {
    final existing = await (_db.select(_db.aiConversations)
          ..where((c) =>
              c.targetType.equals(targetType.name) &
              c.targetId.equals(targetId))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) return _mapConversation(existing);

    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.aiConversations).insert(
      AiConversationsCompanion.insert(
        id: id,
        targetType: targetType.name,
        targetId: targetId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return model.AiConversation(
      id: id,
      targetType: targetType,
      targetId: targetId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Stream<List<model.AiMessage>> watchMessages(String conversationId) {
    return (_db.select(_db.aiMessages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapMessage).toList());
  }

  Future<model.AiMessage> addMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    List<String> citations = const [],
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.aiMessages).insert(
      AiMessagesCompanion.insert(
        id: id,
        conversationId: conversationId,
        role: role.name,
        content: content,
        citations: Value(citations.join(',')),
        createdAt: now,
      ),
    );
    // Update conversation timestamp
    await (_db.update(_db.aiConversations)
          ..where((c) => c.id.equals(conversationId)))
        .write(AiConversationsCompanion(updatedAt: Value(now)));

    return model.AiMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      citations: citations,
      createdAt: now,
    );
  }

  Future<void> deleteConversation(String id) async {
    await (_db.delete(_db.aiConversations)..where((c) => c.id.equals(id))).go();
  }

  model.AiConversation _mapConversation(AiConversation row) {
    return model.AiConversation(
      id: row.id,
      targetType: ConversationTargetType.values.firstWhere(
        (e) => e.name == row.targetType,
      ),
      targetId: row.targetId,
      title: row.title,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  model.AiMessage _mapMessage(AiMessage row) {
    return model.AiMessage(
      id: row.id,
      conversationId: row.conversationId,
      role: MessageRole.values.firstWhere((e) => e.name == row.role),
      content: row.content,
      citations: row.citations.isEmpty ? [] : row.citations.split(','),
      createdAt: row.createdAt,
    );
  }
}
