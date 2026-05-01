import 'dart:math';

/// Shared XP calculation logic used by both FlowForge and AI Tutor.
class XpService {
  const XpService._();

  /// Calculate level from total XP: floor(sqrt(totalXP / 100)), clamped 1-999.
  static int levelFromXp(int totalXP) {
    return (sqrt(totalXP / 100)).floor().clamp(1, 999);
  }

  /// XP required to reach a given level.
  static int xpForLevel(int level) {
    return level * level * 100;
  }

  /// Progress fraction (0.0-1.0) within the current level.
  static double levelProgress(int totalXP) {
    final level = levelFromXp(totalXP);
    final current = xpForLevel(level);
    final next = xpForLevel(level + 1);
    return ((totalXP - current) / (next - current)).clamp(0.0, 1.0);
  }

  /// XP remaining to reach the next level.
  static int xpToNextLevel(int totalXP) {
    final level = levelFromXp(totalXP);
    return max(0, xpForLevel(level + 1) - totalXP);
  }

  /// Title/rank for a given level.
  static String titleForLevel(int level) {
    if (level >= 51) return 'Legend';
    if (level >= 36) return 'Grandmaster';
    if (level >= 21) return 'Master';
    if (level >= 11) return 'Expert';
    if (level >= 6) return 'Practitioner';
    return 'Apprentice';
  }

  /// Calculate XP earned for a focus session.
  static int focusSessionXp({required int minutes, bool isDeepTask = false}) {
    final base = minutes * 2;
    final multiplier = isDeepTask ? 2.0 : 1.0;
    return (base * multiplier).round();
  }

  /// Calculate XP earned for completing a quiz.
  static int quizXp({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions == 0) return 0;
    final accuracy = correctAnswers / totalQuestions;
    return (50 * accuracy).round();
  }

  /// Calculate XP earned for a study session in AI Tutor.
  static int studySessionXp({required int minutes}) {
    return minutes * 2;
  }
}
