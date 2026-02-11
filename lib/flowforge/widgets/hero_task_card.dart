import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';

class HeroTaskCard extends StatefulWidget {
  const HeroTaskCard({super.key, required this.state});

  final FlowForgeState state;

  @override
  State<HeroTaskCard> createState() => _HeroTaskCardState();
}

class _HeroTaskCardState extends State<HeroTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.state.focusedTodo;

    if (todo == null) {
      return _emptyState(context);
    }

    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final t = _breathController.value;
        final scale = 1.0 + (t * 0.008);
        final shadowOpacity = 0.08 + (t * 0.06);

        return _buildDismissible(
          todo: todo,
          child: Transform.scale(
            scale: scale,
            child: _cardContent(context, todo, shadowOpacity),
          ),
        );
      },
    );
  }

  Widget _buildDismissible({required TodoItem todo, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey<String>('hero-${todo.id}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => widget.state.toggleTodo(todo.id, true),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
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

  Widget _cardContent(
    BuildContext context,
    TodoItem todo,
    double shadowOpacity,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hint = widget.state.todoConstraintHint(todo);
    final energyFit = widget.state.isEnergyFit(todo);
    final timeFit = widget.state.isTimeFit(todo);
    final fitColor =
        energyFit && timeFit ? scheme.primary : scheme.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.75 : 0.9,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: shadowOpacity),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Next Action',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            todo.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _tag(
                icon: todo.energyRequirement.icon,
                text: '${todo.energyRequirement.label} energy',
                color: todo.energyRequirement.accent,
              ),
              _tag(
                icon: Icons.timer_outlined,
                text: '${todo.estimateMinutes} min',
                color: scheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: textTheme.labelSmall?.copyWith(color: fitColor),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.7 : 0.85,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.add_task_rounded,
            size: 36,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks yet',
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one above to get your hero card.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.2), color)
        : color;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.26 : 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
