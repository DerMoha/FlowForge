import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps STT and TTS into a unified speech service.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttInitialized = false;
  bool _ttsInitialized = false;

  bool get isSttAvailable => _sttInitialized;
  bool get isTtsAvailable => _ttsInitialized;

  /// Initialize both STT and TTS.
  Future<void> initialize() async {
    _sttInitialized = await _stt.initialize();

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ttsInitialized = true;
  }

  /// Start listening for speech input.
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function()? onDone,
  }) async {
    if (!_sttInitialized) return;

    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onDone?.call();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _stt.stop();
  }

  /// Speak text aloud.
  Future<void> speak(String text) async {
    if (!_ttsInitialized) return;
    await _tts.speak(text);
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Set a callback for when TTS finishes speaking.
  void setCompletionHandler(void Function() onComplete) {
    _tts.setCompletionHandler(onComplete);
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _stt.stop();
    await _tts.stop();
  }
}
