import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sound_service.dart';

/// Manages user preferences and settings
class ProfileState extends ChangeNotifier {
  String _selectedTheme = 'default';
  AmbientSound _ambientSound = AmbientSound.none;
  double _ambientVolume = 0.5;
  bool _hapticFeedbackEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoStartTimerAfterTask = false;
  String? _userName;

  String get selectedTheme => _selectedTheme;
  AmbientSound get ambientSound => _ambientSound;
  double get ambientVolume => _ambientVolume;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoStartTimerAfterTask => _autoStartTimerAfterTask;
  String? get userName => _userName;

  /// Initialize state
  Future<void> init() async {
    await _loadState();
  }

  /// Set selected theme
  void setTheme(String themeId) {
    if (_selectedTheme == themeId) return;

    _selectedTheme = themeId;
    notifyListeners();
    _saveState();
  }

  /// Set ambient sound
  Future<void> setAmbientSound(AmbientSound sound) async {
    if (_ambientSound == sound) return;

    _ambientSound = sound;
    notifyListeners();
    await _saveState();

    // Update sound service
    await SoundService.instance.playAmbient(sound);
  }

  /// Set ambient volume
  Future<void> setAmbientVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (_ambientVolume == clamped) return;

    _ambientVolume = clamped;
    notifyListeners();
    await _saveState();

    // Update sound service
    await SoundService.instance.setVolume(clamped);
  }

  /// Toggle haptic feedback
  void toggleHapticFeedback() {
    _hapticFeedbackEnabled = !_hapticFeedbackEnabled;
    notifyListeners();
    _saveState();
  }

  /// Toggle notifications
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    _saveState();
  }

  /// Toggle auto-start timer after task
  void toggleAutoStartTimer() {
    _autoStartTimerAfterTask = !_autoStartTimerAfterTask;
    notifyListeners();
    _saveState();
  }

  /// Set user name
  void setUserName(String? name) {
    _userName = name?.trim();
    notifyListeners();
    _saveState();
  }

  /// Load state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _selectedTheme = prefs.getString('profile_theme') ?? 'default';

      final soundName = prefs.getString('profile_ambient_sound') ?? 'none';
      _ambientSound = AmbientSound.values.firstWhere(
        (s) => s.name == soundName,
        orElse: () => AmbientSound.none,
      );

      _ambientVolume = prefs.getDouble('profile_ambient_volume') ?? 0.5;
      _hapticFeedbackEnabled = prefs.getBool('profile_haptic_feedback') ?? true;
      _notificationsEnabled = prefs.getBool('profile_notifications') ?? true;
      _autoStartTimerAfterTask =
          prefs.getBool('profile_auto_start_timer') ?? false;
      _userName = prefs.getString('profile_user_name');

      notifyListeners();

      // Initialize sound service with saved preferences
      if (_ambientSound != AmbientSound.none) {
        await SoundService.instance.playAmbient(_ambientSound);
        await SoundService.instance.setVolume(_ambientVolume);
      }
    } catch (e) {
      debugPrint('Error loading profile state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('profile_theme', _selectedTheme);
      await prefs.setString('profile_ambient_sound', _ambientSound.name);
      await prefs.setDouble('profile_ambient_volume', _ambientVolume);
      await prefs.setBool('profile_haptic_feedback', _hapticFeedbackEnabled);
      await prefs.setBool('profile_notifications', _notificationsEnabled);
      await prefs.setBool('profile_auto_start_timer', _autoStartTimerAfterTask);

      if (_userName != null) {
        await prefs.setString('profile_user_name', _userName!);
      } else {
        await prefs.remove('profile_user_name');
      }
    } catch (e) {
      debugPrint('Error saving profile state: $e');
    }
  }
}
