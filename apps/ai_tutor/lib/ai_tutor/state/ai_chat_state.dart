import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/ai_repository.dart';
import '../models/conversation.dart';
import '../models/enums.dart';
import '../services/ai/ai_provider.dart';
import '../services/ai/api_key_store.dart';
import '../services/ai/openai_provider.dart';

class AiChatState extends ChangeNotifier {
  AiChatState({
    required AiRepository aiRepository,
    required ApiKeyStore apiKeyStore,
  })  : _repo = aiRepository,
        _keyStore = apiKeyStore {
    _loadProviders();
  }

  final AiRepository _repo;
  final ApiKeyStore _keyStore;

  // Available provider implementations
  final Map<String, AiProvider> _providers = {
    'openai': OpenAiProvider(),
    'openrouter': OpenAiProvider(providerId: 'openrouter'),
  };

  // State
  AiConversation? _conversation;
  List<AiMessage> _messages = [];
  StreamSubscription<List<AiMessage>>? _messagesSub;
  String _streamingContent = '';
  bool _isStreaming = false;
  bool _isLoading = false;
  String? _error;

  // Provider config
  List<ProviderConfig> _configs = [];
  String? _activeProviderId;

  // Getters
  AiConversation? get conversation => _conversation;
  List<AiMessage> get messages => _messages;
  String get streamingContent => _streamingContent;
  bool get isStreaming => _isStreaming;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProviderConfig> get configs => _configs;
  String? get activeProviderId => _activeProviderId;
  bool get hasActiveProvider => _activeProviderId != null;

  ProviderConfig? get activeConfig {
    if (_activeProviderId == null) return null;
    try {
      return _configs.firstWhere((c) => c.providerId == _activeProviderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProviders() async {
    _configs = await _keyStore.getConfigs();
    _activeProviderId = await _keyStore.getActiveProviderId();
    notifyListeners();
  }

  /// Open a conversation for a given target (notebook or document).
  Future<void> openConversation({
    required ConversationTargetType targetType,
    required String targetId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _conversation = await _repo.getOrCreateConversation(
      targetType: targetType,
      targetId: targetId,
    );

    // Watch messages
    _messagesSub?.cancel();
    _messagesSub = _repo.watchMessages(_conversation!.id).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Send a user message and stream the AI response.
  Future<void> sendMessage(String content) async {
    if (_conversation == null || content.trim().isEmpty) return;

    final config = activeConfig;
    if (config == null) {
      _error = 'No AI provider configured. Go to Settings to add one.';
      notifyListeners();
      return;
    }

    final apiKey = await _keyStore.getApiKey(config.providerId);
    if (apiKey == null || apiKey.isEmpty) {
      _error = 'No API key found for ${config.label}.';
      notifyListeners();
      return;
    }

    _error = null;

    // Add user message
    await _repo.addMessage(
      conversationId: _conversation!.id,
      role: MessageRole.user,
      content: content.trim(),
    );

    // Build chat request from conversation history
    final chatMessages = _messages
        .map((m) => AiChatMessage(
              role: m.role.name,
              content: m.content,
            ))
        .toList();

    // Add the new user message (it might not be in _messages yet)
    if (chatMessages.isEmpty ||
        chatMessages.last.content != content.trim()) {
      chatMessages.add(AiChatMessage(role: 'user', content: content.trim()));
    }

    final request = AiChatRequest(
      messages: chatMessages,
      systemPrompt:
          'You are a helpful AI tutor. Help the student understand their study material. '
          'Be concise but thorough. Use examples when helpful.',
    );

    final runtimeConfig = ProviderRuntimeConfig(
      apiKey: apiKey,
      model: config.model,
      baseUrl: config.baseUrl,
    );

    final provider = _providers[config.providerId];
    if (provider == null) {
      _error = 'Provider "${config.providerId}" not found.';
      notifyListeners();
      return;
    }

    // Stream response
    _isStreaming = true;
    _streamingContent = '';
    notifyListeners();

    try {
      await for (final chunk in provider.sendChat(runtimeConfig, request)) {
        if (chunk.isDone) break;
        _streamingContent += chunk.content;
        notifyListeners();
      }

      // Save completed response
      if (_streamingContent.isNotEmpty) {
        await _repo.addMessage(
          conversationId: _conversation!.id,
          role: MessageRole.assistant,
          content: _streamingContent,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isStreaming = false;
      _streamingContent = '';
      notifyListeners();
    }
  }

  /// Save a new provider config with API key.
  Future<void> saveProvider({
    required String providerId,
    required String label,
    required String model,
    required String apiKey,
    String? baseUrl,
  }) async {
    final config = ProviderConfig(
      providerId: providerId,
      label: label,
      model: model,
      baseUrl: baseUrl,
    );
    await _keyStore.saveConfig(config);
    await _keyStore.saveApiKey(providerId, apiKey);

    // If no active provider, make this one active
    _activeProviderId ??= providerId;
    await _keyStore.setActiveProviderId(_activeProviderId!);

    await _loadProviders();
  }

  /// Delete a provider config.
  Future<void> deleteProvider(String providerId) async {
    await _keyStore.deleteConfig(providerId);
    if (_activeProviderId == providerId) {
      final remaining = await _keyStore.getConfigs();
      _activeProviderId =
          remaining.isNotEmpty ? remaining.first.providerId : null;
      if (_activeProviderId != null) {
        await _keyStore.setActiveProviderId(_activeProviderId!);
      }
    }
    await _loadProviders();
  }

  /// Set the active provider.
  Future<void> setActiveProvider(String providerId) async {
    _activeProviderId = providerId;
    await _keyStore.setActiveProviderId(providerId);
    notifyListeners();
  }

  /// Test connection to a provider.
  Future<void> testConnection({
    required String providerId,
    required String apiKey,
    required String model,
    String? baseUrl,
  }) async {
    final provider = _providers[providerId];
    if (provider == null) throw Exception('Unknown provider: $providerId');

    await provider.testConnection(ProviderRuntimeConfig(
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
    ));
  }

  /// Close the current conversation.
  void closeConversation() {
    _messagesSub?.cancel();
    _conversation = null;
    _messages = [];
    _streamingContent = '';
    _isStreaming = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}
