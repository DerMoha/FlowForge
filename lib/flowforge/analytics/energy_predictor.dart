import 'dart:math';
import '../models/analytics_snapshot.dart';

/// Energy prediction engine using time-series analysis
class EnergyPredictor {
  EnergyPredictor._();

  static final instance = EnergyPredictor._();

  /// Predict energy level for a given time
  int? predictEnergy({
    required DateTime targetTime,
    required List<EnergyDataPoint> historicalData,
  }) {
    if (historicalData.isEmpty) return null;

    // Build time-of-day patterns
    final hourlyAverages = _calculateHourlyAverages(historicalData);

    // Build day-of-week multipliers
    final dayMultipliers = _calculateDayMultipliers(historicalData);

    // Get base prediction from hour of day
    final hour = targetTime.hour;
    final baseEnergy = hourlyAverages[hour];
    if (baseEnergy == null) return null;

    // Apply day-of-week adjustment
    final dayOfWeek = targetTime.weekday;
    final dayMultiplier = dayMultipliers[dayOfWeek] ?? 1.0;

    // Apply recent session boost
    final recentBoost = _calculateRecentBoost(historicalData, targetTime);

    // Combine factors
    final predictedEnergy = (baseEnergy * dayMultiplier + recentBoost).round();

    return predictedEnergy.clamp(25, 85);
  }

  /// Calculate average energy for each hour of day
  Map<int, double> _calculateHourlyAverages(List<EnergyDataPoint> data) {
    final hourBuckets = <int, List<int>>{};

    for (final point in data) {
      final hour = point.hourOfDay;
      hourBuckets.putIfAbsent(hour, () => []).add(point.energy);
    }

    final averages = <int, double>{};
    for (final entry in hourBuckets.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }

    return averages;
  }

  /// Calculate day-of-week multipliers (1=Monday, 7=Sunday)
  Map<int, double> _calculateDayMultipliers(List<EnergyDataPoint> data) {
    final dayBuckets = <int, List<int>>{};

    for (final point in data) {
      final day = point.dayOfWeek;
      dayBuckets.putIfAbsent(day, () => []).add(point.energy);
    }

    // Calculate average for each day
    final dayAverages = <int, double>{};
    for (final entry in dayBuckets.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      dayAverages[entry.key] = sum / entry.value.length;
    }

    // Convert to multipliers (relative to weekly average)
    final weeklyAverage = dayAverages.values.reduce((a, b) => a + b) / dayAverages.length;
    final multipliers = <int, double>{};
    for (final entry in dayAverages.entries) {
      multipliers[entry.key] = entry.value / weeklyAverage;
    }

    return multipliers;
  }

  /// Calculate boost from recent activity
  double _calculateRecentBoost(List<EnergyDataPoint> data, DateTime targetTime) {
    // Find recent data points (last 2 hours)
    final twoHoursAgo = targetTime.subtract(const Duration(hours: 2));
    final recentPoints = data.where((point) =>
      point.timestamp.isAfter(twoHoursAgo) &&
      point.timestamp.isBefore(targetTime)
    ).toList();

    if (recentPoints.isEmpty) return 0;

    // Calculate momentum (positive if energy is increasing)
    recentPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (recentPoints.length < 2) return 0;

    final first = recentPoints.first.energy;
    final last = recentPoints.last.energy;
    final momentum = last - first;

    // Apply exponential decay (more recent = more weight)
    final decay = 0.5; // Half-life of 30 minutes
    final timeDiff = targetTime.difference(recentPoints.last.timestamp).inMinutes;
    final weight = exp(-decay * timeDiff / 30);

    return momentum * weight * 0.2; // Scale down the boost
  }

  /// Get optimal next session timing based on predicted energy
  DateTime? suggestNextSession({
    required List<EnergyDataPoint> historicalData,
    required int requiredEnergy,
    DateTime? startFrom,
  }) {
    final now = startFrom ?? DateTime.now();
    final searchWindow = 12; // Search next 12 hours

    DateTime? bestTime;
    int bestEnergy = 0;

    for (var i = 0; i < searchWindow * 4; i++) {
      // Check every 15 minutes
      final candidateTime = now.add(Duration(minutes: i * 15));
      final predicted = predictEnergy(
        targetTime: candidateTime,
        historicalData: historicalData,
      );

      if (predicted != null && predicted >= requiredEnergy) {
        if (predicted > bestEnergy) {
          bestEnergy = predicted;
          bestTime = candidateTime;
        }
      }
    }

    return bestTime;
  }

  /// Analyze energy patterns and return insights
  EnergyInsights analyzePatterns(List<EnergyDataPoint> data) {
    if (data.isEmpty) {
      return EnergyInsights.empty();
    }

    // Find peak energy time
    final hourlyAverages = _calculateHourlyAverages(data);
    int peakHour = 0;
    double peakEnergy = 0;
    for (final entry in hourlyAverages.entries) {
      if (entry.value > peakEnergy) {
        peakEnergy = entry.value;
        peakHour = entry.key;
      }
    }

    // Find low energy time
    int lowHour = 0;
    double lowEnergy = 100;
    for (final entry in hourlyAverages.entries) {
      if (entry.value < lowEnergy) {
        lowEnergy = entry.value;
        lowHour = entry.key;
      }
    }

    // Calculate average energy by time of day
    final morningEnergy = _getAverageForTimeRange(hourlyAverages, 6, 12);
    final afternoonEnergy = _getAverageForTimeRange(hourlyAverages, 12, 17);
    final eveningEnergy = _getAverageForTimeRange(hourlyAverages, 17, 22);

    // Detect patterns
    final isMorningPerson = morningEnergy > afternoonEnergy && morningEnergy > eveningEnergy;
    final isNightOwl = eveningEnergy > morningEnergy && eveningEnergy > afternoonEnergy;

    // Calculate consistency (standard deviation)
    final allValues = data.map((p) => p.energy.toDouble()).toList();
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance = allValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / allValues.length;
    final stdDev = sqrt(variance);
    final consistency = 1.0 - (stdDev / mean).clamp(0.0, 1.0);

    return EnergyInsights(
      peakHour: peakHour,
      peakEnergy: peakEnergy.round(),
      lowHour: lowHour,
      lowEnergy: lowEnergy.round(),
      morningEnergy: morningEnergy.round(),
      afternoonEnergy: afternoonEnergy.round(),
      eveningEnergy: eveningEnergy.round(),
      isMorningPerson: isMorningPerson,
      isNightOwl: isNightOwl,
      consistency: consistency,
    );
  }

  double _getAverageForTimeRange(Map<int, double> hourlyAverages, int startHour, int endHour) {
    final values = <double>[];
    for (var hour = startHour; hour < endHour; hour++) {
      final value = hourlyAverages[hour];
      if (value != null) {
        values.add(value);
      }
    }

    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Generate productivity recommendations
  List<String> generateRecommendations(EnergyInsights insights) {
    final recommendations = <String>[];

    // Peak time recommendation
    final peakPeriod = _formatTimePeriod(insights.peakHour);
    recommendations.add(
      'Your energy peaks around $peakPeriod. Schedule deep work tasks then.'
    );

    // Morning person vs night owl
    if (insights.isMorningPerson) {
      recommendations.add(
        'You\'re a morning person! Tackle your most important tasks before noon.'
      );
    } else if (insights.isNightOwl) {
      recommendations.add(
        'You\'re a night owl! Your best work happens in the evening.'
      );
    }

    // Low energy time
    final lowPeriod = _formatTimePeriod(insights.lowHour);
    recommendations.add(
      'Energy dips around $lowPeriod. Consider a break or light tasks.'
    );

    // Consistency insight
    if (insights.consistency > 0.8) {
      recommendations.add(
        'Your energy levels are very consistent. Great routine!'
      );
    } else if (insights.consistency < 0.5) {
      recommendations.add(
        'Your energy varies significantly. Try to maintain a regular sleep schedule.'
      );
    }

    return recommendations;
  }

  String _formatTimePeriod(int hour) {
    if (hour < 6) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 22) return 'evening';
    return 'night';
  }
}

/// Energy pattern insights
class EnergyInsights {
  const EnergyInsights({
    required this.peakHour,
    required this.peakEnergy,
    required this.lowHour,
    required this.lowEnergy,
    required this.morningEnergy,
    required this.afternoonEnergy,
    required this.eveningEnergy,
    required this.isMorningPerson,
    required this.isNightOwl,
    required this.consistency,
  });

  final int peakHour;
  final int peakEnergy;
  final int lowHour;
  final int lowEnergy;
  final int morningEnergy;
  final int afternoonEnergy;
  final int eveningEnergy;
  final bool isMorningPerson;
  final bool isNightOwl;
  final double consistency;

  factory EnergyInsights.empty() {
    return const EnergyInsights(
      peakHour: 9,
      peakEnergy: 65,
      lowHour: 15,
      lowEnergy: 50,
      morningEnergy: 60,
      afternoonEnergy: 55,
      eveningEnergy: 50,
      isMorningPerson: false,
      isNightOwl: false,
      consistency: 0.5,
    );
  }
}
