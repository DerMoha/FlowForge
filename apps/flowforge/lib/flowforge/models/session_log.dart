class SessionLog {
  const SessionLog({required this.completedAt, required this.minutes});

  final DateTime completedAt;
  final int minutes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'completed_at': completedAt.toIso8601String(),
      'minutes': minutes,
    };
  }

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final rawTime = json['completed_at'];
    final rawMinutes = json['minutes'];
    if (rawTime is! String || rawMinutes is! int) {
      throw const FormatException('Invalid log payload');
    }

    final parsed = DateTime.tryParse(rawTime);
    if (parsed == null) {
      throw const FormatException('Invalid timestamp');
    }

    return SessionLog(completedAt: parsed, minutes: rawMinutes.clamp(1, 180));
  }
}
