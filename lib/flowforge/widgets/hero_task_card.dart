import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';

class HeroTaskCard extends StatelessWidget {
  const HeroTaskCard({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final todo = state.focusedTodo;

    if (todo == null) {
      return _emptyState(context);
    }

    return _buildDismissible(
      context: context,
      todo: todo,
      child: _cardContent(context, todo),
    );
  }

  Widget _buildDismissible({
    required BuildContext context,
    required TodoItem todo,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey<String>('hero-${todo.id}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => state.toggleTodo(todo.id, true),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  Widget _cardContent(BuildContext context, TodoItem todo) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hint = state.todoConstraintHint(todo);
    final energyFit = state.isEnergyFit(todo);
    final timeFit = state.isTimeFit(todo);
    final dueDateText = formatDueDate(todo.deadline);
    final isOverdue = todo.isOverdue;
    final fitColor = energyFit && timeFit ? scheme.primary : scheme.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.82 : 0.92,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdue
              ? scheme.error.withValues(alpha: 0.45)
              : scheme.primary.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (isOverdue ? scheme.error : scheme.shadow).withValues(
              alpha: isDark ? 0.2 : 0.12,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Best Fit Right Now',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (dueDateText.isNotEmpty)
                _tag(
                  context,
                  icon: isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.schedule,
                  text: dueDateText,
                  color: isOverdue ? scheme.error : scheme.secondary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            todo.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the cleanest next move for your current energy and focus window.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _tag(
                context,
                icon: todo.energyRequirement.icon,
                text: '${todo.energyRequirement.label} energy',
                color: todo.energyRequirement.accent,
              ),
              _tag(
                context,
                icon: Icons.timer_outlined,
                text: '${todo.estimateMinutes} min',
                color: scheme.secondary,
              ),
              _tag(
                context,
                icon: todo.status == TaskStatus.today
                    ? Icons.today_rounded
                    : Icons.inventory_2_rounded,
                text: todo.status.label,
                color: todo.status == TaskStatus.today
                    ? scheme.primary
                    : scheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fitColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  energyFit && timeFit
                      ? Icons.check_circle
                      : Icons.insights_rounded,
                  size: 18,
                  color: fitColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: textTheme.bodySmall?.copyWith(
                      color: fitColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: state.toggleTimer,
                icon: Icon(
                  state.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(state.isRunning ? 'Pause Focus' : 'Start Focus'),
              ),
              OutlinedButton.icon(
                onPressed: () => state.toggleTodo(todo.id, true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark Done'),
              ),
              TextButton.icon(
                onPressed: () => state.moveTaskToStatus(
                  todo.id,
                  todo.status == TaskStatus.today
                      ? TaskStatus.backlog
                      : TaskStatus.today,
                ),
                icon: Icon(
                  todo.status == TaskStatus.today
                      ? Icons.inventory_2_rounded
                      : Icons.today_rounded,
                ),
                label: Text(
                  todo.status == TaskStatus.today
                      ? 'Back to Backlog'
                      : 'Move to Today',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.76 : 0.9,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.bolt_rounded, size: 32, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            'Nothing is queued for focus yet',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture a task above or move one into Today so FlowForge can recommend the next best move.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
