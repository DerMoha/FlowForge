import 'package:flutter/material.dart';

enum AchievementCategory {
  streaks,
  sessions,
  tasks,
  energy,
  speed,
  special,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

extension AchievementRarityX on AchievementRarity {
  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFF78909C);
      case AchievementRarity.rare:
        return const Color(0xFF42A5F5);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  String get label {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.targetValue,
    this.hiddenUntilUnlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int targetValue;
  final bool hiddenUntilUnlocked;

  /// Calculate progress percentage (0.0 to 1.0)
  double progress(int currentValue) {
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Check if achievement is unlocked
  bool isUnlocked(int currentValue) {
    return currentValue >= targetValue;
  }
}

/// All available achievements in the app
class Achievements {
  Achievements._();

  // Streaks
  static const firstStep = Achievement(
    id: 'first_step',
    title: 'First Step',
    description: 'Complete 1 day streak',
    icon: Icons.looks_one_rounded,
    category: AchievementCategory.streaks,
    rarity: AchievementRarity.common,
    targetValue: 1,
  );

  static const committed = Achievement(
    id: 'committed',
    title: 'Committed',
    description: 'Complete 7 day streak',
    icon: Icons.local_fire_department_rounded,
    category: AchievementCategory.streaks,
    rarity: AchievementRarity.common,
    targetValue: 7,
  );

  static const dedicated = Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Complete 30 day streak',
    icon: Icons.whatshot_rounded,
    category: AchievementCategory.streaks,
    rarity: AchievementRarity.rare,
    targetValue: 30,
  );

  static const unstoppable = Achievement(
    id: 'unstoppable',
    title: 'Unstoppable',
    description: 'Complete 100 day streak',
    icon: Icons.bolt_rounded,
    category: AchievementCategory.streaks,
    rarity: AchievementRarity.epic,
    targetValue: 100,
  );

  static const legendary = Achievement(
    id: 'legendary',
    title: 'Legendary',
    description: 'Complete 365 day streak',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.streaks,
    rarity: AchievementRarity.legendary,
    targetValue: 365,
  );

  // Sessions
  static const quickStart = Achievement(
    id: 'quick_start',
    title: 'Quick Start',
    description: 'Complete 10 focus sessions',
    icon: Icons.play_circle_rounded,
    category: AchievementCategory.sessions,
    rarity: AchievementRarity.common,
    targetValue: 10,
  );

  static const flowState = Achievement(
    id: 'flow_state',
    title: 'Flow State',
    description: 'Complete 100 focus sessions',
    icon: Icons.water_rounded,
    category: AchievementCategory.sessions,
    rarity: AchievementRarity.rare,
    targetValue: 100,
  );

  static const deepWorker = Achievement(
    id: 'deep_worker',
    title: 'Deep Worker',
    description: 'Complete 50 sessions of 60 minutes',
    icon: Icons.psychology_rounded,
    category: AchievementCategory.sessions,
    rarity: AchievementRarity.epic,
    targetValue: 50,
  );

  static const marathon = Achievement(
    id: 'marathon',
    title: 'Marathon',
    description: 'Complete a single 240 minute session',
    icon: Icons.timer_rounded,
    category: AchievementCategory.sessions,
    rarity: AchievementRarity.legendary,
    targetValue: 240,
  );

  // Tasks
  static const gettingStarted = Achievement(
    id: 'getting_started',
    title: 'Getting Started',
    description: 'Complete 10 tasks',
    icon: Icons.check_circle_rounded,
    category: AchievementCategory.tasks,
    rarity: AchievementRarity.common,
    targetValue: 10,
  );

  static const productive = Achievement(
    id: 'productive',
    title: 'Productive',
    description: 'Complete 100 tasks',
    icon: Icons.done_all_rounded,
    category: AchievementCategory.tasks,
    rarity: AchievementRarity.rare,
    targetValue: 100,
  );

  static const taskSlayer = Achievement(
    id: 'task_slayer',
    title: 'Task Slayer',
    description: 'Complete 500 tasks',
    icon: Icons.military_tech_rounded,
    category: AchievementCategory.tasks,
    rarity: AchievementRarity.epic,
    targetValue: 500,
  );

  static const deepDive = Achievement(
    id: 'deep_dive',
    title: 'Deep Dive',
    description: 'Complete 10 deep energy tasks',
    icon: Icons.rocket_launch_rounded,
    category: AchievementCategory.tasks,
    rarity: AchievementRarity.rare,
    targetValue: 10,
  );

  // Energy Management
  static const energyAware = Achievement(
    id: 'energy_aware',
    title: 'Energy Aware',
    description: 'Log energy 50 times',
    icon: Icons.psychology_alt_rounded,
    category: AchievementCategory.energy,
    rarity: AchievementRarity.common,
    targetValue: 50,
  );

  static const energyMaster = Achievement(
    id: 'energy_master',
    title: 'Energy Master',
    description: 'Maintain 65+ energy for 7 consecutive days',
    icon: Icons.battery_full_rounded,
    category: AchievementCategory.energy,
    rarity: AchievementRarity.epic,
    targetValue: 7,
  );

  static const recoveryKing = Achievement(
    id: 'recovery_king',
    title: 'Recovery King',
    description: 'Go from 25 to 85 energy in a single day',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.energy,
    rarity: AchievementRarity.rare,
    targetValue: 1,
  );

  // Speed Runs
  static const earlyBird = Achievement(
    id: 'early_bird',
    title: 'Early Bird',
    description: 'Complete a session before 6 AM',
    icon: Icons.wb_sunny_rounded,
    category: AchievementCategory.speed,
    rarity: AchievementRarity.rare,
    targetValue: 1,
  );

  static const nightOwl = Achievement(
    id: 'night_owl',
    title: 'Night Owl',
    description: 'Complete a session after 10 PM',
    icon: Icons.nightlight_round,
    category: AchievementCategory.speed,
    rarity: AchievementRarity.rare,
    targetValue: 1,
  );

  static const lightning = Achievement(
    id: 'lightning',
    title: 'Lightning',
    description: 'Complete a task faster than estimated',
    icon: Icons.flash_on_rounded,
    category: AchievementCategory.speed,
    rarity: AchievementRarity.common,
    targetValue: 1,
  );

  static const perfectionist = Achievement(
    id: 'perfectionist',
    title: 'Perfectionist',
    description: 'Complete a task in exactly the estimated time',
    icon: Icons.check_rounded,
    category: AchievementCategory.speed,
    rarity: AchievementRarity.epic,
    targetValue: 1,
  );

  // Special Events
  static const newYearNewMe = Achievement(
    id: 'new_year_new_me',
    title: 'New Year New Me',
    description: 'Complete a session on January 1st',
    icon: Icons.celebration_rounded,
    category: AchievementCategory.special,
    rarity: AchievementRarity.rare,
    targetValue: 1,
  );

  static const weekendWarrior = Achievement(
    id: 'weekend_warrior',
    title: 'Weekend Warrior',
    description: 'Complete sessions on both Saturday and Sunday',
    icon: Icons.weekend_rounded,
    category: AchievementCategory.special,
    rarity: AchievementRarity.common,
    targetValue: 1,
  );

  static const birthdayGrind = Achievement(
    id: 'birthday_grind',
    title: 'Birthday Grind',
    description: 'Complete a session on your birthday',
    icon: Icons.cake_rounded,
    category: AchievementCategory.special,
    rarity: AchievementRarity.legendary,
    targetValue: 1,
    hiddenUntilUnlocked: true,
  );

  static const perfectWeek = Achievement(
    id: 'perfect_week',
    title: 'Perfect Week',
    description: 'Complete at least one session every day for 7 days',
    icon: Icons.calendar_month_rounded,
    category: AchievementCategory.special,
    rarity: AchievementRarity.epic,
    targetValue: 1,
  );

  /// All achievements in the app
  static const List<Achievement> all = [
    // Streaks
    firstStep,
    committed,
    dedicated,
    unstoppable,
    legendary,
    // Sessions
    quickStart,
    flowState,
    deepWorker,
    marathon,
    // Tasks
    gettingStarted,
    productive,
    taskSlayer,
    deepDive,
    // Energy
    energyAware,
    energyMaster,
    recoveryKing,
    // Speed
    earlyBird,
    nightOwl,
    lightning,
    perfectionist,
    // Special
    newYearNewMe,
    weekendWarrior,
    birthdayGrind,
    perfectWeek,
  ];

  /// Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get achievements by category
  static List<Achievement> byCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Get achievements by rarity
  static List<Achievement> byRarity(AchievementRarity rarity) {
    return all.where((a) => a.rarity == rarity).toList();
  }
}
