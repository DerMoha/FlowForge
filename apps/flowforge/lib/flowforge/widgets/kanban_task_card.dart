import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'task_editor_sheet.dart';
import 'task_ui_helpers.dart';

class KanbanTaskCard extends StatelessWidget {
  const KanbanTaskCard({super.key, required this.todo, required this.state});

  final TodoItem todo;
  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = todo.isOverdue;
    final dueDateText = formatDueDate(todo.deadline);

    return _buildCard(
      context,
      scheme,
      textTheme,
      isDark,
      isOverdue,
      dueDateText,
    );
  }

  Widget _buildCard(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool isDark,
    bool isOverdue,
    String dueDateText,
  ) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue
              ? scheme.errorContainer.withValues(alpha: isDark ? 0.2 : 0.15)
              : scheme.surfaceContainerLow.withValues(
                  alpha: isDark ? 0.8 : 0.95,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? scheme.error.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(
          context,
          scheme,
          textTheme,
          isOverdue,
          dueDateText,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    openTaskEditorSheet(context, todo: todo, state: state);
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool isOverdue,
    String dueDateText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      TaskMetaChip(
                        icon: todo.energyRequirement.icon,
                        text: todo.energyRequirement.label,
                        color: todo.energyRequirement.accent,
                        compact: true,
                      ),
                      TaskProjectBadge(todo: todo, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todo.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isDone ? scheme.onSurfaceVariant : null,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_KanbanTaskAction>(
              tooltip: 'Task actions',
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (context) => <PopupMenuEntry<_KanbanTaskAction>>[
                const PopupMenuItem<_KanbanTaskAction>(
                  value: _KanbanTaskAction.edit,
                  child: Text('Edit task'),
                ),
                if (todo.status != TaskStatus.today && !todo.isDone)
                  const PopupMenuItem<_KanbanTaskAction>(
                    value: _KanbanTaskAction.moveToToday,
                    child: Text('Move to Today'),
                  ),
                if (todo.status != TaskStatus.backlog && !todo.isDone)
                  const PopupMenuItem<_KanbanTaskAction>(
                    value: _KanbanTaskAction.moveToBacklog,
                    child: Text('Move to Backlog'),
                  ),
                if (!todo.isDone)
                  const PopupMenuItem<_KanbanTaskAction>(
                    value: _KanbanTaskAction.markDone,
                    child: Text('Mark done'),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<_KanbanTaskAction>(
                  value: _KanbanTaskAction.delete,
                  child: Text('Delete task'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            TaskMetaChip(
              icon: Icons.timer_outlined,
              text: '${todo.estimateMinutes}m',
              color: scheme.secondary,
            ),
            if (dueDateText.isNotEmpty)
              TaskMetaChip(
                icon: isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                text: dueDateText,
                color: isOverdue ? scheme.error : scheme.tertiary,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (todo.status == TaskStatus.backlog)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.today_rounded, size: 18),
                label: const Text('Move to Today'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.today),
              ),
            if (todo.status == TaskStatus.today)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('Backlog'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.backlog),
              ),
            if (!todo.isDone)
              OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Done'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.done),
              ),
          ],
        ),
      ],
    );
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

  void _handleAction(BuildContext context, _KanbanTaskAction action) {
    switch (action) {
      case _KanbanTaskAction.edit:
        _showEditSheet(context);
        return;
      case _KanbanTaskAction.moveToToday:
        state.moveTaskToStatus(todo.id, TaskStatus.today);
        return;
      case _KanbanTaskAction.moveToBacklog:
        state.moveTaskToStatus(todo.id, TaskStatus.backlog);
        return;
      case _KanbanTaskAction.markDone:
        state.moveTaskToStatus(todo.id, TaskStatus.done);
        return;
      case _KanbanTaskAction.delete:
        _confirmDelete(context);
        return;
    }
  }
}

enum _KanbanTaskAction { edit, moveToToday, moveToBacklog, markDone, delete }
