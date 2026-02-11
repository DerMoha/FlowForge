import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/gamification_state.dart';

/// Lifetime statistics summary card
class StatsSummary extends StatelessWidget {
  const StatsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationState>(
      builder: (context, gamification, child) {
        final stats = gamification.profile.lifetimeStats;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lifetime Stats',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                context,
                Icons.play_circle_rounded,
                'Total Sessions',
                '${stats.totalSessions}',
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.timer_rounded,
                'Total Minutes',
                '${stats.totalMinutes}',
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.check_circle_rounded,
                'Tasks Completed',
                '${stats.totalTasksCompleted}',
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.rocket_launch_rounded,
                'Deep Tasks',
                '${stats.totalDeepTasksCompleted}',
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.trending_up_rounded,
                'Longest Session',
                '${stats.longestSessionMinutes} min',
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.calendar_month_rounded,
                'Perfect Weeks',
                '${stats.perfectWeeks}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Compact stats grid for dashboard
class CompactStatsGrid extends StatelessWidget {
  const CompactStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationState>(
      builder: (context, gamification, child) {
        final stats = gamification.profile.lifetimeStats;
        final theme = Theme.of(context);

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                Icons.play_circle_rounded,
                '${stats.totalSessions}',
                'Sessions',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                Icons.timer_rounded,
                '${(stats.totalMinutes / 60).toStringAsFixed(1)}h',
                'Focused',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                Icons.check_circle_rounded,
                '${stats.totalTasksCompleted}',
                'Completed',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
