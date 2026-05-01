import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'task_editor_sheet.dart';
import 'task_ui_helpers.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: todo.isDone
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : isOverdue
            ? scheme.errorContainer.withValues(alpha: isDark ? 0.15 : 0.1)
            : isFocused
            ? scheme.primaryContainer.withValues(alpha: isDark ? 0.22 : 0.42)
            : scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.6 : 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isOverdue ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: InkWell(
                  key: ValueKey<String>('task-pill-focus-${todo.id}'),
                  onTap: todo.isDone
                      ? null
                      : () => state.setFocusedTodo(todo.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: <Widget>[
                                TaskMetaChip(
                                  icon: todo.energyRequirement.icon,
                                  text: todo.energyRequirement.label,
                                  color: todo.isDone
                                      ? scheme.onSurfaceVariant
                                      : todo.energyRequirement.accent,
                                  compact: true,
                                ),
                                TaskProjectBadge(todo: todo, compact: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              todo.title,
                              style: textTheme.bodyMedium?.copyWith(
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: todo.isDone
                                    ? scheme.onSurfaceVariant
                                    : null,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: <Widget>[
                            TaskMetaChip(
                              icon: Icons.timer_outlined,
                              text: '${todo.estimateMinutes}m',
                              color: scheme.secondary,
                              compact: true,
                            ),
                            if (dueDateText.isNotEmpty)
                              TaskMetaChip(
                                icon: isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule,
                                text: dueDateText,
                                color: isOverdue
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                                compact: true,
                              ),
                            if (isFocused)
                              TaskMetaChip(
                                icon: Icons.center_focus_strong_rounded,
                                text: 'Focused',
                                color: scheme.primary,
                                compact: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  IconButton.filledTonal(
                    key: ValueKey<String>('task-pill-toggle-${todo.id}'),
                    tooltip: todo.isDone ? 'Restore to backlog' : 'Mark done',
                    onPressed: () => state.moveTaskToStatus(
                      todo.id,
                      todo.isDone ? TaskStatus.backlog : TaskStatus.done,
                    ),
                    icon: Icon(
                      todo.isDone
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PopupMenuButton<_TaskPillAction>(
                    tooltip: 'More actions',
                    onSelected: (action) => _handleAction(context, action),
                    itemBuilder: (context) => <PopupMenuEntry<_TaskPillAction>>[
                      const PopupMenuItem<_TaskPillAction>(
                        value: _TaskPillAction.edit,
                        child: Text('Edit task'),
                      ),
                      if (!todo.isDone && todo.status != TaskStatus.today)
                        const PopupMenuItem<_TaskPillAction>(
                          value: _TaskPillAction.moveToToday,
                          child: Text('Move to Today'),
                        ),
                      if (!todo.isDone && todo.status != TaskStatus.backlog)
                        const PopupMenuItem<_TaskPillAction>(
                          value: _TaskPillAction.moveToBacklog,
                          child: Text('Move to Backlog'),
                        ),
                      if (todo.isDone)
                        const PopupMenuItem<_TaskPillAction>(
                          value: _TaskPillAction.restore,
                          child: Text('Restore to Backlog'),
                        ),
                      const PopupMenuItem<_TaskPillAction>(
                        value: _TaskPillAction.delete,
                        child: Text('Delete task'),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.more_horiz_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, _TaskPillAction action) {
    switch (action) {
      case _TaskPillAction.edit:
        openTaskEditorSheet(context, todo: todo, state: state);
        return;
      case _TaskPillAction.moveToToday:
        return state.moveTaskToStatus(todo.id, TaskStatus.today);
      case _TaskPillAction.moveToBacklog:
        return state.moveTaskToStatus(todo.id, TaskStatus.backlog);
      case _TaskPillAction.restore:
        return state.moveTaskToStatus(todo.id, TaskStatus.backlog);
      case _TaskPillAction.delete:
        _confirmDelete(context);
        return;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${todo.title}" will be removed permanently.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      state.deleteTodo(todo.id);
    }
  }
}

enum _TaskPillAction { edit, moveToToday, moveToBacklog, restore, delete }
