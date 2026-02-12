import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/todo_item.dart';
import '../utils/date_helpers.dart';

class KanbanTaskCard extends StatelessWidget {
  const KanbanTaskCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onDelete,
  });

  final TodoItem todo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = todo.isOverdue;
    final dueDateText = formatDueDate(todo.deadline);

    return Draggable<TodoItem>(
      data: todo,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: todo.energyRequirement.accent.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: _buildContent(context, scheme, textTheme, isDark, isOverdue, dueDateText),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCard(context, scheme, textTheme, isDark, isOverdue, dueDateText),
      ),
      child: _buildCard(context, scheme, textTheme, isDark, isOverdue, dueDateText),
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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue
              ? scheme.errorContainer.withValues(alpha: isDark ? 0.2 : 0.15)
              : scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.8 : 0.95),
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
        child: _buildContent(context, scheme, textTheme, isDark, isOverdue, dueDateText),
      ),
    );
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
            if (onDelete != null)
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
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
