import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/practice.dart';
import '../../state/practice_state.dart';
import 'practice_feedback_card.dart';

class PracticeCellWidget extends StatefulWidget {
  const PracticeCellWidget({
    super.key,
    required this.cell,
    required this.isLast,
  });

  final PracticeCell cell;
  final bool isLast;

  @override
  State<PracticeCellWidget> createState() => _PracticeCellWidgetState();
}

class _PracticeCellWidgetState extends State<PracticeCellWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.content);
  }

  @override
  void didUpdateWidget(PracticeCellWidget old) {
    super.didUpdateWidget(old);
    // Keep controller in sync with external content updates
    if (old.cell.id != widget.cell.id) {
      _controller.text = widget.cell.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.cell.cellType) {
      case PracticeCellType.task:
        return _TaskCell(cell: widget.cell);
      case PracticeCellType.work:
        return _WorkCell(
          cell: widget.cell,
          controller: _controller,
          isActive: widget.isLast,
        );
      case PracticeCellType.feedback:
        return _FeedbackCellWrapper(cell: widget.cell);
    }
  }
}

// ── Task Cell ──

class _TaskCell extends StatelessWidget {
  const _TaskCell({required this.cell});

  final PracticeCell cell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = cell.metadata['difficulty'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Task',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (difficulty.isNotEmpty) ...[
                  const Spacer(),
                  Chip(
                    label: Text(difficulty),
                    labelStyle: theme.textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cell.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Work Cell ──

class _WorkCell extends StatelessWidget {
  const _WorkCell({
    required this.cell,
    required this.controller,
    required this.isActive,
  });

  final PracticeCell cell;
  final TextEditingController controller;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<PracticeState>();
    final isCompleted = cell.cellStatus == CellStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green
              : isActive
                  ? theme.colorScheme.outline
                  : theme.colorScheme.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cell header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.edit_note_outlined,
                  size: 14,
                  color: isCompleted
                      ? Colors.green
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Your answer',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCompleted
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (isActive && !isCompleted && !state.isBusy)
                  TextButton.icon(
                    onPressed: state.checkWork,
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('Check'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (state.isEvaluating && isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          // Text field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: TextField(
              controller: controller,
              enabled: isActive && !isCompleted,
              maxLines: null,
              minLines: 4,
              onChanged: (v) {
                if (isActive) {
                  context.read<PracticeState>().onWorkChanged(v);
                }
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: isCompleted
                    ? null
                    : 'Write your solution here...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feedback Cell wrapper ──

class _FeedbackCellWrapper extends StatelessWidget {
  const _FeedbackCellWrapper({required this.cell});

  final PracticeCell cell;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PracticeState>();
    return PracticeFeedbackCard(
      cell: cell,
      onAcceptSubtask: cell.action == PracticeAction.suggestSubtask &&
              cell.subtaskTopic != null
          ? () => state.acceptSubtask(cell.subtaskTopic!)
          : null,
      onReturnToParent: cell.metadata['action'] == 'bridge'
          ? state.closeWorkspace
          : null,
    );
  }
}
