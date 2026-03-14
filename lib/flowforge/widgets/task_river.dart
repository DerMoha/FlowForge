import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'task_pill.dart';

class TaskRiver extends StatefulWidget {
  const TaskRiver({
    super.key,
    required this.state,
    this.openTodos,
    this.completedTodos,
    this.heroTodoId,
  });

  final FlowForgeState state;
  final List<TodoItem>? openTodos;
  final List<TodoItem>? completedTodos;
  final String? heroTodoId;

  @override
  State<TaskRiver> createState() => _TaskRiverState();
}

class _TaskRiverState extends State<TaskRiver> {
  bool _overdueExpanded = true;
  bool _todayExpanded = true;
  bool _thisWeekExpanded = true;
  bool _laterExpanded = true;

  @override
  Widget build(BuildContext context) {
    final openTodos = widget.openTodos ?? widget.state.sortedOpenTodos;
    final heroTodoId =
        widget.heroTodoId ??
        (widget.openTodos == null && openTodos.isNotEmpty
            ? openTodos.first.id
            : null);
    final riverTodos = heroTodoId == null
        ? openTodos
        : openTodos.where((todo) => todo.id != heroTodoId).toList();
    final completedTodos = widget.completedTodos ?? widget.state.completedTodos;

    if (riverTodos.isEmpty && completedTodos.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = _groupByDeadline(riverTodos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ..._buildGroupedSections(context, grouped),
        if (completedTodos.isNotEmpty)
          _buildCompletedSection(context, completedTodos),
      ],
    );
  }

  Map<DueGroup, List<TodoItem>> _groupByDeadline(List<TodoItem> todos) {
    final result = <DueGroup, List<TodoItem>>{
      DueGroup.overdue: [],
      DueGroup.today: [],
      DueGroup.thisWeek: [],
      DueGroup.later: [],
    };

    for (final todo in todos) {
      final group = groupByDueDate(todo.deadline);
      result[group]!.add(todo);
    }

    return result;
  }

  List<Widget> _buildGroupedSections(
    BuildContext context,
    Map<DueGroup, List<TodoItem>> grouped,
  ) {
    return <Widget>[
      if (grouped[DueGroup.overdue]!.isNotEmpty)
        _buildSection(
          context: context,
          title: 'Overdue',
          count: grouped[DueGroup.overdue]!.length,
          todos: grouped[DueGroup.overdue]!,
          isExpanded: _overdueExpanded,
          onToggle: () => setState(() => _overdueExpanded = !_overdueExpanded),
          isOverdue: true,
        ),
      if (grouped[DueGroup.today]!.isNotEmpty)
        _buildSection(
          context: context,
          title: 'Today',
          count: grouped[DueGroup.today]!.length,
          todos: grouped[DueGroup.today]!,
          isExpanded: _todayExpanded,
          onToggle: () => setState(() => _todayExpanded = !_todayExpanded),
        ),
      if (grouped[DueGroup.thisWeek]!.isNotEmpty)
        _buildSection(
          context: context,
          title: 'This Week',
          count: grouped[DueGroup.thisWeek]!.length,
          todos: grouped[DueGroup.thisWeek]!,
          isExpanded: _thisWeekExpanded,
          onToggle: () =>
              setState(() => _thisWeekExpanded = !_thisWeekExpanded),
        ),
      if (grouped[DueGroup.later]!.isNotEmpty)
        _buildSection(
          context: context,
          title: 'Later',
          count: grouped[DueGroup.later]!.length,
          todos: grouped[DueGroup.later]!,
          isExpanded: _laterExpanded,
          onToggle: () => setState(() => _laterExpanded = !_laterExpanded),
        ),
    ];
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required int count,
    required List<TodoItem> todos,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isOverdue = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$title ($count)',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: isExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: todos
                      .map(
                        (todo) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: TaskPill(
                            todo: todo,
                            state: widget.state,
                            isFocused: todo.id == widget.state.focusedTodoId,
                          ),
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCompletedSection(
    BuildContext context,
    List<TodoItem> completedTodos,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Finished (${completedTodos.length})',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              key: const ValueKey<String>('toggle-finished-todos'),
              onPressed: widget.state.toggleShowFinishedTodos,
              child: Text(widget.state.showFinishedTodos ? 'Hide' : 'Show'),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: widget.state.showFinishedTodos
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...completedTodos.map(
                      (todo) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TaskPill(todo: todo, state: widget.state),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.state.clearCompletedTodos,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text('Clear finished (${completedTodos.length})'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
