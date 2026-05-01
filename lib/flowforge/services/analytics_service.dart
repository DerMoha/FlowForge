import '../models/analytics_snapshot.dart';
import '../models/session_log.dart';
import '../models/todo_item.dart';

/// Service for analyzing productivity patterns and generating insights
class AnalyticsService {
  AnalyticsService._();

  static final instance = AnalyticsService._();

  /// Analyze peak performance times from session logs
  Map<int, double> analyzePeakTimes(List<SessionLog> logs) {
    final hourCounts = <int, int>{};
    final hourMinutes = <int, int>{};

    for (final log in logs) {
      final hour = log.completedAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      hourMinutes[hour] = (hourMinutes[hour] ?? 0) + log.minutes;
    }

    // Calculate productivity score per hour (sessions * minutes)
    final productivity = <int, double>{};
    for (final hour in hourCounts.keys) {
      final score = (hourCounts[hour]! * hourMinutes[hour]!).toDouble();
      productivity[hour] = score;
    }

    return productivity;
  }

  /// Analyze energy patterns by time of day
  Map<int, double> analyzeEnergyPatterns(List<EnergyDataPoint> dataPoints) {
    final hourEnergy = <int, List<int>>{};

    for (final point in dataPoints) {
      final hour = point.hourOfDay;
      hourEnergy.putIfAbsent(hour, () => []).add(point.energy);
    }

    // Calculate average energy per hour
    final averages = <int, double>{};
    for (final entry in hourEnergy.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }

    return averages;
  }

  /// Analyze task duration accuracy
  double analyzeEstimationAccuracy(List<TodoItem> completedTasks) {
    final accuracies = completedTasks
        .where((task) => task.estimationAccuracy != null)
        .map((task) => task.estimationAccuracy!)
        .toList();

    if (accuracies.isEmpty) return 1.0;

    final sum = accuracies.reduce((a, b) => a + b);
    return sum / accuracies.length;
  }

  /// Calculate productivity velocity (tasks per week)
  double calculateVelocity(List<TodoItem> tasks, int weeks) {
    if (weeks == 0) return 0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: weeks * 7));

    final recentCompletions = tasks
        .where(
          (task) =>
              task.isDone &&
              task.completedAt != null &&
              task.completedAt!.isAfter(cutoff),
        )
        .length;

    return recentCompletions / weeks;
  }

  /// Calculate focus quality score (completion rate)
  double calculateFocusQuality(List<SessionLog> logs, List<TodoItem> tasks) {
    if (logs.isEmpty) return 0;

    final totalSessions = logs.length;
    final completedTasks = tasks.where((t) => t.isDone).length;

    // Basic metric: completed tasks per session
    return (completedTasks / totalSessions).clamp(0, 10);
  }

  /// Detect burnout risk (consecutive low-energy days)
  int detectBurnoutRisk(List<EnergyDataPoint> recentData) {
    if (recentData.isEmpty) return 0;

    // Group by day and calculate daily average
    final dailyAverages = <DateTime, List<int>>{};
    for (final point in recentData) {
      final day = DateTime(
        point.timestamp.year,
        point.timestamp.month,
        point.timestamp.day,
      );
      dailyAverages.putIfAbsent(day, () => []).add(point.energy);
    }

    // Count consecutive low-energy days (< 50)
    var consecutiveLowDays = 0;
    var maxConsecutive = 0;

    final sortedDays = dailyAverages.keys.toList()..sort();
    for (final day in sortedDays) {
      final avg =
          dailyAverages[day]!.reduce((a, b) => a + b) /
          dailyAverages[day]!.length;
      if (avg < 50) {
        consecutiveLowDays++;
        if (consecutiveLowDays > maxConsecutive) {
          maxConsecutive = consecutiveLowDays;
        }
      } else {
        consecutiveLowDays = 0;
      }
    }

    return maxConsecutive;
  }

  /// Generate actionable insights
  List<String> generateInsights(
    List<SessionLog> logs,
    List<TodoItem> tasks,
    List<EnergyDataPoint> energyData,
  ) {
    final insights = <String>[];

    // Peak time insight
    final peakTimes = analyzePeakTimes(logs);
    if (peakTimes.isNotEmpty) {
      final bestHour = peakTimes.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final period = bestHour < 12
          ? 'morning'
          : (bestHour < 17 ? 'afternoon' : 'evening');
      insights.add(
        'You\'re most productive in the $period (around $bestHour:00)',
      );
    }

    // Energy pattern insight
    final energyPatterns = analyzeEnergyPatterns(energyData);
    if (energyPatterns.isNotEmpty) {
      final highEnergyHour = energyPatterns.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insights.add('Your energy peaks around $highEnergyHour:00');
    }

    // Velocity insight
    final velocity = calculateVelocity(tasks, 4);
    if (velocity > 0) {
      insights.add(
        'You complete an average of ${velocity.toStringAsFixed(1)} tasks per week',
      );
    }

    // Burnout warning
    final burnoutRisk = detectBurnoutRisk(energyData);
    if (burnoutRisk >= 3) {
      insights.add(
        'Warning: $burnoutRisk consecutive low-energy days detected. Consider rest.',
      );
    }

    return insights;
  }

  /// Create daily analytics snapshot
  AnalyticsSnapshot createDailySnapshot(
    DateTime date,
    List<SessionLog> logs,
    List<TodoItem> tasks,
    List<EnergyDataPoint> energyData,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final daySessions = logs
        .where(
          (log) =>
              log.completedAt.isAfter(dayStart) &&
              log.completedAt.isBefore(dayEnd),
        )
        .toList();

    final dayEnergy = energyData
        .where(
          (point) =>
              point.timestamp.isAfter(dayStart) &&
              point.timestamp.isBefore(dayEnd),
        )
        .toList();

    final tasksCompleted = tasks
        .where(
          (task) =>
              task.isDone &&
              task.completedAt != null &&
              task.completedAt!.isAfter(dayStart) &&
              task.completedAt!.isBefore(dayEnd),
        )
        .length;

    final tasksCreated = tasks
        .where(
          (task) =>
              task.createdAt.isAfter(dayStart) &&
              task.createdAt.isBefore(dayEnd),
        )
        .length;

    final totalMinutes = daySessions.fold<int>(
      0,
      (sum, log) => sum + log.minutes,
    );

    double avgEnergy = 0;
    int minEnergy = 0;
    int maxEnergy = 0;
    if (dayEnergy.isNotEmpty) {
      final energyValues = dayEnergy.map((p) => p.energy).toList();
      avgEnergy = energyValues.reduce((a, b) => a + b) / energyValues.length;
      minEnergy = energyValues.reduce((a, b) => a < b ? a : b);
      maxEnergy = energyValues.reduce((a, b) => a > b ? a : b);
    }

    DateTime? firstSessionTime;
    DateTime? lastSessionTime;
    if (daySessions.isNotEmpty) {
      firstSessionTime = daySessions.first.completedAt;
      lastSessionTime = daySessions.last.completedAt;
    }

    return AnalyticsSnapshot(
      date: dayStart,
      totalSessions: daySessions.length,
      totalMinutes: totalMinutes,
      tasksCompleted: tasksCompleted,
      tasksCreated: tasksCreated,
      averageEnergy: avgEnergy,
      minEnergy: minEnergy,
      maxEnergy: maxEnergy,
      energyLogs: dayEnergy.length,
      firstSessionTime: firstSessionTime,
      lastSessionTime: lastSessionTime,
    );
  }
}
