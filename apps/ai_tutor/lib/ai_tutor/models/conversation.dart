import 'enums.dart';

class AiConversation {
  const AiConversation({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ConversationTargetType targetType;
  final String targetId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation copyWith({
    String? id,
    ConversationTargetType? targetType,
    String? targetId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiConversation(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiMessage {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final List<String> citations;
  final DateTime createdAt;

  AiMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    List<String>? citations,
    DateTime? createdAt,
  }) {
    return AiMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProviderConfig {
  const ProviderConfig({
    required this.providerId,
    required this.label,
    this.baseUrl,
    required this.model,
    this.isEnabled = true,
  });

  final String providerId;
  final String label;
  final String? baseUrl;
  final String model;
  final bool isEnabled;

  ProviderConfig copyWith({
    String? providerId,
    String? label,
    String? baseUrl,
    String? model,
    bool? isEnabled,
  }) {
    return ProviderConfig(
      providerId: providerId ?? this.providerId,
      label: label ?? this.label,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
