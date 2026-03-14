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
      fullscreenDialog: true,
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

    return DefaultTabController(
      length: 2,
      child: AmbientGradientBackground(
        energy: state.energy,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
                        child: Row(
                          children: <Widget>[
                            IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Workspace',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Projects and analytics live here so Focus and Tasks stay simple.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _WorkspaceSummary(state: state),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh.withValues(
                              alpha: 0.76,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            padding: const EdgeInsets.all(6),
                            indicator: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelColor: scheme.onPrimaryContainer,
                            unselectedLabelColor: scheme.onSurfaceVariant,
                            tabs: const <Widget>[
                              Tab(text: 'Projects'),
                              Tab(text: 'Analytics'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            _ProjectsPanel(state: state),
                            const _AnalyticsPanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ProjectState, AnalyticsState>(
      builder: (context, projectState, analyticsState, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(
              alpha: isDark ? 0.78 : 0.9,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Secondary surfaces, one obvious home',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                projectState.activeProject == null
                    ? 'Use Projects to give tasks context and Analytics to review patterns without crowding the main workflow.'
                    : 'Project scope is active now, so Focus and Tasks are filtered to ${projectState.activeProject!.name}.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (projectState.activeProject != null) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('workspace-summary-show-all'),
                    onPressed: () => projectState.setActiveProject(null),
                    icon: const Icon(Icons.filter_alt_off_rounded),
                    label: const Text('Show all tasks'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _SummaryPill(
                    icon: Icons.folder_copy_rounded,
                    label: 'Projects',
                    value: '${projectState.projects.length}',
                    color: scheme.primary,
                  ),
                  _SummaryPill(
                    icon: Icons.task_alt_rounded,
                    label: 'Open Tasks',
                    value: '${state.openTodoCount}',
                    color: scheme.secondary,
                  ),
                  _SummaryPill(
                    icon: Icons.bolt_rounded,
                    label: 'Sessions',
                    value: '${analyticsState.totalSessions}',
                    color: scheme.tertiary,
                  ),
                  _SummaryPill(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${analyticsState.currentStreak}',
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

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                        'Keep ownership visible on tasks without promoting projects to a main navigation tab.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (activeProject != null)
                      OutlinedButton.icon(
                        onPressed: () => projectState.setActiveProject(null),
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Show All'),
                      ),
                    FilledButton.icon(
                      onPressed: () => _showProjectEditor(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                    ),
                  ],
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
                  onSetActive: () => projectState.setActiveProject(project.id),
                  onEdit: () => _showProjectEditor(context, project: project),
                  onDelete: projects.length > 1
                      ? () => _confirmDelete(context, project)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
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

    return Container(
      key: const ValueKey<String>('workspace-active-project-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: project.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(project.icon, color: project.color),
              ),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _SummaryPill(
                icon: Icons.inventory_2_rounded,
                label: 'Open',
                value: '$openCount',
                color: scheme.primary,
              ),
              _SummaryPill(
                icon: Icons.check_circle_rounded,
                label: 'Done',
                value: '$doneCount',
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

    return Container(
      key: const ValueKey<String>('workspace-all-projects-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'All tasks are visible',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose an active project only when you want Focus and Tasks to narrow down to one stream of work.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _SummaryPill(
                icon: Icons.inventory_2_rounded,
                label: 'Open',
                value: '${state.openTodoCount}',
                color: scheme.primary,
              ),
              _SummaryPill(
                icon: Icons.check_circle_rounded,
                label: 'Done',
                value: '${state.completedTodoCount}',
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive
              ? project.color.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(project.icon, color: project.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            project.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isActive) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (project.description ?? '').isNotEmpty
                          ? project.description!
                          : 'No description yet. Use this to group related work.',
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
              _metaChip(context, Icons.inventory_2_rounded, '$openCount open'),
              _metaChip(context, Icons.schedule_rounded, '$dueSoonCount dated'),
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
                  label: const Text('Set Active'),
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

  Widget _metaChip(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.76),
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

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Analytics',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Review momentum and patterns here instead of scattering insights across the main task flow.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: const AnalyticsDashboard(),
            ),
          ),
        ],
      ),
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
              'Projects stay secondary, but they should still be easy to maintain.',
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
