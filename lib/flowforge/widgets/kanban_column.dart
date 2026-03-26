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
    this.boardMode = false,
  });

  final TaskStatus status;
  final List<TodoItem> todos;
  final FlowForgeState state;
  final bool showWarning;
  final bool boardMode;

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
      padding: EdgeInsets.all(widget.boardMode ? 14 : 0),
      decoration: BoxDecoration(
        color: widget.boardMode
            ? scheme.surfaceContainerLow.withValues(alpha: 0.72)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: widget.boardMode
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(context, scheme, textTheme, columnColor),
          if (_isExpanded) ...<Widget>[
            if (widget.showWarning && widget.todos.length > 5)
              _buildWarning(context, scheme),
            if (widget.boardMode)
              Expanded(child: _buildTaskRegion(context, scheme))
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _buildTaskRegion(context, scheme),
              ),
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
    final helperText = widget.status == TaskStatus.today
        ? 'Keep this list intentionally small.'
        : widget.status == TaskStatus.backlog
        ? 'Park worthwhile tasks here until they earn today.'
        : 'Finished work stays visible without stealing attention.';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 14, 14, widget.boardMode ? 14 : 12),
        decoration: BoxDecoration(
          color: columnColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_getColumnIcon(), size: 20, color: columnColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.status.label} (${widget.todos.length})',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: columnColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: columnColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              helperText,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRegion(BuildContext context, ColorScheme scheme) {
    if (widget.todos.isEmpty) {
      return _buildEmptyState(context, scheme);
    }

    return _buildTaskList(context);
  }

  Widget _buildTaskList(BuildContext context) {
    final children = widget.todos
        .map(
          (todo) => _AnimatedTaskCard(
            key: ValueKey(todo.id),
            todo: todo,
            state: widget.state,
          ),
        )
        .toList();

    if (widget.boardMode) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          children: children,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.3 : 0.5,
        ),
        borderRadius: BorderRadius.circular(18),
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
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
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
        return 'Nothing is committed for today yet.';
      case TaskStatus.backlog:
        return 'Your backlog is empty.';
      case TaskStatus.done:
        return 'No completed tasks yet.';
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
