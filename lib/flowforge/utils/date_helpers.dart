enum DueGroup { overdue, today, thisWeek, later }

DateTime startOfDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

DateTime endOfDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
}

DateTime? normalizeDueDate(DateTime? dateTime) {
  if (dateTime == null) return null;
  return endOfDay(dateTime);
}

bool isOverdueDate(DateTime? deadline, {DateTime? now}) {
  if (deadline == null) return false;
  final currentDay = startOfDay(now ?? DateTime.now());
  final deadlineDay = startOfDay(deadline);
  return deadlineDay.isBefore(currentDay);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DueGroup groupByDueDate(DateTime? deadline) {
  if (deadline == null) return DueGroup.later;

  final today = startOfDay(DateTime.now());
  final deadlineDay = startOfDay(deadline);

  if (deadlineDay.isBefore(today)) return DueGroup.overdue;
  if (isSameDay(deadlineDay, today)) return DueGroup.today;

  final weekFromNow = today.add(const Duration(days: 7));
  if (deadlineDay.isBefore(weekFromNow)) return DueGroup.thisWeek;

  return DueGroup.later;
}

String formatDueDate(DateTime? deadline) {
  if (deadline == null) return '';

  final group = groupByDueDate(deadline);
  switch (group) {
    case DueGroup.overdue:
      final today = startOfDay(DateTime.now());
      final deadlineDay = startOfDay(deadline);
      final daysOverdue = today.difference(deadlineDay).inDays;
      if (daysOverdue == 1) return 'Overdue 1 day';
      return 'Overdue $daysOverdue days';
    case DueGroup.today:
      return 'Today';
    case DueGroup.thisWeek:
      final tomorrow = startOfDay(DateTime.now()).add(const Duration(days: 1));
      if (isSameDay(deadline, tomorrow)) return 'Tomorrow';
      return formatShortMonthDay(deadline);
    case DueGroup.later:
      return formatShortMonthDay(deadline);
  }
}

String formatShortMonthDay(DateTime dateTime) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}';
}

String formatCompactDate(DateTime dateTime) {
  const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
}

String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
}

String cleanSummary(String input, {required String fallback}) {
  final singleLine = input.trim().replaceAll('\n', ' ');
  if (singleLine.isEmpty) {
    return fallback;
  }
  return singleLine.endsWith('.') ? singleLine : '$singleLine.';
}

String formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final marker = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $marker';
}

String formatShortDate(DateTime dateTime) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}

String formatFullDate(DateTime dateTime) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
}
