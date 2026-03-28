import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';

class TaskDetailSections extends StatelessWidget {
  const TaskDetailSections({
    super.key,
    required this.energyRequirement,
    required this.onEnergyChanged,
    required this.estimateMinutes,
    required this.onEstimateChanged,
    required this.deadline,
    required this.onDeadlineChanged,
    this.status,
    this.onStatusChanged,
    this.projectId,
    this.onProjectChanged,
    this.suggestedMinutes,
    this.onUseSuggestedEstimate,
    this.estimateHelperText,
    this.keyPrefix = 'task',
  });

  final TaskEnergyRequirement energyRequirement;
  final ValueChanged<TaskEnergyRequirement> onEnergyChanged;
  final int estimateMinutes;
  final ValueChanged<int> onEstimateChanged;
  final DateTime? deadline;
  final ValueChanged<DateTime?> onDeadlineChanged;
  final TaskStatus? status;
  final ValueChanged<TaskStatus>? onStatusChanged;
  final String? projectId;
  final ValueChanged<String?>? onProjectChanged;
  final int? suggestedMinutes;
  final VoidCallback? onUseSuggestedEstimate;
  final String? estimateHelperText;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (status != null && onStatusChanged != null) ...<Widget>[
          _SectionCard(
            label: 'Where should this live?',
            scheme: scheme,
            textTheme: textTheme,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskStatus.values.map((value) {
                final color = _statusColor(value, scheme);
                return ChoiceChip(
                  key: ValueKey<String>('$keyPrefix-status-${value.name}'),
                  selected: status == value,
                  onSelected: (_) => onStatusChanged!(value),
                  selectedColor: color.withValues(alpha: 0.18),
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(_statusIcon(value), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(value.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          label: 'Energy and time',
          scheme: scheme,
          textTheme: textTheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SectionLabel(
                label: 'Energy',
                scheme: scheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskEnergyRequirement.values.map((requirement) {
                  return ChoiceChip(
                    key: ValueKey<String>(
                      '$keyPrefix-energy-${requirement.name}',
                    ),
                    selected: energyRequirement == requirement,
                    onSelected: (_) => onEnergyChanged(requirement),
                    selectedColor: requirement.accent.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: requirement.accent.withValues(alpha: 0.35),
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          requirement.icon,
                          size: 14,
                          color: requirement.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(requirement.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _SectionLabel(
                label: 'Time estimate',
                scheme: scheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FlowForgeState.todoEstimatePresets.map((minutes) {
                  return ChoiceChip(
                    key: ValueKey<String>('$keyPrefix-effort-$minutes'),
                    selected: estimateMinutes == minutes,
                    onSelected: (_) => onEstimateChanged(minutes),
                    label: Text('$minutes min'),
                  );
                }).toList(),
              ),
              if (suggestedMinutes != null &&
                  onUseSuggestedEstimate != null &&
                  estimateHelperText != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          estimateHelperText!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton(
                        key: ValueKey<String>('$keyPrefix-use-estimate'),
                        onPressed: onUseSuggestedEstimate,
                        child: Text('Use $suggestedMinutes min'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          label: 'Timing',
          scheme: scheme,
          textTheme: textTheme,
          child: _DueDateChips(
            keyPrefix: keyPrefix,
            deadline: deadline,
            onChanged: onDeadlineChanged,
          ),
        ),
        if (onProjectChanged != null) ...<Widget>[
          const SizedBox(height: 12),
          Consumer<ProjectState>(
            builder: (context, projectState, child) {
              final projects = projectState.projects;
              if (projects.isEmpty) {
                return const SizedBox.shrink();
              }

              return _SectionCard(
                label: 'Project',
                scheme: scheme,
                textTheme: textTheme,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey<String>('$keyPrefix-project-picker'),
                  initialValue: projectId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_open_rounded),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No project'),
                    ),
                    ...projects.map((project) {
                      return DropdownMenuItem<String?>(
                        key: ValueKey<String>(
                          '$keyPrefix-project-${project.id}',
                        ),
                        value: project.id,
                        child: Row(
                          children: <Widget>[
                            Icon(project.icon, size: 18, color: project.color),
                            const SizedBox(width: 8),
                            Text(project.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: onProjectChanged,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Color _statusColor(TaskStatus value, ColorScheme scheme) {
    switch (value) {
      case TaskStatus.today:
        return scheme.primary;
      case TaskStatus.backlog:
        return scheme.tertiary;
      case TaskStatus.done:
        return scheme.secondary;
    }
  }

  IconData _statusIcon(TaskStatus value) {
    switch (value) {
      case TaskStatus.today:
        return Icons.today_rounded;
      case TaskStatus.backlog:
        return Icons.inventory_2_rounded;
      case TaskStatus.done:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.scheme,
    required this.textTheme,
    required this.child,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionLabel(label: label, scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _DueDateChips extends StatelessWidget {
  const _DueDateChips({
    required this.keyPrefix,
    required this.deadline,
    required this.onChanged,
  });

  final String keyPrefix;
  final DateTime? deadline;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeek = today.add(const Duration(days: 7));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _DueDateChip(
          keyPrefix: keyPrefix,
          label: 'Today',
          date: today,
          deadline: deadline,
          onChanged: onChanged,
        ),
        _DueDateChip(
          keyPrefix: keyPrefix,
          label: 'Tomorrow',
          date: tomorrow,
          deadline: deadline,
          onChanged: onChanged,
        ),
        _DueDateChip(
          keyPrefix: keyPrefix,
          label: 'This Week',
          date: thisWeek,
          deadline: deadline,
          onChanged: onChanged,
        ),
        ActionChip(
          key: ValueKey<String>('$keyPrefix-due-custom'),
          avatar: Icon(
            Icons.calendar_today,
            size: 16,
            color:
                deadline != null &&
                    !_isQuickChip(deadline, today, tomorrow, thisWeek)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          label: Text(
            deadline != null &&
                    !_isQuickChip(deadline, today, tomorrow, thisWeek)
                ? formatDueDate(deadline)
                : 'Custom',
          ),
          side: BorderSide(
            color:
                deadline != null &&
                    !_isQuickChip(deadline, today, tomorrow, thisWeek)
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.5),
          ),
          onPressed: () => _showDatePicker(context, today),
        ),
        if (deadline != null)
          ActionChip(
            key: ValueKey<String>('$keyPrefix-due-clear'),
            avatar: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
            label: const Text('Clear'),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  bool _isQuickChip(
    DateTime? current,
    DateTime today,
    DateTime tomorrow,
    DateTime thisWeek,
  ) {
    if (current == null) return false;
    return isSameDay(current, today) ||
        isSameDay(current, tomorrow) ||
        isSameDay(current, thisWeek);
  }

  Future<void> _showDatePicker(BuildContext context, DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: deadline != null ? startOfDay(deadline!) : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.keyPrefix,
    required this.label,
    required this.date,
    required this.deadline,
    required this.onChanged,
  });

  final String keyPrefix;
  final String label;
  final DateTime date;
  final DateTime? deadline;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = deadline != null && isSameDay(deadline!, date);

    return ChoiceChip(
      key: ValueKey<String>(
        '$keyPrefix-due-${label.toLowerCase().replaceAll(' ', '-')}',
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(date),
      selectedColor: scheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.outline.withValues(alpha: 0.5),
      ),
    );
  }
}
