import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analytics_snapshot.dart';
import '../services/analytics_service.dart';

/// Manages analytics, insights, and predictions
class AnalyticsState extends ChangeNotifier {
  final Map<DateTime, AnalyticsSnapshot> _snapshots = {};
  final List<EnergyDataPoint> _energyHistory = [];
  final List<String> _insights = [];

  Map<DateTime, AnalyticsSnapshot> get snapshots => Map.unmodifiable(_snapshots);
  List<EnergyDataPoint> get energyHistory => List.unmodifiable(_energyHistory);
  List<String> get insights => List.unmodifiable(_insights);

  /// Initialize state
  Future<void> init() async {
    await _loadState();
  }

  /// Log energy data point
  void logEnergyDataPoint(int energy) {
    final dataPoint = EnergyDataPoint(
      timestamp: DateTime.now(),
      energy: energy,
    );

    _energyHistory.add(dataPoint);

    // Keep only last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    _energyHistory.removeWhere((point) => point.timestamp.isBefore(cutoff));

    notifyListeners();
    _saveState();
  }

  /// Add daily snapshot
  void addSnapshot(AnalyticsSnapshot snapshot) {
    _snapshots[snapshot.date] = snapshot;

    // Keep only last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    _snapshots.removeWhere((date, _) => date.isBefore(cutoff));

    notifyListeners();
    _saveState();
  }

  /// Get snapshot for a specific date
  AnalyticsSnapshot? getSnapshot(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _snapshots[normalized];
  }

  /// Get snapshots for date range
  List<AnalyticsSnapshot> getSnapshotsInRange(DateTime start, DateTime end) {
    return _snapshots.entries
        .where((entry) =>
            !entry.key.isBefore(start) && !entry.key.isAfter(end))
        .map((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Regenerate insights
  void regenerateInsights({
    required List<dynamic> logs,
    required List<dynamic> tasks,
  }) {
    try {
      _insights.clear();
      // In real implementation, call analytics service
      // _insights = AnalyticsService.instance.generateInsights(logs, tasks, _energyHistory);
      notifyListeners();
    } catch (e) {
      debugPrint('Error regenerating insights: $e');
    }
  }

  /// Predict energy for time of day
  int? predictEnergyForTime(DateTime time) {
    if (_energyHistory.isEmpty) return null;

    final hour = time.hour;
    final dayOfWeek = time.weekday;

    // Get data points for this hour and day of week
    final relevantPoints = _energyHistory.where((point) =>
      point.hourOfDay == hour && point.dayOfWeek == dayOfWeek
    ).toList();

    if (relevantPoints.isEmpty) {
      // Fall back to just hour
      final hourPoints = _energyHistory.where((point) =>
        point.hourOfDay == hour
      ).toList();

      if (hourPoints.isEmpty) return null;

      final sum = hourPoints.fold<int>(0, (sum, point) => sum + point.energy);
      return sum ~/ hourPoints.length;
    }

    final sum = relevantPoints.fold<int>(0, (sum, point) => sum + point.energy);
    return sum ~/ relevantPoints.length;
  }

  /// Get peak productivity times (hours of day)
  List<int> getPeakProductivityHours() {
    if (_snapshots.isEmpty) return [];

    final hourScores = <int, double>{};

    for (final snapshot in _snapshots.values) {
      if (snapshot.firstSessionTime != null) {
        final hour = snapshot.firstSessionTime!.hour;
        hourScores[hour] = (hourScores[hour] ?? 0) + snapshot.totalMinutes.toDouble();
      }
    }

    final sorted = hourScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Calculate average daily sessions
  double getAverageDailySessions(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentSnapshots = _snapshots.values
        .where((s) => s.date.isAfter(cutoff))
        .toList();

    if (recentSnapshots.isEmpty) return 0;

    final totalSessions = recentSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.totalSessions,
    );

    return totalSessions / days;
  }

  /// Calculate average daily minutes
  double getAverageDailyMinutes(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentSnapshots = _snapshots.values
        .where((s) => s.date.isAfter(cutoff))
        .toList();

    if (recentSnapshots.isEmpty) return 0;

    final totalMinutes = recentSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.totalMinutes,
    );

    return totalMinutes / days;
  }

  /// Load state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load energy history
      final energyJson = prefs.getStringList('analytics_energy_history') ?? [];
      _energyHistory.clear();
      for (final json in energyJson) {
        try {
          // In real implementation, parse JSON properly
          // _energyHistory.add(EnergyDataPoint.fromJson(jsonDecode(json)));
        } catch (_) {
          continue;
        }
      }

      // Load snapshots
      final snapshotsJson = prefs.getStringList('analytics_snapshots') ?? [];
      _snapshots.clear();
      for (final json in snapshotsJson) {
        try {
          // In real implementation, parse JSON properly
          // final snapshot = AnalyticsSnapshot.fromJson(jsonDecode(json));
          // _snapshots[snapshot.date] = snapshot;
        } catch (_) {
          continue;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save energy history
      final energyJson = _energyHistory
          .map((point) => point.toJson().toString())
          .toList();
      await prefs.setStringList('analytics_energy_history', energyJson);

      // Save snapshots
      final snapshotsJson = _snapshots.values
          .map((snapshot) => snapshot.toJson().toString())
          .toList();
      await prefs.setStringList('analytics_snapshots', snapshotsJson);
    } catch (e) {
      debugPrint('Error saving analytics state: $e');
    }
  }
}
