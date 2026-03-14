import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/todo_item.dart';
import '../models/task_status.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
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
    _projectId = context.read<ProjectState>().activeProjectId;

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
    final projectState = context.watch<ProjectState>();
    final activeProject = projectState.activeProject;
    final todayTodos = _filterTodos(widget.state.todayTodos, activeProject?.id);
    final backlogTodos = _filterTodos(
      widget.state.backlogTodos,
      activeProject?.id,
    );
    final doneTodos = _filterTodos(widget.state.doneTodos, activeProject?.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: SizedBox(
              width: double.infinity,
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
                    if (activeProject != null) ...<Widget>[
                      _projectScopeBanner(context, projectState),
                      const SizedBox(height: 16),
                    ],
                    KanbanColumn(
                      status: TaskStatus.today,
                      todos: todayTodos,
                      state: widget.state,
                      showWarning: true,
                    ),
                    const SizedBox(height: 12),
                    KanbanColumn(
                      status: TaskStatus.backlog,
                      todos: backlogTodos,
                      state: widget.state,
                    ),
                    const SizedBox(height: 12),
                    KanbanColumn(
                      status: TaskStatus.done,
                      todos: doneTodos,
                      state: widget.state,
                    ),
                  ],
                ),
              ),
            ),
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
    final activeProjectId = context.watch<ProjectState>().activeProjectId;
    final todayCount = _filterTodos(
      widget.state.todayTodos,
      activeProjectId,
    ).length;
    final doneCount = _filterTodos(
      widget.state.doneTodos,
      activeProjectId,
    ).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _buildStatItem(
            context,
            icon: Icons.today_rounded,
            count: todayCount,
            color: scheme.primary,
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 14, color: color.withValues(alpha: 0.24)),
          const SizedBox(width: 6),
          Text(
            icon == Icons.today_rounded ? 'Today' : 'Done',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _projectScopeBanner(BuildContext context, ProjectState projectState) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeProject = projectState.activeProject;
    if (activeProject == null) return const SizedBox.shrink();

    return Container(
      key: const ValueKey<String>('kanban-project-scope-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeProject.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeProject.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activeProject.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activeProject.icon, color: activeProject.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${activeProject.name} is filtering Tasks',
                  style: textTheme.titleSmall?.copyWith(
                    color: activeProject.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New tasks created here will default into this project until you clear the scope.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey<String>('kanban-clear-project-scope'),
            onPressed: () => projectState.setActiveProject(null),
            child: const Text('Show all'),
          ),
        ],
      ),
    );
  }

  List<TodoItem> _filterTodos(List<TodoItem> todos, String? activeProjectId) {
    if (activeProjectId == null) return todos;
    return todos.where((todo) => todo.projectId == activeProjectId).toList();
  }
}
