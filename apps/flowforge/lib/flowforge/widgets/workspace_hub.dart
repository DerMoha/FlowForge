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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[
                  _PageHeader(
                    canPop: canPop,
                    onAddProject: () => _showProjectEditor(context),
                  ),
                  const SizedBox(height: 14),
                  _StatsStrip(state: state),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 5,
                              child: _ProjectsSection(state: state),
                            ),
                            const SizedBox(width: 20),
                            Expanded(flex: 6, child: _AnalyticsSection()),
                          ],
                        );
                      }

                      return Column(
                        children: <Widget>[
                          _ProjectsSection(state: state),
                          const SizedBox(height: 20),
                          _AnalyticsSection(),
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

// ─────────────────────────────────────────────────────────────
// Page header — title + single "New project" entry point
// ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.canPop, required this.onAddProject});

  final bool canPop;
  final VoidCallback onAddProject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (canPop) ...<Widget>[
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            'Workspace',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onAddProject,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New project'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats strip — compact horizontal pills
// ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectState, AnalyticsState>(
      builder: (context, projectState, analyticsState, _) {
        final isFiltered = projectState.activeProject != null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _StatPill(
                icon: Icons.folder_copy_rounded,
                value: '${projectState.projects.length}',
                label: 'projects',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.task_alt_rounded,
                value: '${state.openTodoCount}',
                label: isFiltered ? 'filtered' : 'open tasks',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.bolt_rounded,
                value: '${analyticsState.totalSessions}',
                label: 'sessions',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '${analyticsState.currentStreak}',
                label: 'day streak',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Projects section
// ─────────────────────────────────────────────────────────────

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<ProjectState>(
      builder: (context, projectState, _) {
        final projects = projectState.projects;

        return _WorkspaceCard(
          key: ValueKey<String>(
            projectState.activeProjectId == null
                ? 'workspace-all-projects-card'
                : 'workspace-active-project-card',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Projects',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _SectionBadge(count: projects.length),
                  if (projectState.activeProject != null)
                    TextButton.icon(
                      key: const ValueKey<String>('workspace-summary-show-all'),
                      onPressed: () => projectState.setActiveProject(null),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                      label: const Text('Clear focus'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                        textStyle: textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...projects.asMap().entries.map((entry) {
                final index = entry.key;
                final project = entry.value;
                final isActive = project.id == projectState.activeProjectId;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < projects.length - 1 ? 10 : 0,
                  ),
                  child: _ProjectCard(
                    project: project,
                    state: state,
                    isActive: isActive,
                    onSetActive: () =>
                        projectState.setActiveProject(project.id),
                    onClearActive: () => projectState.setActiveProject(null),
                    onEdit: () => _showProjectEditor(context, project: project),
                    onDelete: projects.length > 1
                        ? () => _confirmDelete(context, project)
                        : null,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project card — tappable, colored left strip for active state
// ─────────────────────────────────────────────────────────────

enum _ProjectAction { setActive, clearActive, edit, delete }

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.state,
    required this.isActive,
    required this.onSetActive,
    required this.onClearActive,
    required this.onEdit,
    this.onDelete,
  });

  final Project project;
  final FlowForgeState state;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onClearActive;
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: <Widget>[
          Material(
            color: isActive
                ? project.color.withValues(alpha: 0.07)
                : scheme.surfaceContainerHigh.withValues(alpha: 0.72),
            child: InkWell(
              onTap: isActive ? null : onSetActive,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? project.color.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                              const SizedBox(height: 2),
                              Text(
                                project.name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if ((project.description ?? '')
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  project.description!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<_ProjectAction>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _ProjectAction.setActive:
                                onSetActive();
                              case _ProjectAction.clearActive:
                                onClearActive();
                              case _ProjectAction.edit:
                                onEdit();
                              case _ProjectAction.delete:
                                onDelete?.call();
                            }
                          },
                          itemBuilder: (_) => <PopupMenuEntry<_ProjectAction>>[
                            if (!isActive)
                              const PopupMenuItem<_ProjectAction>(
                                value: _ProjectAction.setActive,
                                child: ListTile(
                                  leading: Icon(Icons.push_pin_outlined),
                                  title: Text('Set as focus'),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (isActive)
                              const PopupMenuItem<_ProjectAction>(
                                value: _ProjectAction.clearActive,
                                child: ListTile(
                                  leading: Icon(Icons.push_pin_rounded),
                                  title: Text('Clear focus'),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<_ProjectAction>(
                              value: _ProjectAction.edit,
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            if (onDelete != null)
                              PopupMenuItem<_ProjectAction>(
                                value: _ProjectAction.delete,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline_rounded,
                                    color: scheme.error,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: scheme.error),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _MetaChip(
                          icon: Icons.inventory_2_rounded,
                          text: '$openCount open',
                        ),
                        if (dueSoonCount > 0)
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            text: '$dueSoonCount dated',
                          ),
                        if (isActive)
                          _MetaChip(
                            icon: Icons.push_pin_rounded,
                            text: 'Focus',
                            accentColor: project.color,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Colored left strip — only visible when active
          if (isActive)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: project.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Analytics section — no wrapper, dashboard renders itself
// ─────────────────────────────────────────────────────────────

class _AnalyticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _WorkspaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Insights',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const AnalyticsDashboard(compact: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Modals
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Shared small components
// ─────────────────────────────────────────────────────────────

class _ProjectAvatar extends StatelessWidget {
  const _ProjectAvatar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: project.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(project.icon, color: project.color, size: 20),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.accentColor});

  final IconData icon;
  final String text;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = accentColor ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor != null
            ? accentColor!.withValues(alpha: 0.1)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: accentColor != null
            ? Border.all(color: accentColor!.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: accentColor != null ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({super.key, required this.child});

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

// ─────────────────────────────────────────────────────────────
// Project editor sheet (unchanged)
// ─────────────────────────────────────────────────────────────

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
