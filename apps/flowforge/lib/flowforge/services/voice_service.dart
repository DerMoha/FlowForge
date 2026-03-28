import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  VoiceService._();
  static final instance = VoiceService._();

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech error: $error'),
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(bool) onListeningStateChanged,
  }) async {
    final available = await initialize();
    if (available) {
      _isListening = true;
      onListeningStateChanged(true);
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            onListeningStateChanged(false);
          }
        },
      );
    } else {
      _isListening = false;
      onListeningStateChanged(false);
    }
  }

  Future<void> stopListening(Function(bool) onListeningStateChanged) async {
    await _speechToText.stop();
    _isListening = false;
    onListeningStateChanged(false);
  }

  Future<void> cancelListening(Function(bool) onListeningStateChanged) async {
    await _speechToText.cancel();
    _isListening = false;
    onListeningStateChanged(false);
  }
}
