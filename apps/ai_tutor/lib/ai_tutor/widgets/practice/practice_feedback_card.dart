import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/practice.dart';

class PracticeFeedbackCard extends StatelessWidget {
  const PracticeFeedbackCard({
    super.key,
    required this.cell,
    this.onAcceptSubtask,
    this.onReturnToParent,
  });

  final PracticeCell cell;
  final VoidCallback? onAcceptSubtask;
  final VoidCallback? onReturnToParent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = cell.action;
    final isBridge = cell.metadata['action'] == 'bridge';

    Color borderColor;
    IconData icon;
    Color iconColor;

    if (isBridge) {
      borderColor = theme.colorScheme.tertiary;
      icon = Icons.arrow_back_rounded;
      iconColor = theme.colorScheme.tertiary;
    } else {
      switch (action) {
        case PracticeAction.correct:
          borderColor = Colors.green;
          icon = Icons.check_circle_outline;
          iconColor = Colors.green;
        case PracticeAction.hint:
          borderColor = Colors.orange;
          icon = Icons.lightbulb_outline;
          iconColor = Colors.orange;
        case PracticeAction.suggestSubtask:
          borderColor = theme.colorScheme.primary;
          icon = Icons.fork_right_outlined;
          iconColor = theme.colorScheme.primary;
        case PracticeAction.partial:
          borderColor = Colors.blue;
          icon = Icons.trending_up;
          iconColor = Colors.blue;
        case null:
          borderColor = theme.colorScheme.outlineVariant;
          icon = Icons.info_outline;
          iconColor = theme.colorScheme.onSurfaceVariant;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  isBridge
                      ? 'Back to main task'
                      : _actionLabel(action),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cell.score != null) ...[
                  const Spacer(),
                  Text(
                    '${(cell.score! * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(cell.content, style: theme.textTheme.bodyMedium),

            // Sub-task suggestion actions
            if (action == PracticeAction.suggestSubtask &&
                cell.subtaskTopic != null) ...[
              const SizedBox(height: 12),
              if (cell.metadata['subtask_reason'] != null)
                Text(
                  cell.metadata['subtask_reason'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onAcceptSubtask,
                    icon: const Icon(Icons.school_outlined, size: 16),
                    label: Text('Practice: ${cell.subtaskTopic}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {}, // decline — handled by parent
                    child: const Text('Keep going'),
                  ),
                ],
              ),
            ],

            // Bridge message return button
            if (isBridge && onReturnToParent != null) ...[
              const SizedBox(height: 12),
              if (cell.metadata['updated_hint'] != null) ...[
                Text(
                  'Hint: ${cell.metadata['updated_hint']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: onReturnToParent,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Continue main task'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(PracticeAction? action) {
    switch (action) {
      case PracticeAction.correct:
        return 'Correct!';
      case PracticeAction.hint:
        return 'Hint';
      case PracticeAction.suggestSubtask:
        return 'Prerequisite suggested';
      case PracticeAction.partial:
        return 'Good progress';
      case null:
        return 'Feedback';
    }
  }
}
