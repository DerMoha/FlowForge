import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/task_energy_requirement.dart';

/// Manages XP, levels, achievements, and streaks
class GamificationState extends ChangeNotifier {
  UserProfile _profile = UserProfile.initial();

  UserProfile get profile => _profile;

  /// Initialize state
  Future<void> init() async {
    await _loadState();
  }

  /// Award XP for completing a task
  void awardTaskXP(TaskEnergyRequirement energyRequirement) {
    final baseXP = 10;
    final multiplier = switch (energyRequirement) {
      TaskEnergyRequirement.low => 1.0,
      TaskEnergyRequirement.medium => 1.5,
      TaskEnergyRequirement.high => 1.75,
      TaskEnergyRequirement.deep => 2.0,
    };

    final xp = (baseXP * multiplier).round();
    _addXP(xp);

    // Update lifetime stats
    final updatedStats = _profile.lifetimeStats.copyWith(
      totalTasksCompleted: _profile.lifetimeStats.totalTasksCompleted + 1,
      totalDeepTasksCompleted: energyRequirement == TaskEnergyRequirement.deep
          ? _profile.lifetimeStats.totalDeepTasksCompleted + 1
          : null,
    );

    _profile = _profile.copyWith(lifetimeStats: updatedStats);
    notifyListeners();
    _saveState();
  }

  /// Award XP for completing a focus session
  void awardSessionXP(int minutes) {
    final xp = (minutes / 15 * 20).round();
    _addXP(xp);

    // Update lifetime stats
    final updatedStats = _profile.lifetimeStats.copyWith(
      totalSessions: _profile.lifetimeStats.totalSessions + 1,
      totalMinutes: _profile.lifetimeStats.totalMinutes + minutes,
      longestSessionMinutes: max(
        _profile.lifetimeStats.longestSessionMinutes,
        minutes,
      ),
    );

    _profile = _profile.copyWith(
      lifetimeStats: updatedStats,
      lastSessionDate: DateTime.now(),
    );

    // Update streak
    _updateStreak();

    notifyListeners();
    _saveState();
  }

  /// Award XP for streak milestone
  void awardStreakXP(int streakDays) {
    final xp = streakDays * 50;
    _addXP(xp);
  }

  /// Award perfect week bonus
  void awardPerfectWeekBonus() {
    _addXP(500);

    final updatedStats = _profile.lifetimeStats.copyWith(
      perfectWeeks: _profile.lifetimeStats.perfectWeeks + 1,
    );

    _profile = _profile.copyWith(lifetimeStats: updatedStats);
    notifyListeners();
    _saveState();
  }

  /// Add XP and check for level ups
  void _addXP(int xp) {
    final oldLevel = _profile.level;
    final newTotalXP = _profile.totalXP + xp;

    _profile = _profile.copyWith(totalXP: newTotalXP);

    final newLevel = _profile.level;
    if (newLevel > oldLevel) {
      _onLevelUp(newLevel);
    }
  }

  /// Handle level up
  void _onLevelUp(int newLevel) {
    debugPrint('Level up! New level: $newLevel');
    // This will trigger UI animations/celebrations
    // Can add callback here for UI layer to listen
  }

  /// Update streak based on last session date
  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSession = _profile.lastSessionDate;

    if (lastSession == null) {
      // First session ever
      _profile = _profile.copyWith(
        currentStreak: 1,
        longestStreak: 1,
      );
      return;
    }

    final lastSessionDay = DateTime(
      lastSession.year,
      lastSession.month,
      lastSession.day,
    );

    if (lastSessionDay == today) {
      // Already counted today
      return;
    }

    final daysSinceLastSession = today.difference(lastSessionDay).inDays;

    if (daysSinceLastSession == 1) {
      // Continue streak
      final newStreak = _profile.currentStreak + 1;
      _profile = _profile.copyWith(
        currentStreak: newStreak,
        longestStreak: max(_profile.longestStreak, newStreak),
      );

      // Award streak freeze token every 7 days
      if (newStreak % 7 == 0) {
        _profile = _profile.copyWith(
          streakFreezeTokens: _profile.streakFreezeTokens + 1,
        );
      }
    } else if (daysSinceLastSession > 1) {
      // Streak broken - check if can use freeze token
      if (_profile.streakFreezeTokens > 0) {
        // Could implement freeze token UI here
        debugPrint('Streak at risk! ${_profile.streakFreezeTokens} freeze tokens available');
      } else {
        // Reset streak
        _profile = _profile.copyWith(currentStreak: 1);
      }
    }
  }

  /// Use a streak freeze token
  void useStreakFreezeToken() {
    if (_profile.streakFreezeTokens <= 0) return;

    _profile = _profile.copyWith(
      streakFreezeTokens: _profile.streakFreezeTokens - 1,
    );

    notifyListeners();
    _saveState();
  }

  /// Unlock an achievement
  void unlockAchievement(String achievementId) {
    if (_profile.unlockedAchievements.contains(achievementId)) return;

    final updated = List<String>.from(_profile.unlockedAchievements)
      ..add(achievementId);

    _profile = _profile.copyWith(unlockedAchievements: updated);

    notifyListeners();
    _saveState();
  }

  /// Unlock a theme
  void unlockTheme(String themeId) {
    if (_profile.unlockedThemes.contains(themeId)) return;

    final updated = List<String>.from(_profile.unlockedThemes)..add(themeId);

    _profile = _profile.copyWith(unlockedThemes: updated);

    notifyListeners();
    _saveState();
  }

  /// Check if theme is unlocked
  bool isThemeUnlocked(String themeId) {
    return _profile.unlockedThemes.contains(themeId);
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _profile.unlockedAchievements.contains(achievementId);
  }

  /// Get streak status
  Map<String, dynamic> getStreakStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSession = _profile.lastSessionDate;

    bool isAtRisk = false;
    if (lastSession != null) {
      final lastSessionDay = DateTime(
        lastSession.year,
        lastSession.month,
        lastSession.day,
      );
      final daysSince = today.difference(lastSessionDay).inDays;
      isAtRisk = daysSince >= 1;
    }

    return {
      'current': _profile.currentStreak,
      'longest': _profile.longestStreak,
      'isAtRisk': isAtRisk,
      'freezeTokens': _profile.streakFreezeTokens,
    };
  }

  /// Load state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('gamification_profile');

      if (profileJson != null) {
        // In real implementation, parse JSON properly
        // _profile = UserProfile.fromJson(jsonDecode(profileJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading gamification state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In real implementation, encode JSON properly
      // await prefs.setString('gamification_profile', jsonEncode(_profile.toJson()));
      await prefs.setString('gamification_profile', _profile.toJson().toString());
    } catch (e) {
      debugPrint('Error saving gamification state: $e');
    }
  }
}
