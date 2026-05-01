import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../state/project_state.dart';
import 'flow_ui.dart';

class TaskMetaChip extends StatelessWidget {
  const TaskMetaChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FlowMetaChip(icon: icon, label: text, color: color, filled: true);
  }
}

class TaskProjectBadge extends StatelessWidget {
  const TaskProjectBadge({
    super.key,
    required this.todo,
    this.compact = false,
    this.showName = true,
  });

  final TodoItem todo;
  final bool compact;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    if (todo.projectId == null) {
      return const SizedBox.shrink();
    }

    return Consumer<ProjectState>(
      builder: (context, projectState, _) {
        final project = projectState.getProject(todo.projectId!);
        if (project == null) {
          return const SizedBox.shrink();
        }

        if (!showName) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: project.color,
              shape: BoxShape.circle,
            ),
          );
        }

        return FlowMetaChip(
          icon: project.icon,
          label: project.name,
          color: project.color,
          filled: true,
        );
      },
    );
  }
}

class TaskSheetFrame extends StatelessWidget {
  const TaskSheetFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return FlowSheetFrame(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class TaskTitleField extends StatelessWidget {
  const TaskTitleField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      maxLines: 2,
      minLines: 1,
      decoration: const InputDecoration(
        hintText: 'What needs to happen?',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.task_alt_rounded),
      ),
    );
  }
}
