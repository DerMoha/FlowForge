import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import '../utils/date_helpers.dart';
import 'task_detail_sections.dart';

class KanbanTaskCard extends StatelessWidget {
  const KanbanTaskCard({
    super.key,
    required this.todo,
    required this.state,
    this.onTap,
    this.onDelete,
  });

  final TodoItem todo;
  final FlowForgeState state;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = todo.isOverdue;
    final dueDateText = formatDueDate(todo.deadline);

    return Draggable<TodoItem>(
      data: todo,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: todo.energyRequirement.accent.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: _buildContent(
            context,
            scheme,
            textTheme,
            isDark,
            isOverdue,
            dueDateText,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCard(
          context,
          scheme,
          textTheme,
          isDark,
          isOverdue,
          dueDateText,
        ),
      ),
      child: _buildCard(
        context,
        scheme,
        textTheme,
        isDark,
        isOverdue,
        dueDateText,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool isDark,
    bool isOverdue,
    String dueDateText,
  ) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue
              ? scheme.errorContainer.withValues(alpha: isDark ? 0.2 : 0.15)
              : scheme.surfaceContainerLow.withValues(
                  alpha: isDark ? 0.8 : 0.95,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? scheme.error.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(
          context,
          scheme,
          textTheme,
          isDark,
          isOverdue,
          dueDateText,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTaskSheet(todo: todo, state: state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool isDark,
    bool isOverdue,
    String dueDateText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Consumer<ProjectState>(
              builder: (context, projectState, _) {
                final project = todo.projectId != null
                    ? projectState.getProject(todo.projectId!)
                    : null;
                if (project == null) return const SizedBox.shrink();
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: project.color,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            Icon(
              todo.energyRequirement.icon,
              size: 18,
              color: todo.energyRequirement.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                todo.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                  color: todo.isDone ? scheme.onSurfaceVariant : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            _buildTag(
              context,
              icon: Icons.timer_outlined,
              text: '${todo.estimateMinutes}m',
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
            if (dueDateText.isNotEmpty)
              _buildTag(
                context,
                icon: isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                text: dueDateText,
                color: isOverdue ? scheme.error : scheme.tertiary,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ActionChip(
              avatar: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              onPressed: () => _showEditSheet(context),
            ),
            if (todo.status == TaskStatus.backlog)
              ActionChip(
                avatar: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Move to Today'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.today),
              ),
            if (todo.status == TaskStatus.today)
              ActionChip(
                avatar: const Icon(Icons.inventory_2_rounded, size: 16),
                label: const Text('Backlog'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.backlog),
              ),
            if (!todo.isDone)
              ActionChip(
                avatar: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                label: const Text('Done'),
                onPressed: () =>
                    state.moveTaskToStatus(todo.id, TaskStatus.done),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditTaskSheet extends StatefulWidget {
  const _EditTaskSheet({required this.todo, required this.state});

  final TodoItem todo;
  final FlowForgeState state;

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late TextEditingController _titleController;
  late TaskEnergyRequirement _energyRequirement;
  late int _estimateMinutes;
  late TaskStatus _status;
  DateTime? _deadline;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _energyRequirement = widget.todo.energyRequirement;
    _estimateMinutes = widget.todo.estimateMinutes;
    _status = widget.todo.status;
    _deadline = widget.todo.deadline;
    _projectId = widget.todo.projectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    widget.state.updateTodo(
      id: widget.todo.id,
      title: title,
      energyRequirement: _energyRequirement,
      estimateMinutes: _estimateMinutes,
      status: _status,
      deadline: _deadline,
      projectId: _projectId,
      clearDeadline: _deadline == null,
      clearProjectId: _projectId == null,
    );
    Navigator.pop(context);
  }

  void _delete() {
    widget.state.deleteTodo(widget.todo.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      hintText: 'Task title...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 56),
                  ),
                  child: const Icon(Icons.check),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Edit task',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep the title clear, then update where it belongs and when it is due.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TaskDetailSections(
              keyPrefix: 'task-edit',
              status: _status,
              onStatusChanged: (value) => setState(() => _status = value),
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
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Task'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
