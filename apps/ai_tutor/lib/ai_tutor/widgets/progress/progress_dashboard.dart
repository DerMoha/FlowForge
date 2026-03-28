import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../../state/progress_state.dart';

class ProgressDashboard extends StatelessWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressState>();
    final theme = Theme.of(context);

    if (progress.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: AppTypography.heading(context)),
                  const SizedBox(height: 24),

                  // Level & XP card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Level circle
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: progress.levelProgress,
                                  strokeWidth: 6,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${progress.level}',
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(progress.title,
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${progress.totalXp} XP total',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${XpService.xpToNextLevel(progress.totalXp)} XP to next level',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Study time stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Today',
                          value: '${progress.todayStudyMinutes}',
                          unit: 'min',
                          icon: Icons.today,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'This Week',
                          value: '${progress.weekStudyMinutes}',
                          unit: 'min',
                          icon: Icons.date_range,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Total',
                          value: '${progress.totalStudyMinutes}',
                          unit: 'min',
                          icon: Icons.timer,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Sessions',
                          value: '${progress.sessions.length}',
                          unit: '',
                          icon: Icons.event_note,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Topic mastery section
          if (progress.masteries.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text('Topic Mastery',
                    style: theme.textTheme.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList.builder(
                itemCount: progress.masteries.length,
                itemBuilder: (context, index) {
                  final mastery = progress.masteries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mastery.topic,
                                    style: theme.textTheme.titleSmall),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: mastery.confidenceScore / 100,
                                  borderRadius: BorderRadius.circular(4),
                                  backgroundColor: theme.colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${mastery.confidenceScore.round()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Recent sessions
          if (progress.sessions.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text('Recent Sessions',
                    style: theme.textTheme.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList.builder(
                itemCount: progress.sessions.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final session = progress.sessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        session.targetType.name == 'notebook'
                            ? Icons.book
                            : Icons.picture_as_pdf,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text('${session.durationMinutes} min session'),
                      subtitle: Text(
                        _formatDate(session.startedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (session.inkStrokeCount > 0) ...[
                            Icon(Icons.edit, size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text('${session.inkStrokeCount}',
                                style: theme.textTheme.bodySmall),
                            const SizedBox(width: 8),
                          ],
                          if (session.aiInteractionCount > 0) ...[
                            Icon(Icons.smart_toy, size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text('${session.aiInteractionCount}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Empty state
          if (progress.sessions.isEmpty && progress.masteries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('No progress yet',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Start studying to track your progress.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.theme,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}
