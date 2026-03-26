import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../state/project_state.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 5),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: project.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(project.icon, size: compact ? 12 : 14, color: project.color),
              const SizedBox(width: 5),
              Text(
                project.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: project.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
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
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
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
