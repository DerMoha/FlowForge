class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.date,
    required this.totalSessions,
    required this.totalMinutes,
    required this.tasksCompleted,
    required this.tasksCreated,
    required this.averageEnergy,
    required this.minEnergy,
    required this.maxEnergy,
    required this.energyLogs,
    this.firstSessionTime,
    this.lastSessionTime,
  });

  final DateTime date;
  final int totalSessions;
  final int totalMinutes;
  final int tasksCompleted;
  final int tasksCreated;
  final double averageEnergy;
  final int minEnergy;
  final int maxEnergy;
  final int energyLogs;
  final DateTime? firstSessionTime;
  final DateTime? lastSessionTime;

  /// Time span between first and last session (in hours)
  double? get workingHours {
    if (firstSessionTime == null || lastSessionTime == null) {
      return null;
    }
    return lastSessionTime!.difference(firstSessionTime!).inMinutes / 60.0;
  }

  /// Sessions per hour rate
  double? get sessionsPerHour {
    final hours = workingHours;
    if (hours == null || hours == 0) {
      return null;
    }
    return totalSessions / hours;
  }

  /// Average session duration
  double get averageSessionMinutes {
    if (totalSessions == 0) return 0;
    return totalMinutes / totalSessions;
  }

  /// Completion rate
  double get completionRate {
    if (tasksCreated == 0) return 0;
    return tasksCompleted / tasksCreated;
  }

  AnalyticsSnapshot copyWith({
    DateTime? date,
    int? totalSessions,
    int? totalMinutes,
    int? tasksCompleted,
    int? tasksCreated,
    double? averageEnergy,
    int? minEnergy,
    int? maxEnergy,
    int? energyLogs,
    DateTime? firstSessionTime,
    DateTime? lastSessionTime,
    bool clearFirstSessionTime = false,
    bool clearLastSessionTime = false,
  }) {
    return AnalyticsSnapshot(
      date: date ?? this.date,
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksCreated: tasksCreated ?? this.tasksCreated,
      averageEnergy: averageEnergy ?? this.averageEnergy,
      minEnergy: minEnergy ?? this.minEnergy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      energyLogs: energyLogs ?? this.energyLogs,
      firstSessionTime: clearFirstSessionTime
          ? null
          : (firstSessionTime ?? this.firstSessionTime),
      lastSessionTime: clearLastSessionTime
          ? null
          : (lastSessionTime ?? this.lastSessionTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'total_sessions': totalSessions,
      'total_minutes': totalMinutes,
      'tasks_completed': tasksCompleted,
      'tasks_created': tasksCreated,
      'average_energy': averageEnergy,
      'min_energy': minEnergy,
      'max_energy': maxEnergy,
      'energy_logs': energyLogs,
      'first_session_time': firstSessionTime?.toIso8601String(),
      'last_session_time': lastSessionTime?.toIso8601String(),
    };
  }

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return AnalyticsSnapshot(
      date: DateTime.parse(json['date'] as String),
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      tasksCreated: json['tasks_created'] as int? ?? 0,
      averageEnergy: (json['average_energy'] as num?)?.toDouble() ?? 0.0,
      minEnergy: json['min_energy'] as int? ?? 0,
      maxEnergy: json['max_energy'] as int? ?? 0,
      energyLogs: json['energy_logs'] as int? ?? 0,
      firstSessionTime: json['first_session_time'] != null
          ? DateTime.tryParse(json['first_session_time'] as String)
          : null,
      lastSessionTime: json['last_session_time'] != null
          ? DateTime.tryParse(json['last_session_time'] as String)
          : null,
    );
  }

  factory AnalyticsSnapshot.empty(DateTime date) {
    return AnalyticsSnapshot(
      date: date,
      totalSessions: 0,
      totalMinutes: 0,
      tasksCompleted: 0,
      tasksCreated: 0,
      averageEnergy: 0,
      minEnergy: 0,
      maxEnergy: 0,
      energyLogs: 0,
    );
  }
}

/// Energy data point for time-series analysis
class EnergyDataPoint {
  const EnergyDataPoint({required this.timestamp, required this.energy});

  final DateTime timestamp;
  final int energy;

  /// Hour of day (0-23)
  int get hourOfDay => timestamp.hour;

  /// Day of week (1=Monday, 7=Sunday)
  int get dayOfWeek => timestamp.weekday;

  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.toIso8601String(), 'energy': energy};
  }

  factory EnergyDataPoint.fromJson(Map<String, dynamic> json) {
    return EnergyDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      energy: json['energy'] as int,
    );
  }
}
