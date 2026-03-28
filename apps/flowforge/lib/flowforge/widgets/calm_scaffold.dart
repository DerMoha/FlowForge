import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';
import 'activity_heatmap.dart';
import 'ambient_gradient_background.dart';
import 'collapsible_section.dart';
import 'focus_home_sections.dart';
import 'focus_mode_transition.dart';
import 'focus_support_cards.dart';
import 'focus_timer_ring.dart';
import 'hero_task_card.dart';
import 'session_stats_bar.dart';
import 'task_input_bar.dart';
import 'task_river.dart';

class CalmScaffold extends StatefulWidget {
  const CalmScaffold({
    super.key,
    required this.state,
    required this.onToggleTheme,
  });

  final FlowForgeState state;
  final VoidCallback onToggleTheme;

  @override
  State<CalmScaffold> createState() => _CalmScaffoldState();
}

class _CalmScaffoldState extends State<CalmScaffold> {
  static const double _desktopBreakpoint = 920;

  bool _activityExpanded = false;

  FlowForgeState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _state.onShowSnack = _handleSnack;
    _state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(CalmScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.onShowSnack = null;
      oldWidget.state.removeListener(_onStateChanged);
      _state.onShowSnack = _handleSnack;
      _state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    _state.onShowSnack = null;
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _handleSnack() {
    final message = _state.pendingSnackMessage;
    if (message == null) return;
    _state.consumeSnack();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectState>();
    final activeProject = projectState.activeProject;
    final filteredOpenTodos = _filterTodos(
      _state.sortedOpenTodos,
      projectId: activeProject?.id,
    );
    final filteredCompletedTodos = _filterTodos(
      _state.completedTodos,
      projectId: activeProject?.id,
    );
    final filteredTodayTodos = _filterTodos(
      _state.todayTodos,
      projectId: activeProject?.id,
    );
    final visibleHeroTodo = _pickHeroTodo(filteredOpenTodos, activeProject?.id);

    return AmbientGradientBackground(
      energy: _state.energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
                  final horizontalPadding = isDesktop ? 24.0 : 20.0;
                  final contentPadding = EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    24,
                  );

                  return Column(
                    children: <Widget>[
                      _focusHeader(context),
                      if (activeProject != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            16,
                          ),
                          child: ProjectScopeBanner(projectState: projectState),
                        ),
                      Expanded(
                        child: isDesktop
                            ? _buildDesktopBody(
                                context,
                                contentPadding: contentPadding,
                                activeProjectName: activeProject?.name,
                                todayCount: filteredTodayTodos.length,
                                openCount: filteredOpenTodos.length,
                                visibleHeroTodo: visibleHeroTodo,
                                filteredOpenTodos: filteredOpenTodos,
                                filteredCompletedTodos: filteredCompletedTodos,
                              )
                            : _buildMobileBody(
                                context,
                                contentPadding: contentPadding,
                                activeProjectName: activeProject?.name,
                                todayCount: filteredTodayTodos.length,
                                openCount: filteredOpenTodos.length,
                                visibleHeroTodo: visibleHeroTodo,
                                filteredOpenTodos: filteredOpenTodos,
                                filteredCompletedTodos: filteredCompletedTodos,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context, {
    required EdgeInsets contentPadding,
    required String? activeProjectName,
    required int todayCount,
    required int openCount,
    required TodoItem? visibleHeroTodo,
    required List<TodoItem> filteredOpenTodos,
    required List<TodoItem> filteredCompletedTodos,
  }) {
    return Padding(
      padding: contentPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _loopOverview(
                    activeProjectName: activeProjectName,
                    todayCount: todayCount,
                    openCount: openCount,
                  ),
                  const SizedBox(height: 18),
                  _captureSection(),
                  const SizedBox(height: 18),
                  _chooseSection(
                    context,
                    visibleHeroTodo: visibleHeroTodo,
                    filteredOpenTodos: filteredOpenTodos,
                    filteredCompletedTodos: filteredCompletedTodos,
                  ),
                  const SizedBox(height: 18),
                  _reviewSection(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 360,
            child: Column(
              children: <Widget>[
                _focusSection(context),
                const SizedBox(height: 18),
                TodayRhythmCard(state: _state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(
    BuildContext context, {
    required EdgeInsets contentPadding,
    required String? activeProjectName,
    required int todayCount,
    required int openCount,
    required TodoItem? visibleHeroTodo,
    required List<TodoItem> filteredOpenTodos,
    required List<TodoItem> filteredCompletedTodos,
  }) {
    return SingleChildScrollView(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _captureSection(),
          const SizedBox(height: 18),
          _loopOverview(
            activeProjectName: activeProjectName,
            todayCount: todayCount,
            openCount: openCount,
          ),
          const SizedBox(height: 18),
          _chooseSection(
            context,
            visibleHeroTodo: visibleHeroTodo,
            filteredOpenTodos: filteredOpenTodos,
            filteredCompletedTodos: filteredCompletedTodos,
          ),
          const SizedBox(height: 18),
          _focusSection(context),
          const SizedBox(height: 18),
          TodayRhythmCard(state: _state),
          const SizedBox(height: 18),
          _reviewSection(),
        ],
      ),
    );
  }

  Widget _focusHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _state.activeEnergyPreset;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Focus',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatCompactDate(DateTime.now())}  |  Capture, choose, focus, review.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _state.isRunning
                    ? 'Stay with the current block. Everything else can wait.'
                    : 'Start with one small capture, then commit to the clearest next block.',
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
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
                const SizedBox(height: 14)
              else
                const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FocusHeaderBadge(
                    label: '${active.label} ${active.value}%',
                    icon: active.icon,
                    color: active.color,
                    onTap: () => showFocusEnergySheet(context, _state),
                  ),
                  IconButton.filledTonal(
                    tooltip: isDark
                        ? 'Switch to light mode'
                        : 'Switch to dark mode',
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _loopOverview({
    required String? activeProjectName,
    required int todayCount,
    required int openCount,
  }) {
    final active = _state.activeEnergyPreset;

    return FocusLoopOverview(
      energyLabel: active.label,
      energyHint: active.hint,
      activeProjectName: activeProjectName,
      todayCount: todayCount,
      openCount: openCount,
      momentumScore: _state.momentumScore,
    );
  }

  Widget _captureSection() {
    return FocusSectionCard(
      step: '1. Capture',
      icon: Icons.edit_note_rounded,
      title: 'Get it out of your head',
      description:
          'Capture the next task quickly so the rest of the screen can help you decide what deserves a block.',
      child: FocusModeTransition(
        isFocusMode: _state.isRunning,
        child: TaskInputBar(state: _state),
      ),
    );
  }

  Widget _chooseSection(
    BuildContext context, {
    required TodoItem? visibleHeroTodo,
    required List<TodoItem> filteredOpenTodos,
    required List<TodoItem> filteredCompletedTodos,
  }) {
    return FocusSectionCard(
      step: '2. Choose',
      icon: Icons.track_changes_rounded,
      title: 'Pick the best next move',
      description:
          'Let the hero task lead, then keep the surrounding queue visible without crowding the decision.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HeroTaskCard(state: _state, todo: visibleHeroTodo),
          const SizedBox(height: 16),
          Text(
            'Supporting queue',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep Today lean. Everything else waits here until it earns your attention.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FocusModeTransition(
            isFocusMode: _state.isRunning,
            child: TaskRiver(
              state: _state,
              openTodos: filteredOpenTodos,
              completedTodos: filteredCompletedTodos,
              heroTodoId: visibleHeroTodo?.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusSection(BuildContext context) {
    return FocusSectionCard(
      step: '3. Focus',
      icon: Icons.timer_rounded,
      title: 'Keep the timer in view',
      description:
          'One visible timer makes it easier to start, stay steady, and return when your attention drifts.',
      child: FocusTimerRing(state: _state),
    );
  }

  Widget _reviewSection() {
    return FocusSectionCard(
      step: '4. Review',
      icon: Icons.self_improvement_rounded,
      title: 'Notice the pattern, then reset calmly',
      description:
          'Review momentum and recent activity without turning the home screen into a dashboard wall.',
      child: CollapsibleSection(
        title: 'Activity and momentum',
        icon: Icons.insights_rounded,
        isExpanded: _activityExpanded,
        onToggle: () => setState(() => _activityExpanded = !_activityExpanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SessionStatsBar(state: _state),
            const SizedBox(height: 14),
            ActivityHeatmap(state: _state),
          ],
        ),
      ),
    );
  }

  List<TodoItem> _filterTodos(List<TodoItem> todos, {String? projectId}) {
    if (projectId == null) return todos;
    return todos.where((todo) => todo.projectId == projectId).toList();
  }

  TodoItem? _pickHeroTodo(List<TodoItem> todos, String? projectId) {
    final focused = _state.focusedTodo;
    if (focused != null &&
        (projectId == null || focused.projectId == projectId)) {
      return todos.cast<TodoItem?>().firstWhere(
        (todo) => todo?.id == focused.id,
        orElse: () => todos.isEmpty ? null : todos.first,
      );
    }
    return todos.isEmpty ? null : todos.first;
  }
}
