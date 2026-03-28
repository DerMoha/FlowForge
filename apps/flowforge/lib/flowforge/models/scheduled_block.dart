class ScheduledBlock {
  const ScheduledBlock({
    required this.taskId,
    required this.taskTitle,
    required this.start,
    required this.end,
    this.calendarUid,
  });

  final String taskId;
  final String taskTitle;
  final DateTime start;
  final DateTime end;
  final String? calendarUid;

  factory ScheduledBlock.fromJson(Map<String, dynamic> json) {
    return ScheduledBlock(
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      calendarUid: json['calendarUid'] as String?,
    );
  }
}

class UnschedulableTask {
  const UnschedulableTask({
    required this.taskId,
    required this.taskTitle,
    required this.reason,
  });

  final String taskId;
  final String taskTitle;
  final String reason;

  factory UnschedulableTask.fromJson(Map<String, dynamic> json) {
    return UnschedulableTask(
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      reason: json['reason'] as String,
    );
  }
}
