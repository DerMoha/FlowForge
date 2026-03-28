import '../utils/date_helpers.dart';

/// Shared streak calculation logic.
class StreakService {
  const StreakService._();

  /// Check if the streak is still active based on the last session date.
  /// Returns the updated streak count.
  static int updateStreak({
    required int currentStreak,
    required DateTime? lastSessionDate,
    required int freezeTokens,
    DateTime? now,
  }) {
    final today = startOfDay(now ?? DateTime.now());

    if (lastSessionDate == null) {
      return 1; // First session ever
    }

    final lastDay = startOfDay(lastSessionDate);
    final daysDiff = today.difference(lastDay).inDays;

    if (daysDiff == 0) {
      return currentStreak; // Already counted today
    } else if (daysDiff == 1) {
      return currentStreak + 1; // Consecutive day
    } else if (daysDiff == 2 && freezeTokens > 0) {
      return currentStreak + 1; // Used a freeze token (skipped 1 day)
    } else {
      return 1; // Streak broken, start fresh
    }
  }

  /// Check if a freeze token should be consumed.
  static bool shouldConsumeFreezeToken({
    required DateTime? lastSessionDate,
    DateTime? now,
  }) {
    if (lastSessionDate == null) return false;

    final today = startOfDay(now ?? DateTime.now());
    final lastDay = startOfDay(lastSessionDate);
    return today.difference(lastDay).inDays == 2;
  }

  /// Check if the streak is at risk (last session was yesterday).
  static bool isStreakAtRisk({
    required DateTime? lastSessionDate,
    DateTime? now,
  }) {
    if (lastSessionDate == null) return false;

    final today = startOfDay(now ?? DateTime.now());
    final lastDay = startOfDay(lastSessionDate);
    return today.difference(lastDay).inDays >= 1;
  }
}
