import 'package:flutter/material.dart';

import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import 'kanban_task_card.dart';

class KanbanColumn extends StatefulWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.todos,
    required this.state,
    this.showWarning = false,
  });

  final TaskStatus status;
  final List<TodoItem> todos;
  final FlowForgeState state;
  final bool showWarning;

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final columnColor = _getColumnColor(scheme);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(context, scheme, textTheme, columnColor),
          if (_isExpanded) ...<Widget>[
            if (widget.showWarning && widget.todos.length > 5)
              _buildWarning(context, scheme),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.todos
                    .map(
                      (todo) => _AnimatedTaskCard(
                        key: ValueKey(todo.id),
                        todo: todo,
                        state: widget.state,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (widget.todos.isEmpty) _buildEmptyState(context, scheme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    Color columnColor,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 24,
              color: columnColor,
            ),
            const SizedBox(width: 8),
            Icon(_getColumnIcon(), size: 20, color: columnColor),
            const SizedBox(width: 8),
            Text(
              '${widget.status.label} (${widget.todos.length})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: columnColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Use the visible task actions to move work between columns.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lightbulb_outline, size: 16, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Consider focusing on fewer tasks today and moving the rest back to backlog.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.3 : 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          _getEmptyMessage(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Color _getColumnColor(ColorScheme scheme) {
    switch (widget.status) {
      case TaskStatus.today:
        return scheme.primary;
      case TaskStatus.backlog:
        return scheme.tertiary;
      case TaskStatus.done:
        return scheme.secondary;
    }
  }

  IconData _getColumnIcon() {
    switch (widget.status) {
      case TaskStatus.today:
        return Icons.today_rounded;
      case TaskStatus.backlog:
        return Icons.inventory_2_rounded;
      case TaskStatus.done:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _getEmptyMessage() {
    switch (widget.status) {
      case TaskStatus.today:
        return 'Use card actions to plan today intentionally';
      case TaskStatus.backlog:
        return 'Your backlog is empty';
      case TaskStatus.done:
        return 'No completed tasks yet';
    }
  }
}

class _AnimatedTaskCard extends StatefulWidget {
  const _AnimatedTaskCard({super.key, required this.todo, required this.state});

  final TodoItem todo;
  final FlowForgeState state;

  @override
  State<_AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<_AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAnimatedChild(
      KanbanTaskCard(todo: widget.todo, state: widget.state),
    );
  }

  Widget _buildAnimatedChild(Widget child) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: child),
    );
  }
}
