import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/gamification_state.dart';

/// Streak flame indicator with current streak count
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationState>(
      builder: (context, gamification, child) {
        final status = gamification.getStreakStatus();
        final currentStreak = status['current'] as int;
        final longestStreak = status['longest'] as int;
        final isAtRisk = status['isAtRisk'] as bool;
        final freezeTokens = status['freezeTokens'] as int;

        final theme = Theme.of(context);

        // Determine flame color based on streak length
        Color flameColor;
        if (currentStreak >= 30) {
          flameColor = Colors.red;
        } else if (currentStreak >= 14) {
          flameColor = Colors.orange;
        } else if (currentStreak >= 7) {
          flameColor = Colors.green;
        } else {
          flameColor = Colors.blue;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAtRisk
                  ? Colors.red.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: isAtRisk ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Flame icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          flameColor.withOpacity(0.3),
                          flameColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: flameColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$currentStreak Day${currentStreak != 1 ? 's' : ''}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isAtRisk ? Colors.red : null,
                              ),
                            ),
                            if (isAtRisk) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Streak',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isAtRisk)
                          Text(
                            'Complete a session to save!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Longest',
                    '$longestStreak',
                    Icons.emoji_events_rounded,
                  ),
                  _buildStatItem(
                    context,
                    'Freeze Tokens',
                    '$freezeTokens',
                    Icons.ac_unit_rounded,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Compact streak flame for app bar
class CompactStreakFlame extends StatelessWidget {
  const CompactStreakFlame({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationState>(
      builder: (context, gamification, child) {
        final status = gamification.getStreakStatus();
        final currentStreak = status['current'] as int;
        final isAtRisk = status['isAtRisk'] as bool;

        if (currentStreak == 0) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAtRisk
                ? Colors.red.withOpacity(0.2)
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: isAtRisk
                ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: isAtRisk
                    ? Colors.red
                    : theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '$currentStreak',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isAtRisk
                      ? Colors.red
                      : theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
