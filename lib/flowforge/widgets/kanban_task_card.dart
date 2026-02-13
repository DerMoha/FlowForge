import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';

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
            if (onDelete != null)
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _energyRequirement = widget.todo.energyRequirement;
    _estimateMinutes = widget.todo.estimateMinutes;
    _status = widget.todo.status;
    _deadline = widget.todo.deadline;
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
              'Status',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskStatus.values.map((s) {
                return ChoiceChip(
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: _getStatusColor(
                    s,
                    scheme,
                  ).withValues(alpha: 0.18),
                  side: BorderSide(
                    color: _getStatusColor(s, scheme).withValues(alpha: 0.35),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _getStatusIcon(s),
                        size: 14,
                        color: _getStatusColor(s, scheme),
                      ),
                      const SizedBox(width: 4),
                      Text(s.label),
                    ],
                  ),
                );
              }).toList(),
            ),
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

  Color _getStatusColor(TaskStatus status, ColorScheme scheme) {
    switch (status) {
      case TaskStatus.today:
        return scheme.primary;
      case TaskStatus.backlog:
        return scheme.tertiary;
      case TaskStatus.done:
        return scheme.secondary;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.today:
        return Icons.today_rounded;
      case TaskStatus.backlog:
        return Icons.inventory_2_rounded;
      case TaskStatus.done:
        return Icons.check_circle_outline_rounded;
    }
  }
}
