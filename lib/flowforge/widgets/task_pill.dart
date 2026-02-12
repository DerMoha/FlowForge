import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';

class TaskPill extends StatelessWidget {
  const TaskPill({
    super.key,
    required this.todo,
    required this.state,
    this.isFocused = false,
  });

  final TodoItem todo;
  final FlowForgeState state;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = todo.isOverdue;
    final dueDateText = formatDueDate(todo.deadline);

    final borderColor = isOverdue
        ? scheme.error.withValues(alpha: 0.5)
        : scheme.outlineVariant.withValues(alpha: 0.5);

    final content = GestureDetector(
      onTap: todo.isDone ? null : () => state.setFocusedTodo(todo.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: todo.isDone
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : isOverdue
              ? scheme.errorContainer.withValues(alpha: isDark ? 0.15 : 0.1)
              : scheme.surfaceContainerLow.withValues(
                  alpha: isDark ? 0.6 : 0.8,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isOverdue ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  todo.energyRequirement.icon,
                  size: 16,
                  color: todo.isDone
                      ? scheme.onSurfaceVariant
                      : todo.energyRequirement.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todo.title,
                    style: textTheme.bodyMedium?.copyWith(
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isDone ? scheme.onSurfaceVariant : null,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${todo.estimateMinutes}m',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: 'Delete',
                    onPressed: () => state.deleteTodo(todo.id),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (dueDateText.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const SizedBox(width: 24),
                  Icon(
                    isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                    size: 12,
                    color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDateText,
                    style: textTheme.labelSmall?.copyWith(
                      color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                      fontWeight: isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (todo.isDone) {
      return content;
    }

    return Dismissible(
      key: ValueKey<String>('pill-${todo.id}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => state.toggleTodo(todo.id, true),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.check_rounded, color: scheme.primary),
      ),
      child: content,
    );
  }
}
