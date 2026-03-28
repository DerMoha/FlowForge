import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../state/analytics_state.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import 'ambient_gradient_background.dart';
import 'analytics_dashboard.dart';

Future<void> openWorkspaceHub(BuildContext context, FlowForgeState state) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => WorkspaceHubPage(state: state),
    ),
  );
}

class WorkspaceHubPage extends StatelessWidget {
  const WorkspaceHubPage({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();

    return AmbientGradientBackground(
      energy: state.energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1220),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (canPop) ...<Widget>[
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Workspace',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Projects and insights live together here so planning, review, and next moves stay in one calm place.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WorkspaceSummary(state: state),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 5,
                              child: _ProjectsPanel(state: state),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(flex: 6, child: _AnalyticsPanel()),
                          ],
                        );
                      }

                      return Column(
                        children: <Widget>[
                          _ProjectsPanel(state: state),
                          const SizedBox(height: 16),
                          const _AnalyticsPanel(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSummary extends StatelessWidget {
  const _WorkspaceSummary({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer2<ProjectState, AnalyticsState>(
      builder: (context, projectState, analyticsState, child) {
        final activeProject = projectState.activeProject;

        return _WorkspaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          activeProject == null
                              ? 'Everything is visible right now.'
                              : '${activeProject.name} is the active lane.',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeProject == null
                              ? 'Use projects when you want a cleaner working context, then use analytics to decide where momentum should go next.'
                              : 'Focus and Tasks are filtered to ${activeProject.name}. Clear the filter anytime, or use analytics to decide the best time to push this project forward.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _showProjectEditor(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add project'),
                      ),
                      if (activeProject != null)
                        OutlinedButton.icon(
                          key: const ValueKey<String>(
                            'workspace-summary-show-all',
                          ),
                          onPressed: () => projectState.setActiveProject(null),
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Show all tasks'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ResponsiveStatGrid(
                children: <Widget>[
                  _SummaryTile(
                    icon: Icons.folder_copy_rounded,
                    label: 'Projects',
                    value: '${projectState.projects.length}',
                    detail: activeProject == null
                        ? 'No project filter'
                        : '1 active filter',
                    color: scheme.primary,
                  ),
                  _SummaryTile(
                    icon: Icons.task_alt_rounded,
                    label: 'Open tasks',
                    value: '${state.openTodoCount}',
                    detail: '${state.completedTodoCount} completed',
                    color: scheme.secondary,
                  ),
                  _SummaryTile(
                    icon: Icons.bolt_rounded,
                    label: 'Sessions',
                    value: '${analyticsState.totalSessions}',
                    detail: '${analyticsState.totalMinutes} minutes logged',
                    color: scheme.tertiary,
                  ),
                  _SummaryTile(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${analyticsState.currentStreak}',
                    detail: analyticsState.currentStreak == 0
                        ? 'Start one today'
                        : 'Keep it alive today',
                    color: scheme.error,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectsPanel extends StatelessWidget {
  const _ProjectsPanel({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<ProjectState>(
      builder: (context, projectState, child) {
        final activeProject = projectState.activeProject;
        final projects = projectState.projects;

        return _WorkspaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Projects',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick an active lane, adjust project details, or keep everything visible.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _showProjectEditor(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (activeProject != null)
                _ActiveProjectCard(
                  project: activeProject,
                  state: state,
                  onClear: () => projectState.setActiveProject(null),
                )
              else
                _AllProjectsCard(state: state),
              const SizedBox(height: 16),
              ...projects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProjectCard(
                    project: project,
                    state: state,
                    isActive: project.id == projectState.activeProjectId,
                    onSetActive: () =>
                        projectState.setActiveProject(project.id),
                    onEdit: () => _showProjectEditor(context, project: project),
                    onDelete: projects.length > 1
                        ? () => _confirmDelete(context, project)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _WorkspaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Insights',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Review progress, patterns, predictions, and the next useful move without switching views.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const AnalyticsDashboard(compact: true),
        ],
      ),
    );
  }
}

Future<void> _showProjectEditor(BuildContext context, {Project? project}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProjectEditorSheet(project: project),
  );
}

Future<void> _confirmDelete(BuildContext context, Project project) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete project?'),
      content: Text(
        'Tasks will keep their titles, but ${project.name} will be removed.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (shouldDelete == true && context.mounted) {
    await context.read<ProjectState>().deleteProject(project.id);
  }
}

class _ActiveProjectCard extends StatelessWidget {
  const _ActiveProjectCard({
    required this.project,
    required this.state,
    required this.onClear,
  });

  final Project project;
  final FlowForgeState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final openCount = state.openTodos
        .where((todo) => todo.projectId == project.id)
        .length;
    final doneCount = state.completedTodos
        .where((todo) => todo.projectId == project.id)
        .length;

    return _WorkspaceInsetCard(
      key: const ValueKey<String>('workspace-active-project-card'),
      borderColor: project.color.withValues(alpha: 0.34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ProjectAvatar(project: project),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Active project',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      project.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((project.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              project.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _ResponsiveStatGrid(
            children: <Widget>[
              _SummaryTile(
                icon: Icons.inventory_2_rounded,
                label: 'Open',
                value: '$openCount',
                detail: 'Still in motion',
                color: scheme.primary,
              ),
              _SummaryTile(
                icon: Icons.check_circle_rounded,
                label: 'Done',
                value: '$doneCount',
                detail: 'Completed so far',
                color: scheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey<String>('workspace-show-all-projects'),
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Show all tasks'),
          ),
        ],
      ),
    );
  }
}

class _AllProjectsCard extends StatelessWidget {
  const _AllProjectsCard({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _WorkspaceInsetCard(
      key: const ValueKey<String>('workspace-all-projects-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'All tasks are visible',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Set an active project when you want Focus and Tasks to narrow down to one stream of work.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _ResponsiveStatGrid(
            children: <Widget>[
              _SummaryTile(
                icon: Icons.inventory_2_rounded,
                label: 'Open',
                value: '${state.openTodoCount}',
                detail: 'Ready to work',
                color: scheme.primary,
              ),
              _SummaryTile(
                icon: Icons.check_circle_rounded,
                label: 'Done',
                value: '${state.completedTodoCount}',
                detail: 'Already finished',
                color: scheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.state,
    required this.isActive,
    required this.onSetActive,
    required this.onEdit,
    this.onDelete,
  });

  final Project project;
  final FlowForgeState state;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final openCount = state.openTodos
        .where((todo) => todo.projectId == project.id)
        .length;
    final dueSoonCount = state.openTodos
        .where((todo) => todo.projectId == project.id && todo.deadline != null)
        .length;

    return _WorkspaceInsetCard(
      borderColor: isActive
          ? project.color.withValues(alpha: 0.42)
          : scheme.outlineVariant.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ProjectAvatar(project: project),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          project.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: project.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Active',
                              style: textTheme.labelSmall?.copyWith(
                                color: project.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (project.description ?? '').isNotEmpty
                          ? project.description!
                          : 'No description yet. Use this space to define what belongs here.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaChip(
                icon: Icons.inventory_2_rounded,
                text: '$openCount open',
              ),
              _MetaChip(
                icon: Icons.schedule_rounded,
                text: '$dueSoonCount dated',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (!isActive)
                FilledButton.tonalIcon(
                  key: ValueKey<String>('set-active-project-${project.id}'),
                  onPressed: onSetActive,
                  icon: const Icon(Icons.push_pin_outlined),
                  label: const Text('Set active'),
                ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectAvatar extends StatelessWidget {
  const _ProjectAvatar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: project.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(project.icon, color: project.color),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _WorkspaceInsetCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(detail, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ResponsiveStatGrid extends StatelessWidget {
  const _ResponsiveStatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = (width / 180).floor().clamp(1, 4);
        final spacing = 12.0;
        final tileWidth = count == 1
            ? width
            : (width - ((count - 1) * spacing)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: tileWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.8 : 0.92,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: child,
    );
  }
}

class _WorkspaceInsetCard extends StatelessWidget {
  const _WorkspaceInsetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: child,
    );
  }
}

class _ProjectEditorSheet extends StatefulWidget {
  const _ProjectEditorSheet({this.project});

  final Project? project;

  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Color _selectedColor;
  late IconData _selectedIcon;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _selectedColor = widget.project?.color ?? ProjectColors.blue;
    _selectedIcon = widget.project?.icon ?? ProjectIcons.folder;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) return;

    final projectState = context.read<ProjectState>();

    if (_isEditing) {
      await projectState.updateProject(
        widget.project!.copyWith(
          name: name,
          color: _selectedColor,
          icon: _selectedIcon,
          description: description.isEmpty ? null : description,
          clearDescription: description.isEmpty,
        ),
      );
    } else {
      await projectState.addProject(
        name: name,
        color: _selectedColor,
        icon: _selectedIcon,
        description: description.isEmpty ? null : description,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              _isEditing ? 'Edit project' : 'Add project',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Projects stay lightweight, but they should still be easy to maintain.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional context for what belongs here',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ProjectColors.all.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? scheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: scheme.onPrimary,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ProjectIcons.all.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withValues(alpha: 0.16)
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.45)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _selectedColor
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.add_rounded,
                ),
                label: Text(_isEditing ? 'Save project' : 'Create project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
