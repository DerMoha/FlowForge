import 'task_energy_requirement.dart';
import 'task_status.dart';
import 'recurrence_rule.dart';
import '../utils/date_helpers.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.energyRequirement,
    required this.estimateMinutes,
    required this.status,
    this.projectId,
    this.blockedBy,
    this.tags,
    this.priority,
    this.deadline,
    this.recurrence,
    this.completedAt,
    this.actualMinutes,
    this.scheduledStart,
    this.scheduledCalendarUid,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final TaskEnergyRequirement energyRequirement;
  final int estimateMinutes;
  final TaskStatus status;

  // New fields for advanced features
  final String? projectId;
  final List<String>? blockedBy; // Task IDs that block this task
  final List<String>? tags;
  final int? priority; // 1-5 scale (1=highest)
  final DateTime? deadline;
  final RecurrenceRule? recurrence;
  final DateTime? completedAt;
  final int? actualMinutes; // Actual time spent
  final DateTime? scheduledStart; // Auto-scheduled start time
  final String? scheduledCalendarUid; // Calendar event UID for scheduled block

  /// Is this task blocked by incomplete dependencies?
  bool isBlocked(List<TodoItem> allTodos) {
    if (blockedBy == null || blockedBy!.isEmpty) return false;
    return allTodos.any((todo) => blockedBy!.contains(todo.id) && !todo.isDone);
  }

  /// Is this task overdue?
  bool get isOverdue {
    if (deadline == null || isDone) return false;
    return isOverdueDate(deadline);
  }

  /// Get time estimation accuracy (1.0 = perfect, <1 = faster, >1 = slower)
  double? get estimationAccuracy {
    if (actualMinutes == null || estimateMinutes == 0) return null;
    return actualMinutes! / estimateMinutes;
  }

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
    TaskEnergyRequirement? energyRequirement,
    int? estimateMinutes,
    TaskStatus? status,
    String? projectId,
    List<String>? blockedBy,
    List<String>? tags,
    int? priority,
    DateTime? deadline,
    RecurrenceRule? recurrence,
    DateTime? completedAt,
    int? actualMinutes,
    bool clearProjectId = false,
    bool clearBlockedBy = false,
    bool clearTags = false,
    bool clearPriority = false,
    bool clearDeadline = false,
    bool clearRecurrence = false,
    bool clearCompletedAt = false,
    bool clearActualMinutes = false,
    DateTime? scheduledStart,
    String? scheduledCalendarUid,
    bool clearScheduledStart = false,
    bool clearScheduledCalendarUid = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      energyRequirement: energyRequirement ?? this.energyRequirement,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      status: status ?? this.status,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      blockedBy: clearBlockedBy ? null : (blockedBy ?? this.blockedBy),
      tags: clearTags ? null : (tags ?? this.tags),
      priority: clearPriority ? null : (priority ?? this.priority),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      actualMinutes: clearActualMinutes
          ? null
          : (actualMinutes ?? this.actualMinutes),
      scheduledStart: clearScheduledStart
          ? null
          : (scheduledStart ?? this.scheduledStart),
      scheduledCalendarUid: clearScheduledCalendarUid
          ? null
          : (scheduledCalendarUid ?? this.scheduledCalendarUid),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'is_done': isDone,
      'created_at': createdAt.toIso8601String(),
      'energy_requirement': energyRequirement.storageValue,
      'estimate_minutes': estimateMinutes,
      'status': status.storageValue,
      'project_id': projectId,
      'blocked_by': blockedBy,
      'tags': tags,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'recurrence': recurrence?.toJson(),
      'completed_at': completedAt?.toIso8601String(),
      'actual_minutes': actualMinutes,
      'scheduled_start': scheduledStart?.toIso8601String(),
      'scheduled_calendar_uid': scheduledCalendarUid,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawTitle = json['title'];
    final rawDone = json['is_done'];
    final rawCreatedAt = json['created_at'];
    final rawEnergyRequirement = json['energy_requirement'];
    final rawEstimateMinutes = json['estimate_minutes'];

    if (rawId is! String ||
        rawTitle is! String ||
        rawDone is! bool ||
        rawCreatedAt is! String) {
      throw const FormatException('Invalid todo payload');
    }

    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    if (parsedCreatedAt == null) {
      throw const FormatException('Invalid todo timestamp');
    }

    return TodoItem(
      id: rawId,
      title: rawTitle,
      isDone: rawDone,
      createdAt: parsedCreatedAt,
      energyRequirement: TaskEnergyRequirementX.fromStorageValue(
        rawEnergyRequirement is String ? rawEnergyRequirement : null,
      ),
      estimateMinutes: rawEstimateMinutes is int
          ? rawEstimateMinutes.clamp(10, 240)
          : 25,
      status: TaskStatusX.fromStorageValue(json['status'] as String?),
      projectId: json['project_id'] as String?,
      blockedBy: (json['blocked_by'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      priority: json['priority'] as int?,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      actualMinutes: json['actual_minutes'] as int?,
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'] as String)
          : null,
      scheduledCalendarUid: json['scheduled_calendar_uid'] as String?,
    );
  }
}
