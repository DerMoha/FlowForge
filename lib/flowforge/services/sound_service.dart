import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

/// Types of ambient sounds available
enum AmbientSound {
  none,
  whiteNoise,
  brownNoise,
  rain,
  forest,
  ocean,
  cafe,
}

extension AmbientSoundX on AmbientSound {
  String get label {
    switch (this) {
      case AmbientSound.none:
        return 'None';
      case AmbientSound.whiteNoise:
        return 'White Noise';
      case AmbientSound.brownNoise:
        return 'Brown Noise';
      case AmbientSound.rain:
        return 'Rain';
      case AmbientSound.forest:
        return 'Forest';
      case AmbientSound.ocean:
        return 'Ocean';
      case AmbientSound.cafe:
        return 'Cafe';
    }
  }

  IconData get icon {
    switch (this) {
      case AmbientSound.none:
        return Icons.volume_off_rounded;
      case AmbientSound.whiteNoise:
        return Icons.graphic_eq_rounded;
      case AmbientSound.brownNoise:
        return Icons.waves_rounded;
      case AmbientSound.rain:
        return Icons.water_drop_rounded;
      case AmbientSound.forest:
        return Icons.forest_rounded;
      case AmbientSound.ocean:
        return Icons.water_rounded;
      case AmbientSound.cafe:
        return Icons.coffee_rounded;
    }
  }

  /// Asset path for the sound file
  String? get assetPath {
    switch (this) {
      case AmbientSound.none:
        return null;
      case AmbientSound.whiteNoise:
        return 'assets/sounds/white_noise.mp3';
      case AmbientSound.brownNoise:
        return 'assets/sounds/brown_noise.mp3';
      case AmbientSound.rain:
        return 'assets/sounds/rain.mp3';
      case AmbientSound.forest:
        return 'assets/sounds/forest.mp3';
      case AmbientSound.ocean:
        return 'assets/sounds/ocean.mp3';
      case AmbientSound.cafe:
        return 'assets/sounds/cafe.mp3';
    }
  }
}

/// Service for managing ambient sounds and sound effects
class SoundService {
  SoundService._() {
    _ambientPlayer = AudioPlayer();
    _effectPlayer = AudioPlayer();
  }

  static final instance = SoundService._();

  late final AudioPlayer _ambientPlayer;
  late final AudioPlayer _effectPlayer;

  AmbientSound _currentSound = AmbientSound.none;
  double _volume = 0.5;

  AmbientSound get currentSound => _currentSound;
  double get volume => _volume;

  /// Initialize the service
  Future<void> init() async {
    try {
      await _ambientPlayer.setLoopMode(LoopMode.one);
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
    }
  }

  /// Play ambient sound
  Future<void> playAmbient(AmbientSound sound) async {
    if (sound == _currentSound && _ambientPlayer.playing) {
      return;
    }

    try {
      await _ambientPlayer.stop();
      _currentSound = sound;

      if (sound == AmbientSound.none) {
        return;
      }

      final assetPath = sound.assetPath;
      if (assetPath != null) {
        // In a real implementation, load from assets
        // await _ambientPlayer.setAsset(assetPath);
        // await _ambientPlayer.setVolume(_volume);
        // await _ambientPlayer.play();
        debugPrint('Would play: $assetPath');
      }
    } catch (e) {
      debugPrint('Error playing ambient sound: $e');
    }
  }

  /// Stop ambient sound
  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer.stop();
      _currentSound = AmbientSound.none;
    } catch (e) {
      debugPrint('Error stopping ambient sound: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _ambientPlayer.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Play sound effect
  Future<void> playEffect(String effectName) async {
    try {
      // In a real implementation, load and play effect
      // await _effectPlayer.setAsset('assets/sounds/$effectName.mp3');
      // await _effectPlayer.play();
      debugPrint('Would play effect: $effectName');
    } catch (e) {
      debugPrint('Error playing effect: $e');
    }
  }

  /// Play completion sound
  Future<void> playCompletion() async {
    await playEffect('completion');
  }

  /// Play achievement unlock sound
  Future<void> playAchievement() async {
    await playEffect('achievement');
  }

  /// Play level up sound
  Future<void> playLevelUp() async {
    await playEffect('level_up');
  }

  /// Play notification sound
  Future<void> playNotification() async {
    await playEffect('notification');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    await _effectPlayer.dispose();
  }
}
