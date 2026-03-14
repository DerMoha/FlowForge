import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';
import 'task_editor_sheet.dart';

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
          isDark,
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
    bool isDark,
    bool isOverdue,
    String dueDateText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Consumer<ProjectState>(
              builder: (context, projectState, _) {
                final project = todo.projectId != null
                    ? projectState.getProject(todo.projectId!)
                    : null;
                if (project == null) return const SizedBox.shrink();
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: project.color,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            Icon(
              todo.energyRequirement.icon,
              size: 18,
              color: todo.energyRequirement.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                todo.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                  color: todo.isDone ? scheme.onSurfaceVariant : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            _buildTag(
              context,
              icon: Icons.timer_outlined,
              text: '${todo.estimateMinutes}m',
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
            if (dueDateText.isNotEmpty)
              _buildTag(
                context,
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
            ActionChip(
              avatar: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              onPressed: () => _showEditSheet(context),
            ),
            if (todo.status == TaskStatus.backlog)
              ActionChip(
                avatar: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Move to Today'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.today),
              ),
            if (todo.status == TaskStatus.today)
              ActionChip(
                avatar: const Icon(Icons.inventory_2_rounded, size: 16),
                label: const Text('Backlog'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.backlog),
              ),
            if (!todo.isDone)
              ActionChip(
                avatar: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                label: const Text('Done'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.done),
              ),
            ActionChip(
              avatar: const Icon(Icons.more_horiz_rounded, size: 16),
              label: const Text('Delete'),
              onPressed: () => state.deleteTodo(todo.id),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
