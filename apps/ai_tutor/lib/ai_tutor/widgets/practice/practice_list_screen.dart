import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/practice.dart';
import '../../state/practice_state.dart';
import 'practice_start_dialog.dart';
import 'practice_workspace_screen.dart';

class PracticeListScreen extends StatelessWidget {
  const PracticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PracticeState>();

    // Show workspace if a session is active
    if (state.hasActiveSession) {
      return const PracticeWorkspaceScreen();
    }

    return Scaffold(
      body: _buildList(context, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Practice'),
      ),
    );
  }

  Widget _buildList(BuildContext context, PracticeState state) {
    final theme = Theme.of(context);

    if (state.allSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No practice sessions yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start a new session to practice a topic with AI guidance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showStartDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Start practicing'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Practice'),
          floating: true,
          snap: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showStartDialog(context),
              tooltip: 'New session',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: state.allSessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final session = state.allSessions[index];
              return _SessionCard(session: session);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showStartDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const PracticeStartDialog(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<PracticeState>();
    final isCompleted = session.status == PracticeSessionStatus.completed;
    final isAbandoned = session.status == PracticeSessionStatus.abandoned;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isAbandoned ? null : () => state.loadSession(session.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(session.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _statusIcon(session.status),
                  color: _statusColor(session.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.topic,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: isAbandoned
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(session.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _statusColor(session.status),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted && !isAbandoned) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(PracticeSessionStatus s) {
    switch (s) {
      case PracticeSessionStatus.completed:
        return Colors.green;
      case PracticeSessionStatus.abandoned:
        return Colors.red;
      case PracticeSessionStatus.inProgress:
      case PracticeSessionStatus.evaluating:
      case PracticeSessionStatus.subtaskActive:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(PracticeSessionStatus s) {
    switch (s) {
      case PracticeSessionStatus.completed:
        return Icons.check_circle;
      case PracticeSessionStatus.abandoned:
        return Icons.cancel_outlined;
      case PracticeSessionStatus.inProgress:
      case PracticeSessionStatus.evaluating:
      case PracticeSessionStatus.subtaskActive:
        return Icons.pending_outlined;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _statusLabel(PracticeSessionStatus s) {
    switch (s) {
      case PracticeSessionStatus.completed:
        return 'Completed';
      case PracticeSessionStatus.abandoned:
        return 'Abandoned';
      case PracticeSessionStatus.inProgress:
        return 'In progress';
      case PracticeSessionStatus.evaluating:
        return 'Checking...';
      case PracticeSessionStatus.subtaskActive:
        return 'Sub-task in progress';
      case PracticeSessionStatus.awaitingTask:
        return 'Loading task...';
      case PracticeSessionStatus.notStarted:
        return 'Not started';
    }
  }
}
