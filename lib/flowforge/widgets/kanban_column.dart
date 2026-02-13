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
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final columnColor = _getColumnColor(scheme);
    final backgroundColor = _isDragOver
        ? columnColor.withValues(alpha: isDark ? 0.15 : 0.1)
        : Colors.transparent;

    return DragTarget<TodoItem>(
      onWillAcceptWithDetails: (details) {
        if (details.data.status == widget.status) return false;
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        widget.state.moveTaskToStatus(details.data.id, widget.status);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: _isDragOver
                ? Border.all(color: columnColor, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(context, scheme, textTheme, columnColor),
              if (_isExpanded) ...<Widget>[
                if (widget.showWarning && widget.todos.length > 5)
                  _buildWarning(context, scheme),
                ...widget.todos.map(
                  (todo) => _buildSwipeableCard(todo, context, scheme),
                ),
                if (widget.todos.isEmpty) _buildEmptyState(context, scheme),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwipeableCard(
    TodoItem todo,
    BuildContext context,
    ColorScheme scheme,
  ) {
    final swipeConfig = _getSwipeConfig();

    if (swipeConfig == null) {
      return KanbanTaskCard(
        todo: todo,
        state: widget.state,
        onDelete: () => widget.state.deleteTodo(todo.id),
      );
    }

    return Dismissible(
      key: Key(todo.id),
      direction: swipeConfig.direction,
      background: _buildSwipeBackground(
        context,
        scheme,
        swipeConfig.backgroundColor,
        swipeConfig.icon,
        swipeConfig.label,
        Alignment.centerLeft,
      ),
      secondaryBackground: swipeConfig.secondaryTarget != null
          ? _buildSwipeBackground(
              context,
              scheme,
              swipeConfig.secondaryBackgroundColor ??
                  swipeConfig.backgroundColor,
              swipeConfig.secondaryIcon ?? swipeConfig.icon,
              swipeConfig.secondaryLabel ?? swipeConfig.label,
              Alignment.centerRight,
            )
          : null,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.state.moveTaskToStatus(todo.id, swipeConfig.targetStatus);
        } else if (direction == DismissDirection.endToStart &&
            swipeConfig.secondaryTarget != null) {
          widget.state.moveTaskToStatus(todo.id, swipeConfig.secondaryTarget!);
        }
        return false;
      },
      child: KanbanTaskCard(
        todo: todo,
        state: widget.state,
        onDelete: () => widget.state.deleteTodo(todo.id),
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context,
    ColorScheme scheme,
    Color backgroundColor,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: isDark ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: backgroundColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: backgroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SwipeConfig? _getSwipeConfig() {
    switch (widget.status) {
      case TaskStatus.today:
        return _SwipeConfig(
          direction: DismissDirection.horizontal,
          targetStatus: TaskStatus.done,
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
          label: 'Done',
          secondaryTarget: TaskStatus.backlog,
          secondaryBackgroundColor: Colors.orange,
          secondaryIcon: Icons.inventory_2_outlined,
          secondaryLabel: 'Backlog',
        );
      case TaskStatus.backlog:
        return _SwipeConfig(
          direction: DismissDirection.startToEnd,
          targetStatus: TaskStatus.today,
          backgroundColor: Colors.blue,
          icon: Icons.today_outlined,
          label: 'Today',
        );
      case TaskStatus.done:
        return _SwipeConfig(
          direction: DismissDirection.endToStart,
          targetStatus: TaskStatus.backlog,
          backgroundColor: Colors.orange,
          icon: Icons.inventory_2_outlined,
          label: 'Backlog',
        );
    }
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
              'Consider focusing on fewer tasks today',
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
        return 'Drag tasks here to plan your day';
      case TaskStatus.backlog:
        return 'Your backlog is empty';
      case TaskStatus.done:
        return 'No completed tasks yet';
    }
  }
}

class _SwipeConfig {
  const _SwipeConfig({
    required this.direction,
    required this.targetStatus,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    this.secondaryTarget,
    this.secondaryBackgroundColor,
    this.secondaryIcon,
    this.secondaryLabel,
  });

  final DismissDirection direction;
  final TaskStatus targetStatus;
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final TaskStatus? secondaryTarget;
  final Color? secondaryBackgroundColor;
  final IconData? secondaryIcon;
  final String? secondaryLabel;
}
