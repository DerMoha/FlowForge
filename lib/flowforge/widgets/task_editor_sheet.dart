import 'package:flutter/material.dart';

import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../state/app_state.dart';
import 'task_detail_sections.dart';
import 'task_ui_helpers.dart';

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

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('"${widget.todo.title}" will be removed permanently.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskSheetFrame(
      title: 'Edit task',
      subtitle:
          'Adjust the title, scope, effort, and timing without changing how tasks work underneath.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TaskTitleField(
                  controller: _titleController,
                  autofocus: true,
                  onSubmitted: (_) => _save(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size(56, 56)),
                child: const Icon(Icons.check_rounded),
              ),
            ],
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
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
