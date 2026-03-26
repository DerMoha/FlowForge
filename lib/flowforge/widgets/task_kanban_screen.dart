import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/todo_item.dart';
import '../models/task_status.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';
import 'ambient_gradient_background.dart';
import 'kanban_column.dart';
import 'task_detail_sections.dart';
import 'task_ui_helpers.dart';

class TaskKanbanScreen extends StatefulWidget {
  const TaskKanbanScreen({
    super.key,
    required this.state,
    required this.onToggleTheme,
  });

  final FlowForgeState state;
  final VoidCallback onToggleTheme;

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
    return AmbientGradientBackground(
      energy: widget.state.energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isBoardLayout = constraints.maxWidth >= 900;
                  final horizontalPadding = isBoardLayout ? 24.0 : 20.0;
                  final bottomPadding = isBoardLayout ? 36.0 : 136.0;

                  return SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildPageHeader(
                            context,
                            scheme,
                            textTheme,
                            isBoardLayout: isBoardLayout,
                            todayCount: todayTodos.length,
                            backlogCount: backlogTodos.length,
                            doneCount: doneTodos.length,
                          ),
                          if (activeProject != null) ...<Widget>[
                            const SizedBox(height: 16),
                            _projectScopeBanner(context, projectState),
                          ],
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: isBoardLayout
                                ? _buildBoardLayout(
                                    context,
                                    todayTodos,
                                    backlogTodos,
                                    doneTodos,
                                  )
                                : _buildGroupedLayout(
                                    context,
                                    todayTodos,
                                    backlogTodos,
                                    doneTodos,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskSheet(BuildContext context) {
    return TaskSheetFrame(
      title: 'Add a task',
      subtitle:
          'Capture it calmly now, then decide later whether it belongs in Today or Backlog.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TaskTitleField(
                  controller: _taskController,
                  autofocus: true,
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _addTask,
                style: FilledButton.styleFrom(minimumSize: const Size(56, 56)),
                child: const Icon(Icons.add_rounded),
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
    );
  }

  Widget _buildGroupedLayout(
    BuildContext context,
    List<TodoItem> todayTodos,
    List<TodoItem> backlogTodos,
    List<TodoItem> doneTodos,
  ) {
    return Column(
      key: const ValueKey<String>('tasks-grouped-layout'),
      children: <Widget>[
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
    );
  }

  Widget _buildBoardLayout(
    BuildContext context,
    List<TodoItem> todayTodos,
    List<TodoItem> backlogTodos,
    List<TodoItem> doneTodos,
  ) {
    final boardHeight = (MediaQuery.sizeOf(context).height - 260).clamp(
      420.0,
      760.0,
    );

    return SizedBox(
      key: const ValueKey<String>('tasks-board-layout'),
      height: boardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: KanbanColumn(
              status: TaskStatus.today,
              todos: todayTodos,
              state: widget.state,
              showWarning: true,
              boardMode: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: KanbanColumn(
              status: TaskStatus.backlog,
              todos: backlogTodos,
              state: widget.state,
              boardMode: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: KanbanColumn(
              status: TaskStatus.done,
              todos: doneTodos,
              state: widget.state,
              boardMode: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme, {
    required bool isBoardLayout,
    required int todayCount,
    required int backlogCount,
    required int doneCount,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isBoardLayout ? 24 : 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tasks',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Plan today intentionally. Keep the active list lean and let backlog hold the rest.',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildHeaderPill(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: formatCompactDate(DateTime.now()),
                    color: scheme.primary,
                  ),
                  _buildHeaderPill(
                    context,
                    icon: Icons.today_rounded,
                    label: '$todayCount today',
                    color: scheme.primary,
                  ),
                  _buildHeaderPill(
                    context,
                    icon: Icons.inventory_2_rounded,
                    label: '$backlogCount backlog',
                    color: scheme.tertiary,
                  ),
                  _buildHeaderPill(
                    context,
                    icon: Icons.check_circle_rounded,
                    label: '$doneCount done',
                    color: scheme.secondary,
                  ),
                ],
              ),
            ],
          );

          final actionBlock = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: widget.onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddTaskSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(stacked ? 'Add task' : 'Capture task'),
              ),
            ],
          );

          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              if (stacked) titleBlock else Expanded(child: titleBlock),
              if (stacked)
                const SizedBox(height: 16)
              else
                const SizedBox(width: 16),
              actionBlock,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final details = Column(
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
          );

          final projectIcon = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activeProject.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activeProject.icon, color: activeProject.color),
          );

          final clearButton = TextButton(
            key: const ValueKey<String>('kanban-clear-project-scope'),
            onPressed: () => projectState.setActiveProject(null),
            child: const Text('Show all'),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    projectIcon,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 12),
                clearButton,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    projectIcon,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              clearButton,
            ],
          );
        },
      ),
    );
  }

  List<TodoItem> _filterTodos(List<TodoItem> todos, String? activeProjectId) {
    if (activeProjectId == null) return todos;
    return todos.where((todo) => todo.projectId == activeProjectId).toList();
  }
}
