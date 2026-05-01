import 'dart:math';

class UserProfile {
  const UserProfile({
    required this.totalXP,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakFreezeTokens,
    required this.unlockedAchievements,
    required this.unlockedThemes,
    required this.lifetimeStats,
    required this.lastSessionDate,
  });

  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezeTokens;
  final List<String> unlockedAchievements;
  final List<String> unlockedThemes;
  final LifetimeStats lifetimeStats;
  final DateTime? lastSessionDate;

  /// Calculate level from total XP using: floor(sqrt(totalXP / 100))
  int get level => (sqrt(totalXP / 100)).floor().clamp(1, 999);

  /// Get user title/rank based on level
  String get title {
    if (level >= 51) return 'Legend';
    if (level >= 36) return 'Grandmaster';
    if (level >= 21) return 'Master';
    if (level >= 11) return 'Expert';
    if (level >= 6) return 'Practitioner';
    return 'Apprentice';
  }

  /// XP required for current level
  int get currentLevelXP {
    return level * level * 100;
  }

  /// XP required for next level
  int get nextLevelXP {
    return (level + 1) * (level + 1) * 100;
  }

  /// Progress to next level (0.0 to 1.0)
  double get levelProgress {
    final current = currentLevelXP;
    final next = nextLevelXP;
    final progress = totalXP - current;
    final total = next - current;
    return (progress / total).clamp(0.0, 1.0);
  }

  /// XP remaining to next level
  int get xpToNextLevel {
    return max(0, nextLevelXP - totalXP);
  }

  UserProfile copyWith({
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    int? streakFreezeTokens,
    List<String>? unlockedAchievements,
    List<String>? unlockedThemes,
    LifetimeStats? lifetimeStats,
    DateTime? lastSessionDate,
    bool clearLastSessionDate = false,
  }) {
    return UserProfile(
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakFreezeTokens: streakFreezeTokens ?? this.streakFreezeTokens,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      lifetimeStats: lifetimeStats ?? this.lifetimeStats,
      lastSessionDate: clearLastSessionDate
          ? null
          : (lastSessionDate ?? this.lastSessionDate),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_xp': totalXP,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_freeze_tokens': streakFreezeTokens,
      'unlocked_achievements': unlockedAchievements,
      'unlocked_themes': unlockedThemes,
      'lifetime_stats': lifetimeStats.toJson(),
      'last_session_date': lastSessionDate?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      totalXP: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      streakFreezeTokens: json['streak_freeze_tokens'] as int? ?? 0,
      unlockedAchievements:
          (json['unlocked_achievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      unlockedThemes:
          (json['unlocked_themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lifetimeStats: json['lifetime_stats'] != null
          ? LifetimeStats.fromJson(
              json['lifetime_stats'] as Map<String, dynamic>,
            )
          : const LifetimeStats(),
      lastSessionDate: json['last_session_date'] != null
          ? DateTime.tryParse(json['last_session_date'] as String)
          : null,
    );
  }

  factory UserProfile.initial() {
    return UserProfile(
      totalXP: 0,
      currentStreak: 0,
      longestStreak: 0,
      streakFreezeTokens: 0,
      unlockedAchievements: const [],
      unlockedThemes: const ['default'],
      lifetimeStats: const LifetimeStats(),
      lastSessionDate: null,
    );
  }
}

class LifetimeStats {
  const LifetimeStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.totalTasksCompleted = 0,
    this.totalDeepTasksCompleted = 0,
    this.longestSessionMinutes = 0,
    this.perfectWeeks = 0,
  });

  final int totalSessions;
  final int totalMinutes;
  final int totalTasksCompleted;
  final int totalDeepTasksCompleted;
  final int longestSessionMinutes;
  final int perfectWeeks;

  LifetimeStats copyWith({
    int? totalSessions,
    int? totalMinutes,
    int? totalTasksCompleted,
    int? totalDeepTasksCompleted,
    int? longestSessionMinutes,
    int? perfectWeeks,
  }) {
    return LifetimeStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalDeepTasksCompleted:
          totalDeepTasksCompleted ?? this.totalDeepTasksCompleted,
      longestSessionMinutes:
          longestSessionMinutes ?? this.longestSessionMinutes,
      perfectWeeks: perfectWeeks ?? this.perfectWeeks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_minutes': totalMinutes,
      'total_tasks_completed': totalTasksCompleted,
      'total_deep_tasks_completed': totalDeepTasksCompleted,
      'longest_session_minutes': longestSessionMinutes,
      'perfect_weeks': perfectWeeks,
    };
  }

  factory LifetimeStats.fromJson(Map<String, dynamic> json) {
    return LifetimeStats(
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
      totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
      totalDeepTasksCompleted: json['total_deep_tasks_completed'] as int? ?? 0,
      longestSessionMinutes: json['longest_session_minutes'] as int? ?? 0,
      perfectWeeks: json['perfect_weeks'] as int? ?? 0,
    );
  }
}
