import '../models/todo_item.dart';
import '../models/recurrence_rule.dart';
import '../models/task_energy_requirement.dart';

/// Manages recurring task generation and tracking
class RecurrenceManager {
  RecurrenceManager._();

  static final instance = RecurrenceManager._();

  /// Generate due tasks based on recurrence rules
  List<TodoItem> generateDueTasks(
    List<TodoItem> existingTasks,
    DateTime currentDate,
  ) {
    final newTasks = <TodoItem>[];

    // Find recurring task templates
    final recurringTemplates = existingTasks
        .where((task) => task.recurrence != null && !task.isDone)
        .toList();

    for (final template in recurringTemplates) {
      final rule = template.recurrence!;

      // Check if this recurrence is due
      if (rule.matches(currentDate)) {
        // Check if task already exists for this date
        final alreadyExists = existingTasks.any(
          (task) =>
              task.title == template.title &&
              task.createdAt.year == currentDate.year &&
              task.createdAt.month == currentDate.month &&
              task.createdAt.day == currentDate.day,
        );

        if (!alreadyExists) {
          // Generate new instance
          newTasks.add(_createInstance(template, currentDate));
        }
      }
    }

    return newTasks;
  }

  /// Create a new instance from a recurring template
  TodoItem _createInstance(TodoItem template, DateTime date) {
    return TodoItem(
      id: '${date.millisecondsSinceEpoch}-recurring',
      title: template.title,
      isDone: false,
      createdAt: date,
      energyRequirement: template.energyRequirement,
      estimateMinutes: template.estimateMinutes,
      status: template.status,
      projectId: template.projectId,
      tags: template.tags,
      priority: template.priority,
    );
  }

  /// Get next occurrence for a recurring task
  DateTime? getNextOccurrence(RecurrenceRule rule, DateTime after) {
    return rule.nextOccurrence(after);
  }

  /// Skip a recurring task instance
  void skipInstance(TodoItem task) {
    // Mark as completed without affecting streak/stats
    // Implementation would update the task state
  }

  /// Postpone a recurring task instance
  DateTime? postponeInstance(TodoItem task, int days) {
    if (task.recurrence == null) return null;

    final nextDate = task.createdAt.add(Duration(days: days));
    return nextDate;
  }

  /// Create a recurring rule from a task
  RecurrenceRule createRule({
    required RecurrencePattern pattern,
    required DateTime startDate,
    DateTime? endDate,
    List<int>? specificDaysOfWeek,
    int? dayOfMonth,
  }) {
    return RecurrenceRule(
      pattern: pattern,
      startDate: startDate,
      endDate: endDate,
      specificDaysOfWeek: specificDaysOfWeek,
      dayOfMonth: dayOfMonth,
    );
  }
}
