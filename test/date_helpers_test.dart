import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/flowforge/models/task_energy_requirement.dart';
import 'package:flowforge/flowforge/models/task_status.dart';
import 'package:flowforge/flowforge/models/todo_item.dart';
import 'package:flowforge/flowforge/utils/date_helpers.dart';

void main() {
  test('normalizeDueDate moves deadlines to end of day', () {
    final normalized = normalizeDueDate(DateTime(2026, 3, 12, 9, 30));

    expect(normalized, isNotNull);
    expect(normalized!.hour, 23);
    expect(normalized.minute, 59);
    expect(normalized.second, 59);
  });

  test('isOverdueDate only turns true after the due day has passed', () {
    final todayDeadline = normalizeDueDate(DateTime(2026, 3, 12));
    final yesterdayDeadline = normalizeDueDate(DateTime(2026, 3, 11));
    final now = DateTime(2026, 3, 12, 18, 0);

    expect(isOverdueDate(todayDeadline, now: now), isFalse);
    expect(isOverdueDate(yesterdayDeadline, now: now), isTrue);
  });

  test('TodoItem overdue uses day semantics and ignores completed tasks', () {
    final base = TodoItem(
      id: 'todo-1',
      title: 'Ship the better due-date logic',
      isDone: false,
      createdAt: DateTime(2026, 3, 12, 8, 0),
      energyRequirement: TaskEnergyRequirement.medium,
      estimateMinutes: 25,
      status: TaskStatus.today,
      deadline: normalizeDueDate(DateTime(2026, 3, 11)),
    );

    expect(base.isOverdue, isTrue);
    expect(base.copyWith(isDone: true).isOverdue, isFalse);
  });
}
