import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../state/app_state.dart';
import 'kanban_column.dart';
import 'task_detail_sections.dart';

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
  String? _projectId;

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
      projectId: _projectId,
    );

    _taskController.clear();
    _deadline = null;
    _projectId = null;
    Navigator.pop(context);
  }

  void _showAddTaskSheet() {
    _taskController.clear();
    _energyRequirement = TaskEnergyRequirement.medium;
    _estimateMinutes = 25;
    _deadline = null;
    _projectId = null;

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
              const SizedBox(height: 8),
              Text(
                'Choose what deserves today and keep the rest organized.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
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
      child: SingleChildScrollView(
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
            Text(
              'Add a task',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create it once, then decide later if it belongs in Today.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 56),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TaskDetailSections(
              keyPrefix: 'kanban-add',
              energyRequirement: _energyRequirement,
              onEnergyChanged: (value) =>
                  setState(() => _energyRequirement = value),
              estimateMinutes: _estimateMinutes,
              onEstimateChanged: (value) =>
                  setState(() => _estimateMinutes = value),
              deadline: _deadline,
              onDeadlineChanged: (value) => setState(() => _deadline = value),
              projectId: _projectId,
              onProjectChanged: (value) => setState(() => _projectId = value),
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
