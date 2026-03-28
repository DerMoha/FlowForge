import 'package:flutter/foundation.dart';
import '../services/ai/ai_provider.dart';
import '../services/ai/api_key_store.dart';
import '../services/ai/openai_provider.dart';
import '../services/speech_service.dart';

enum VoiceTutorStatus { idle, listening, processing, speaking }

class VoiceTutorState extends ChangeNotifier {
  VoiceTutorState({
    required SpeechService speechService,
    required ApiKeyStore apiKeyStore,
  })  : _speech = speechService,
        _keyStore = apiKeyStore;

  final SpeechService _speech;
  final ApiKeyStore _keyStore;

  final Map<String, AiProvider> _providers = {
    'openai': OpenAiProvider(),
    'openrouter': OpenAiProvider(providerId: 'openrouter'),
  };

  VoiceTutorStatus _status = VoiceTutorStatus.idle;
  String _recognizedText = '';
  String _responseText = '';
  String? _error;
  bool _initialized = false;

  // Conversation history for context
  final List<AiChatMessage> _history = [];

  VoiceTutorStatus get status => _status;
  String get recognizedText => _recognizedText;
  String get responseText => _responseText;
  String? get error => _error;
  bool get initialized => _initialized;
  bool get isIdle => _status == VoiceTutorStatus.idle;
  bool get isListening => _status == VoiceTutorStatus.listening;
  bool get isProcessing => _status == VoiceTutorStatus.processing;
  bool get isSpeaking => _status == VoiceTutorStatus.speaking;

  Future<void> initialize() async {
    await _speech.initialize();
    _speech.setCompletionHandler(_onSpeechComplete);
    _initialized = true;
    notifyListeners();
  }

  /// Start listening for voice input (push-to-talk).
  Future<void> startListening() async {
    if (!_initialized) await initialize();

    _error = null;
    _status = VoiceTutorStatus.listening;
    _recognizedText = '';
    notifyListeners();

    await _speech.startListening(
      onResult: (text) {
        _recognizedText = text;
        notifyListeners();
      },
      onDone: () {
        if (_recognizedText.isNotEmpty) {
          _processInput(_recognizedText);
        } else {
          _status = VoiceTutorStatus.idle;
          notifyListeners();
        }
      },
    );
  }

  /// Stop listening and process what we have.
  Future<void> stopListening() async {
    await _speech.stopListening();
    if (_recognizedText.isNotEmpty) {
      _processInput(_recognizedText);
    } else {
      _status = VoiceTutorStatus.idle;
      notifyListeners();
    }
  }

  /// Process user input through AI.
  Future<void> _processInput(String input) async {
    _status = VoiceTutorStatus.processing;
    notifyListeners();

    try {
      final activeId = await _keyStore.getActiveProviderId();
      if (activeId == null) throw Exception('No AI provider configured.');

      final configs = await _keyStore.getConfigs();
      final config = configs.firstWhere((c) => c.providerId == activeId);
      final apiKey = await _keyStore.getApiKey(activeId);
      if (apiKey == null) throw Exception('No API key found.');

      final provider = _providers[activeId];
      if (provider == null) throw Exception('Unknown provider.');

      _history.add(AiChatMessage(role: 'user', content: input));

      final request = AiChatRequest(
        messages: _history,
        systemPrompt:
            'You are a voice-based AI tutor having a spoken conversation with a student. '
            'Keep responses concise (2-3 sentences max) and conversational. '
            'Explain concepts clearly and ask follow-up questions to check understanding.',
      );

      final runtimeConfig = ProviderRuntimeConfig(
        apiKey: apiKey,
        model: config.model,
        baseUrl: config.baseUrl,
      );

      // Collect full response (not streaming for voice)
      final buffer = StringBuffer();
      await for (final chunk in provider.sendChat(runtimeConfig, request)) {
        if (chunk.isDone) break;
        buffer.write(chunk.content);
      }

      _responseText = buffer.toString();
      _history.add(AiChatMessage(role: 'assistant', content: _responseText));

      // Speak the response
      _status = VoiceTutorStatus.speaking;
      notifyListeners();
      await _speech.speak(_responseText);
    } catch (e) {
      _error = e.toString();
      _status = VoiceTutorStatus.idle;
      notifyListeners();
    }
  }

  void _onSpeechComplete() {
    _status = VoiceTutorStatus.idle;
    notifyListeners();
  }

  /// Stop everything and reset.
  Future<void> stop() async {
    await _speech.stopListening();
    await _speech.stopSpeaking();
    _status = VoiceTutorStatus.idle;
    notifyListeners();
  }

  /// Clear conversation history.
  void clearHistory() {
    _history.clear();
    _recognizedText = '';
    _responseText = '';
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }
}
