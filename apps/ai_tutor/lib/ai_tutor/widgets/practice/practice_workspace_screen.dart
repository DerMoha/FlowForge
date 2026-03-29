import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../state/practice_state.dart';
import 'practice_breadcrumb.dart';
import 'practice_cell_widget.dart';

class PracticeWorkspaceScreen extends StatefulWidget {
  const PracticeWorkspaceScreen({super.key});

  @override
  State<PracticeWorkspaceScreen> createState() =>
      _PracticeWorkspaceScreenState();
}

class _PracticeWorkspaceScreenState extends State<PracticeWorkspaceScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PracticeState>();
    final theme = Theme.of(context);

    final session = state.activeSession;
    if (session == null) return const SizedBox.shrink();

    // Scroll to bottom when new cells arrive
    _scrollToBottom();

    return Column(
      children: [
        // Breadcrumb trail for nested sessions
        PracticeBreadcrumb(sessions: state.breadcrumbs),

        // App bar with topic and controls
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.topic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status indicator
              if (state.isGeneratingTask)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Generating task...'),
                    ],
                  ),
                ),
              if (state.isEvaluating)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Checking...'),
                    ],
                  ),
                ),
              // Session status badge
              _SessionStatusBadge(status: session.status),
              // Close button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _confirmClose(context, state),
                tooltip: 'Close workspace',
              ),
            ],
          ),
        ),

        // Error banner
        if (state.error != null)
          MaterialBanner(
            content: Text(state.error!),
            actions: [
              TextButton(
                onPressed: () {}, // errors clear on next action
                child: const Text('Dismiss'),
              ),
            ],
            backgroundColor: theme.colorScheme.errorContainer,
          ),

        // Cell list
        Expanded(
          child: state.cells.isEmpty && state.isGeneratingTask
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('The AI is preparing your task...'),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.cells.length,
                  itemBuilder: (context, index) {
                    final cell = state.cells[index];
                    final isLast = index == state.cells.length - 1;
                    return PracticeCellWidget(
                      key: ValueKey(cell.id),
                      cell: cell,
                      isLast: isLast,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClose(
      BuildContext context, PracticeState state) async {
    final session = state.activeSession;
    if (session == null) {
      state.closeWorkspace();
      return;
    }

    final isCompleted =
        session.status == PracticeSessionStatus.completed;
    if (isCompleted) {
      state.closeWorkspace();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close workspace?'),
        content: const Text(
            'Your progress is saved. You can resume this session later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (result == true) {
      state.closeWorkspace();
    }
  }
}

class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({required this.status});

  final PracticeSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    String label;

    switch (status) {
      case PracticeSessionStatus.completed:
        color = Colors.green;
        label = 'Complete';
      case PracticeSessionStatus.evaluating:
        color = Colors.orange;
        label = 'Checking';
      case PracticeSessionStatus.subtaskActive:
        color = theme.colorScheme.tertiary;
        label = 'Sub-task';
      case PracticeSessionStatus.awaitingTask:
        color = theme.colorScheme.onSurfaceVariant;
        label = 'Loading';
      case PracticeSessionStatus.inProgress:
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
