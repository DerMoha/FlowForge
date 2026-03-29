import 'package:flutter/material.dart';
import '../../models/practice.dart';

class PracticeBreadcrumb extends StatelessWidget {
  const PracticeBreadcrumb({super.key, required this.sessions});

  final List<PracticeSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.length <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < sessions.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    Text(
                      sessions[i].topic,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: i == sessions.length - 1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: i == sessions.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (sessions.length > 1) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('Depth ${sessions.length - 1}'),
              labelStyle: theme.textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
