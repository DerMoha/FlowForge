import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'task_pill.dart';

class TaskRiver extends StatelessWidget {
  const TaskRiver({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Skip the first open todo (shown in hero card).
    final openTodos = state.sortedOpenTodos;
    final riverTodos = openTodos.length > 1 ? openTodos.sublist(1) : <dynamic>[];
    final completedTodos = state.completedTodos;

    if (riverTodos.isEmpty && completedTodos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (riverTodos.isNotEmpty) ...[
          Text(
            'Up next',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...riverTodos.map(
            (todo) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TaskPill(
                todo: todo,
                state: state,
                isFocused: todo.id == state.focusedTodoId,
              ),
            ),
          ),
        ],
        if (completedTodos.isNotEmpty) ...[
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
                onPressed: state.toggleShowFinishedTodos,
                child: Text(state.showFinishedTodos ? 'Hide' : 'Show'),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: state.showFinishedTodos
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ...completedTodos.map(
                        (todo) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: TaskPill(todo: todo, state: state),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: state.clearCompletedTodos,
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: Text(
                          'Clear finished (${completedTodos.length})',
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
