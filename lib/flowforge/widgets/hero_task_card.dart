import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';
import 'task_editor_sheet.dart';

class HeroTaskCard extends StatelessWidget {
  const HeroTaskCard({super.key, required this.state, this.todo});

  final FlowForgeState state;
  final TodoItem? todo;

  @override
  Widget build(BuildContext context) {
    final heroTodo = todo ?? state.focusedTodo;

    if (heroTodo == null) {
      return _emptyState(context);
    }

    return _cardContent(context, heroTodo);
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
              Consumer<ProjectState>(
                builder: (context, projectState, _) {
                  final project = todo.projectId != null
                      ? projectState.getProject(todo.projectId!)
                      : null;
                  if (project == null) return const SizedBox.shrink();
                  return _tag(
                    context,
                    icon: project.icon,
                    text: project.name,
                    color: project.color,
                  );
                },
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
              OutlinedButton.icon(
                onPressed: () =>
                    openTaskEditorSheet(context, todo: todo, state: state),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
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
