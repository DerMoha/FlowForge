import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import 'task_detail_sections.dart';

Future<void> openTaskEditorSheet(
  BuildContext context, {
  required TodoItem todo,
  required FlowForgeState state,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskEditorSheet(todo: todo, state: state),
  );
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, required this.todo, required this.state});

  final TodoItem todo;
  final FlowForgeState state;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
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
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.state.deleteTodo(widget.todo.id);
    Navigator.of(context).pop();
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
