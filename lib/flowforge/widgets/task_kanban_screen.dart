import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'kanban_column.dart';

class TaskKanbanScreen extends StatefulWidget {
  const TaskKanbanScreen({super.key, required this.state});

  final FlowForgeState state;

  @override
  State<TaskKanbanScreen> createState() => _TaskKanbanScreenState();
}

class _TaskKanbanScreenState extends State<TaskKanbanScreen> {
  final TextEditingController _taskController = TextEditingController();
  TaskEnergyRequirement _energyRequirement = TaskEnergyRequirement.medium;
  int _estimateMinutes = 25;
  DateTime? _deadline;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _taskController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    widget.state.addTodoFromKanban(
      title: text,
      energyRequirement: _energyRequirement,
      estimateMinutes: _estimateMinutes,
      deadline: _deadline,
    );

    _taskController.clear();
    _deadline = null;
    setState(() => _showDetails = false);
    Navigator.pop(context);
  }

  void _showAddTaskSheet() {
    _taskController.clear();
    _energyRequirement = TaskEnergyRequirement.medium;
    _estimateMinutes = 25;
    _deadline = null;
    _showDetails = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddTaskSheet(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
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
      ),
    );
  }

  Widget _buildAddTaskSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _taskController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTask(),
                  decoration: const InputDecoration(
                    hintText: 'Task title...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addTask,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showDetails = !_showDetails),
            child: Row(
              children: <Widget>[
                Icon(
                  _showDetails
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Details',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (_deadline != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: scheme.tertiary),
                  const SizedBox(width: 2),
                  Text(
                    formatDueDate(_deadline),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showDetails) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Energy Level',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskEnergyRequirement.values.map((req) {
                return ChoiceChip(
                  selected: _energyRequirement == req,
                  onSelected: (_) => setState(() => _energyRequirement = req),
                  selectedColor: req.accent.withValues(alpha: 0.18),
                  side: BorderSide(color: req.accent.withValues(alpha: 0.35)),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(req.icon, size: 14, color: req.accent),
                      const SizedBox(width: 4),
                      Text(req.label),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Time Estimate',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FlowForgeState.todoEstimatePresets.map((min) {
                return ChoiceChip(
                  selected: _estimateMinutes == min,
                  onSelected: (_) => setState(() => _estimateMinutes = min),
                  label: Text('$min min'),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Due Date',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildDueChip('Today', DateTime.now()),
                _buildDueChip(
                  'Tomorrow',
                  DateTime.now().add(const Duration(days: 1)),
                ),
                _buildDueChip(
                  'This Week',
                  DateTime.now().add(const Duration(days: 7)),
                ),
                ActionChip(
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  label: const Text('Custom'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _deadline = picked);
                  },
                ),
                if (_deadline != null)
                  ActionChip(
                    avatar: Icon(
                      Icons.close,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    label: const Text('Clear'),
                    onPressed: () => setState(() => _deadline = null),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDueChip(String label, DateTime date) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _deadline != null && isSameDay(_deadline!, date);

    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _deadline = date),
      selectedColor: scheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? scheme.primary.withValues(alpha: 0.5)
            : scheme.outline.withValues(alpha: 0.5),
      ),
      label: Text(label),
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
