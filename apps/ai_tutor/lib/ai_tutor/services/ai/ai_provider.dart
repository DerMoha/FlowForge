/// Configuration passed to AI providers at runtime.
class ProviderRuntimeConfig {
  const ProviderRuntimeConfig({
    required this.apiKey,
    required this.model,
    this.baseUrl,
  });

  final String apiKey;
  final String model;
  final String? baseUrl;
}

/// A single chunk from a streaming AI response.
class AiStreamChunk {
  const AiStreamChunk({required this.content, this.isDone = false});

  final String content;
  final bool isDone;
}

/// Request payload for chat completions.
class AiChatRequest {
  const AiChatRequest({
    required this.messages,
    this.systemPrompt,
  });

  final List<AiChatMessage> messages;
  final String? systemPrompt;
}

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role; // 'user', 'assistant', 'system'
  final String content;
}

/// Request payload for quiz generation.
class QuizGenerationRequest {
  const QuizGenerationRequest({
    required this.content,
    required this.questionCount,
    required this.questionTypes,
  });

  final String content;
  final int questionCount;
  final List<String> questionTypes;
}

/// Abstract AI provider interface.
abstract class AiProvider {
  String get id;

  /// Test that the provider is reachable with the given config.
  Future<void> testConnection(ProviderRuntimeConfig config);

  /// Send a chat request and receive a stream of response chunks.
  Stream<AiStreamChunk> sendChat(
    ProviderRuntimeConfig config,
    AiChatRequest request,
  );

  /// Generate a quiz from content.
  Future<String> generateQuiz(
    ProviderRuntimeConfig config,
    QuizGenerationRequest request,
  );

  /// Summarize content.
  Future<String> summarize(
    ProviderRuntimeConfig config,
    String content,
  );

  /// Non-streaming single-turn completion. Returns the full response string.
  /// Used for structured JSON responses (e.g., practice evaluation).
  Future<String> complete(
    ProviderRuntimeConfig config,
    AiChatRequest request,
  );
}
