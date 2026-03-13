import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/analytics_state.dart';

import '../analytics/energy_predictor.dart';
import '../services/export_service.dart';
import 'energy_flow_chart.dart';
import 'glass_card.dart';

/// Analytics dashboard with tabs for different views
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Insights'),
            Tab(text: 'Predictions'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _OverviewTab(),
              _TrendsTab(),
              _InsightsTab(),
              _PredictionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareProgress(AnalyticsState analytics) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final summary = ExportService.instance.generateWeeklySummary(
        sessions: analytics.totalSessions,
        minutes: analytics.totalMinutes,
        tasksCompleted: analytics.totalTasksCompleted,
        streak: analytics.currentStreak,
      );
      final imageBytes = await ExportService.instance.captureWidget(
        _boundaryKey,
      );
      if (imageBytes != null && mounted) {
        final summaryText = ExportService.instance.formatWeeklySummaryText(
          summary,
        );

        await ExportService.instance.shareImage(imageBytes, summaryText);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sharing image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsState>(
      builder: (context, analytics, child) {
        final theme = Theme.of(context);
        final summary = ExportService.instance.generateWeeklySummary(
          sessions: analytics.totalSessions,
          minutes: analytics.totalMinutes,
          tasksCompleted: analytics.totalTasksCompleted,
          streak: analytics.currentStreak,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Progress',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share a clean snapshot of your momentum and energy history.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _shareProgress(analytics),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(_isExporting ? 'Sharing...' : 'Share'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _boundaryKey,
                child: _ShareableProgressCard(
                  analytics: analytics,
                  summary: summary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareableProgressCard extends StatelessWidget {
  const _ShareableProgressCard({
    required this.analytics,
    required this.summary,
  });

  final AnalyticsState analytics;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FlowForge Progress',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A quick snapshot of your recent focus momentum.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.play_circle_rounded,
                  label: 'Total Sessions',
                  value: '${analytics.totalSessions}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.timer_rounded,
                  label: 'Total Hours',
                  value: '${summary['hours']}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Tasks Done',
                  value: '${analytics.totalTasksCompleted}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Current Streak',
                  value: '${analytics.currentStreak}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Energy Flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                EnergyFlowChart(energyData: analytics.energyHistory),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ExportService.instance.formatWeeklySummaryText(summary),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsState>(
      builder: (context, analytics, child) {
        final theme = Theme.of(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time range selector
              Wrap(
                spacing: 8,
                children: [
                  _buildRangeChip(context, '7 Days', true),
                  _buildRangeChip(context, '30 Days', false),
                  _buildRangeChip(context, '90 Days', false),
                ],
              ),
              const SizedBox(height: 24),

              // Average metrics
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Averages',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrendItem(
                      context,
                      'Sessions per day',
                      analytics.getAverageDailySessions(7).toStringAsFixed(1),
                      Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTrendItem(
                      context,
                      'Minutes per day',
                      analytics.getAverageDailyMinutes(7).toStringAsFixed(0),
                      Icons.timer_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Peak times
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peak Productivity Hours',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...analytics.getPeakProductivityHours().map((hour) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wb_sunny_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$hour:00',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRangeChip(BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {},
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildTrendItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsState>(
      builder: (context, analytics, child) {
        final insights = EnergyPredictor.instance.analyzePatterns(
          analytics.energyHistory,
        );
        final recommendations = EnergyPredictor.instance
            .generateRecommendations(insights);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommendations
              ...recommendations.map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightCard(insight: rec),
                );
              }),
              const SizedBox(height: 24),

              // Pattern analysis
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Patterns',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPatternItem(
                      context,
                      'Peak Energy',
                      '${insights.peakHour}:00 (${insights.peakEnergy})',
                      Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildPatternItem(
                      context,
                      'Consistency',
                      '${(insights.consistency * 100).toInt()}%',
                      Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PredictionsTab extends StatelessWidget {
  const _PredictionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsState>(
      builder: (context, analytics, child) {
        final now = DateTime.now();
        final prediction = analytics.predictEnergyForTime(
          now.add(const Duration(hours: 1)),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Predicted Energy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prediction != null ? '$prediction' : '--',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'in 1 hour',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final String insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(insight, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
