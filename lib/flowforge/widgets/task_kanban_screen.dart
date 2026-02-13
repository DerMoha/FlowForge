import 'package:flutter/material.dart';

import '../models/task_status.dart';
import '../state/app_state.dart';
import 'kanban_column.dart';

class TaskKanbanScreen extends StatefulWidget {
  const TaskKanbanScreen({super.key, required this.state});

  final FlowForgeState state;

  @override
  State<TaskKanbanScreen> createState() => _TaskKanbanScreenState();
}

class _TaskKanbanScreenState extends State<TaskKanbanScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context, scheme, textTheme),
            const SizedBox(height: 16),
            KanbanColumn(
              status: TaskStatus.today,
              todos: widget.state.todayTodos,
              state: widget.state,
              showWarning: true,
            ),
            const SizedBox(height: 12),
            KanbanColumn(
              status: TaskStatus.backlog,
              todos: widget.state.backlogTodos,
              state: widget.state,
            ),
            const SizedBox(height: 12),
            KanbanColumn(
              status: TaskStatus.done,
              todos: widget.state.doneTodos,
              state: widget.state,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: <Widget>[
        Icon(Icons.view_kanban_rounded, size: 24, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          'Task Board',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const Spacer(),
        _buildStats(context, scheme, textTheme),
      ],
    );
  }

  Widget _buildStats(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final todayCount = widget.state.todayTodoCount;
    final doneCount = widget.state.doneTodos.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildStatItem(
            context,
            icon: Icons.today_rounded,
            count: todayCount,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            context,
            icon: Icons.check_circle_rounded,
            count: doneCount,
            color: scheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
