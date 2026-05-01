enum RecurrencePattern { daily, weekdays, weekly, biweekly, monthly }

extension RecurrencePatternX on RecurrencePattern {
  String get label {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekdays:
        return 'Weekdays';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.biweekly:
        return 'Biweekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
    }
  }

  String get description {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Repeats every day';
      case RecurrencePattern.weekdays:
        return 'Repeats Monday through Friday';
      case RecurrencePattern.weekly:
        return 'Repeats once a week';
      case RecurrencePattern.biweekly:
        return 'Repeats every two weeks';
      case RecurrencePattern.monthly:
        return 'Repeats once a month';
    }
  }
}

class RecurrenceRule {
  const RecurrenceRule({
    required this.pattern,
    required this.startDate,
    this.endDate,
    this.specificDaysOfWeek,
    this.dayOfMonth,
  });

  final RecurrencePattern pattern;
  final DateTime startDate;
  final DateTime? endDate;

  /// For weekly/biweekly patterns: which days of week (1=Monday, 7=Sunday)
  final List<int>? specificDaysOfWeek;

  /// For monthly patterns: which day of month (1-31)
  final int? dayOfMonth;

  /// Calculate the next occurrence after the given date
  DateTime? nextOccurrence(DateTime after) {
    if (endDate != null && after.isAfter(endDate!)) {
      return null;
    }

    final normalizedAfter = DateTime(after.year, after.month, after.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (normalizedAfter.isBefore(normalizedStart)) {
      return startDate;
    }

    switch (pattern) {
      case RecurrencePattern.daily:
        return _nextDaily(normalizedAfter);
      case RecurrencePattern.weekdays:
        return _nextWeekday(normalizedAfter);
      case RecurrencePattern.weekly:
        return _nextWeekly(normalizedAfter);
      case RecurrencePattern.biweekly:
        return _nextBiweekly(normalizedAfter);
      case RecurrencePattern.monthly:
        return _nextMonthly(normalizedAfter);
    }
  }

  DateTime _nextDaily(DateTime after) {
    final next = after.add(const Duration(days: 1));
    if (endDate != null && next.isAfter(endDate!)) {
      return endDate!;
    }
    return next;
  }

  DateTime _nextWeekday(DateTime after) {
    var next = after.add(const Duration(days: 1));

    // Skip to next weekday
    while (next.weekday == DateTime.saturday ||
        next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }

    if (endDate != null && next.isAfter(endDate!)) {
      return endDate!;
    }
    return next;
  }

  DateTime _nextWeekly(DateTime after) {
    final days = specificDaysOfWeek ?? [startDate.weekday];
    var next = after.add(const Duration(days: 1));

    // Find next matching day of week
    for (var i = 0; i < 14; i++) {
      if (days.contains(next.weekday)) {
        if (endDate != null && next.isAfter(endDate!)) {
          return endDate!;
        }
        return next;
      }
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  DateTime _nextBiweekly(DateTime after) {
    final daysDiff = after.difference(startDate).inDays;
    final weeksSinceStart = daysDiff ~/ 7;
    final isOnCycle = weeksSinceStart % 2 == 0;

    if (isOnCycle) {
      return _nextWeekly(after);
    } else {
      // Skip to next cycle
      final daysToNextCycle = 7 - (daysDiff % 7);
      final next = after.add(Duration(days: daysToNextCycle));
      if (endDate != null && next.isAfter(endDate!)) {
        return endDate!;
      }
      return next;
    }
  }

  DateTime _nextMonthly(DateTime after) {
    final targetDay = dayOfMonth ?? startDate.day;
    var next = DateTime(after.year, after.month, targetDay);

    // If target day already passed this month, move to next month
    if (next.isBefore(after) || next.isAtSameMomentAs(after)) {
      next = DateTime(after.year, after.month + 1, targetDay);
    }

    // Handle months with fewer days
    if (next.day != targetDay) {
      // Target day doesn't exist in this month, use last day
      next = DateTime(next.year, next.month + 1, 0);
    }

    if (endDate != null && next.isAfter(endDate!)) {
      return endDate!;
    }
    return next;
  }

  /// Check if a date matches this recurrence pattern
  bool matches(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (normalized.isBefore(normalizedStart)) {
      return false;
    }

    if (endDate != null && normalized.isAfter(endDate!)) {
      return false;
    }

    switch (pattern) {
      case RecurrencePattern.daily:
        return true;
      case RecurrencePattern.weekdays:
        return normalized.weekday >= DateTime.monday &&
            normalized.weekday <= DateTime.friday;
      case RecurrencePattern.weekly:
        final days = specificDaysOfWeek ?? [startDate.weekday];
        return days.contains(normalized.weekday);
      case RecurrencePattern.biweekly:
        final daysDiff = normalized.difference(normalizedStart).inDays;
        final weeksSinceStart = daysDiff ~/ 7;
        final isOnCycle = weeksSinceStart % 2 == 0;
        final days = specificDaysOfWeek ?? [startDate.weekday];
        return isOnCycle && days.contains(normalized.weekday);
      case RecurrencePattern.monthly:
        final targetDay = dayOfMonth ?? startDate.day;
        return normalized.day == targetDay;
    }
  }

  RecurrenceRule copyWith({
    RecurrencePattern? pattern,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? specificDaysOfWeek,
    int? dayOfMonth,
    bool clearEndDate = false,
    bool clearSpecificDaysOfWeek = false,
    bool clearDayOfMonth = false,
  }) {
    return RecurrenceRule(
      pattern: pattern ?? this.pattern,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      specificDaysOfWeek: clearSpecificDaysOfWeek
          ? null
          : (specificDaysOfWeek ?? this.specificDaysOfWeek),
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'specific_days_of_week': specificDaysOfWeek,
      'day_of_month': dayOfMonth,
    };
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      pattern: RecurrencePattern.values.firstWhere(
        (p) => p.name == json['pattern'],
        orElse: () => RecurrencePattern.daily,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      specificDaysOfWeek: (json['specific_days_of_week'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      dayOfMonth: json['day_of_month'] as int?,
    );
  }
}
