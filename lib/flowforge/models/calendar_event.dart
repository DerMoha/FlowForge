class CalendarEvent {
  const CalendarEvent({
    required this.uid,
    required this.summary,
    required this.start,
    required this.end,
    this.location,
    this.isBlocker = false,
    this.isFlowForgeTask = false,
  });

  final String uid;
  final String summary;
  final DateTime start;
  final DateTime end;
  final String? location;
  final bool isBlocker;
  final bool isFlowForgeTask;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      uid: json['uid'] as String,
      summary: json['summary'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      location: json['location'] as String?,
      isBlocker: json['isBlocker'] as bool? ?? false,
      isFlowForgeTask: json['isFlowForgeTask'] as bool? ?? false,
    );
  }
}
