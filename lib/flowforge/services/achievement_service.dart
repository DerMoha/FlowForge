import '../models/achievement.dart';
import '../models/session_log.dart';
import '../models/todo_item.dart';
import '../models/user_profile.dart';

/// Service for evaluating achievement criteria and detecting unlocks
class AchievementService {
  AchievementService._();

  static final instance = AchievementService._();

  /// Check all achievements and return newly unlocked ones
  List<Achievement> checkForNewAchievements(
    UserProfile profile,
    List<SessionLog> logs,
    List<TodoItem> tasks,
  ) {
    final newlyUnlocked = <Achievement>[];

    for (final achievement in Achievements.all) {
      // Skip if already unlocked
      if (profile.unlockedAchievements.contains(achievement.id)) {
        continue;
      }

      // Check if criteria is met
      final currentValue = _getCurrentValue(achievement, profile, logs, tasks);
      if (achievement.isUnlocked(currentValue)) {
        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  /// Get current progress for an achievement
  int _getCurrentValue(
    Achievement achievement,
    UserProfile profile,
    List<SessionLog> logs,
    List<TodoItem> tasks,
  ) {
    switch (achievement.id) {
      // Streaks
      case 'first_step':
      case 'committed':
      case 'dedicated':
      case 'unstoppable':
      case 'legendary':
        return profile.currentStreak;

      // Sessions
      case 'quick_start':
      case 'flow_state':
        return profile.lifetimeStats.totalSessions;

      case 'deep_worker':
        return logs.where((log) => log.minutes >= 60).length;

      case 'marathon':
        return logs.map((log) => log.minutes).fold<int>(0, (max, minutes) =>
          minutes > max ? minutes : max
        );

      // Tasks
      case 'getting_started':
      case 'productive':
      case 'task_slayer':
        return profile.lifetimeStats.totalTasksCompleted;

      case 'deep_dive':
        return profile.lifetimeStats.totalDeepTasksCompleted;

      // Energy
      case 'energy_aware':
        return logs.length; // Simplified: count of energy changes

      case 'energy_master':
        return _countConsecutiveHighEnergyDays(logs);

      case 'recovery_king':
        return _checkEnergyRecovery(logs) ? 1 : 0;

      // Speed
      case 'early_bird':
        return logs.any((log) => log.completedAt.hour < 6) ? 1 : 0;

      case 'night_owl':
        return logs.any((log) => log.completedAt.hour >= 22) ? 1 : 0;

      case 'lightning':
        return tasks.any((task) =>
          task.estimationAccuracy != null && task.estimationAccuracy! < 1.0
        ) ? 1 : 0;

      case 'perfectionist':
        return tasks.any((task) =>
          task.estimationAccuracy != null &&
          (task.estimationAccuracy! - 1.0).abs() < 0.05
        ) ? 1 : 0;

      // Special
      case 'new_year_new_me':
        return logs.any((log) =>
          log.completedAt.month == 1 && log.completedAt.day == 1
        ) ? 1 : 0;

      case 'weekend_warrior':
        return _checkWeekendSessions(logs) ? 1 : 0;

      case 'birthday_grind':
        // This would need user birthday from profile
        return 0;

      case 'perfect_week':
        return profile.lifetimeStats.perfectWeeks;

      default:
        return 0;
    }
  }

  int _countConsecutiveHighEnergyDays(List<SessionLog> logs) {
    // Simplified: would need actual energy logs
    // For now, return 0
    return 0;
  }

  bool _checkEnergyRecovery(List<SessionLog> logs) {
    // Simplified: would need actual energy logs
    // Check if went from 25 to 85 in a single day
    return false;
  }

  bool _checkWeekendSessions(List<SessionLog> logs) {
    if (logs.length < 2) return false;

    // Find the most recent weekend
    final now = DateTime.now();
    var saturday = now;
    while (saturday.weekday != DateTime.saturday) {
      saturday = saturday.subtract(const Duration(days: 1));
    }
    final sunday = saturday.add(const Duration(days: 1));
    final mondayStart = sunday.add(const Duration(days: 1));

    final saturdayStart = DateTime(saturday.year, saturday.month, saturday.day);
    final sundayEnd = DateTime(mondayStart.year, mondayStart.month, mondayStart.day);

    final hasSaturday = logs.any((log) =>
      log.completedAt.isAfter(saturdayStart) &&
      log.completedAt.isBefore(saturdayStart.add(const Duration(days: 1)))
    );

    final hasSunday = logs.any((log) =>
      log.completedAt.isAfter(sunday) &&
      log.completedAt.isBefore(sundayEnd)
    );

    return hasSaturday && hasSunday;
  }

  /// Get progress for a specific achievement (0.0 to 1.0)
  double getAchievementProgress(
    Achievement achievement,
    UserProfile profile,
    List<SessionLog> logs,
    List<TodoItem> tasks,
  ) {
    final currentValue = _getCurrentValue(achievement, profile, logs, tasks);
    return achievement.progress(currentValue);
  }

  /// Get all achievements with progress
  Map<Achievement, double> getAllProgress(
    UserProfile profile,
    List<SessionLog> logs,
    List<TodoItem> tasks,
  ) {
    final progress = <Achievement, double>{};

    for (final achievement in Achievements.all) {
      progress[achievement] = getAchievementProgress(
        achievement,
        profile,
        logs,
        tasks,
      );
    }

    return progress;
  }
}
