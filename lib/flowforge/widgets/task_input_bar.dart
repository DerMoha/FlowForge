import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../state/app_state.dart';

class TaskInputBar extends StatelessWidget {
  const TaskInputBar({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestedMinutes =
        state.estimatedTodoMinutesFor(state.newTodoEnergyRequirement);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.7 : 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.7),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('todo-input'),
                  controller: state.todoInputController,
                  focusNode: state.todoInputFocusNode,
                  textInputAction: TextInputAction.done,
                  onTap: state.expandTodoComposer,
                  onChanged: (_) => state.expandTodoComposer(),
                  onSubmitted: (_) => state.addTodo(),
                  decoration:
                      const InputDecoration(hintText: 'Add a task...'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey<String>('todo-add-button'),
                onPressed: state.addTodo,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: state.showTodoComposerDetails
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: TaskEnergyRequirement.values
                            .map(
                              (requirement) => ChoiceChip(
                                key: ValueKey<String>(
                                  'todo-energy-${requirement.name}',
                                ),
                                selected: state.newTodoEnergyRequirement ==
                                    requirement,
                                onSelected: (_) => state
                                    .setNewTodoEnergyRequirement(requirement),
                                selectedColor:
                                    requirement.accent.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: requirement.accent
                                      .withValues(alpha: 0.35),
                                ),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      requirement.icon,
                                      size: 15,
                                      color: requirement.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(requirement.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Suggested: $suggestedMinutes min for ${state.newTodoEnergyRequirement.label.toLowerCase()} energy.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey<String>('todo-use-estimate'),
                            onPressed: state.useSuggestedTodoEstimate,
                            child: Text('Use $suggestedMinutes min'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: FlowForgeState.todoEstimatePresets
                            .map(
                              (minutes) => ChoiceChip(
                                key: ValueKey<String>('todo-effort-$minutes'),
                                selected:
                                    state.newTodoEstimateMinutes == minutes,
                                onSelected: (_) =>
                                    state.setNewTodoEstimateMinutes(minutes),
                                selectedColor: scheme.secondaryContainer,
                                label: Text('$minutes min'),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
