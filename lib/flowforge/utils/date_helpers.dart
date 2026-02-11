bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}

String formatFullDate(DateTime dateTime) {
  const weekdays = <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  const months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
}
