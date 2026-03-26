import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analytics/energy_predictor.dart';
import '../models/analytics_snapshot.dart';
import '../services/export_service.dart';
import '../state/analytics_state.dart';
import 'energy_flow_chart.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key, this.compact = false});

  final bool compact;

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
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
        await ExportService.instance.shareImage(
          imageBytes,
          ExportService.instance.formatWeeklySummaryText(summary),
        );
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
        final scheme = theme.colorScheme;
        final snapshots = analytics.snapshots.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final recent = _DashboardMetrics.fromAnalytics(
          analytics: analytics,
          snapshots: snapshots,
        );
        final summary = ExportService.instance.generateWeeklySummary(
          sessions: analytics.totalSessions,
          minutes: analytics.totalMinutes,
          tasksCompleted: analytics.totalTasksCompleted,
          streak: analytics.currentStreak,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SectionCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Insights that help you decide what to do next.',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    recent.nextStep,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _shareProgress(analytics),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded),
                              label: Text(
                                _isExporting ? 'Sharing...' : 'Share progress',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ResponsiveMetricGrid(
                          minTileWidth: widget.compact ? 180 : 210,
                          children: <Widget>[
                            _ActionMetricCard(
                              icon: Icons.bolt_rounded,
                              label: 'Focus minutes this week',
                              value: '${recent.weekMinutes}',
                              detail: recent.weekMinutesDetail,
                              accent: scheme.primary,
                            ),
                            _ActionMetricCard(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Current streak',
                              value: '${analytics.currentStreak} days',
                              detail: recent.streakDetail,
                              accent: scheme.tertiary,
                            ),
                            _ActionMetricCard(
                              icon: Icons.track_changes_rounded,
                              label: 'Completion rhythm',
                              value: recent.completionValue,
                              detail: recent.completionDetail,
                              accent: scheme.secondary,
                            ),
                            _ActionMetricCard(
                              icon: Icons.schedule_rounded,
                              label: 'Best next session',
                              value: recent.bestSessionLabel,
                              detail: recent.bestSessionDetail,
                              accent: scheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 6,
                          child: _buildProgressSection(
                            context,
                            analytics,
                            summary,
                            recent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildPatternsSection(
                            context,
                            analytics,
                            recent,
                          ),
                        ),
                      ],
                    )
                  else ...<Widget>[
                    _buildProgressSection(context, analytics, summary, recent),
                    const SizedBox(height: 16),
                    _buildPatternsSection(context, analytics, recent),
                  ],
                  const SizedBox(height: 16),
                  _buildPredictionSection(context, analytics, recent),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    AnalyticsState analytics,
    Map<String, dynamic> summary,
    _DashboardMetrics metrics,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeading(
            title: 'Progress snapshot',
            subtitle:
                'A quick read on volume, consistency, and shareable momentum.',
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _boundaryKey,
            child: _ShareableProgressCard(
              analytics: analytics,
              summary: summary,
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceStrip(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.flag_circle_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    metrics.progressCallout,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsSection(
    BuildContext context,
    AnalyticsState analytics,
    _DashboardMetrics metrics,
  ) {
    final theme = Theme.of(context);

    return _SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeading(
            title: 'Patterns',
            subtitle:
                'Spot when work feels easiest and where your routine slips.',
          ),
          const SizedBox(height: 16),
          _ResponsiveMetricGrid(
            minTileWidth: 160,
            children: <Widget>[
              _MiniInsightCard(
                title: 'Morning',
                value: metrics.morningEnergy,
                detail: 'Best for ${metrics.morningGuidance}',
              ),
              _MiniInsightCard(
                title: 'Afternoon',
                value: metrics.afternoonEnergy,
                detail: 'Best for ${metrics.afternoonGuidance}',
              ),
              _MiniInsightCard(
                title: 'Evening',
                value: metrics.eveningEnergy,
                detail: 'Best for ${metrics.eveningGuidance}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SurfaceStrip(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LabeledFact(label: 'Peak window', value: metrics.peakWindow),
                const SizedBox(height: 10),
                _LabeledFact(label: 'Lowest window', value: metrics.lowWindow),
                const SizedBox(height: 10),
                _LabeledFact(
                  label: 'Daily averages',
                  value:
                      '${metrics.averageSessions} sessions and ${metrics.averageMinutes} minutes over the last 7 days',
                ),
                if (analytics
                    .getPeakProductivityHours()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _LabeledFact(
                    label: 'Common start times',
                    value: analytics
                        .getPeakProductivityHours()
                        .map(_formatHour)
                        .join(', '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            padding: const EdgeInsets.all(16),
            colorOpacity: 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Energy flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: EnergyFlowChart(energyData: analytics.energyHistory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection(
    BuildContext context,
    AnalyticsState analytics,
    _DashboardMetrics metrics,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeading(
            title: 'Prediction and next steps',
            subtitle:
                'Turn pattern history into a practical plan for the next few hours.',
          ),
          const SizedBox(height: 16),
          _ResponsiveMetricGrid(
            minTileWidth: widget.compact ? 200 : 240,
            children: <Widget>[
              _ActionPlanCard(
                icon: Icons.lightbulb_rounded,
                title: 'Next hour outlook',
                value: metrics.nextHourPrediction,
                detail: metrics.nextHourDetail,
                accent: scheme.primary,
              ),
              _ActionPlanCard(
                icon: Icons.event_available_rounded,
                title: 'Suggested deep work window',
                value: metrics.bestSessionLabel,
                detail: metrics.bestSessionPlan,
                accent: scheme.secondary,
              ),
              _ActionPlanCard(
                icon: Icons.task_alt_rounded,
                title: 'Recommended next move',
                value: metrics.nextMoveTitle,
                detail: metrics.nextStep,
                accent: scheme.tertiary,
              ),
            ],
          ),
          if (analytics.energyHistory.isEmpty ||
              analytics.snapshots.isEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _SurfaceStrip(
              child: Text(
                'Predictions improve after a few days of focus sessions and energy check-ins.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardMetrics {
  const _DashboardMetrics({
    required this.weekMinutes,
    required this.weekMinutesDetail,
    required this.streakDetail,
    required this.completionValue,
    required this.completionDetail,
    required this.bestSessionLabel,
    required this.bestSessionDetail,
    required this.bestSessionPlan,
    required this.progressCallout,
    required this.nextStep,
    required this.nextMoveTitle,
    required this.nextHourPrediction,
    required this.nextHourDetail,
    required this.morningEnergy,
    required this.afternoonEnergy,
    required this.eveningEnergy,
    required this.morningGuidance,
    required this.afternoonGuidance,
    required this.eveningGuidance,
    required this.peakWindow,
    required this.lowWindow,
    required this.averageSessions,
    required this.averageMinutes,
  });

  final int weekMinutes;
  final String weekMinutesDetail;
  final String streakDetail;
  final String completionValue;
  final String completionDetail;
  final String bestSessionLabel;
  final String bestSessionDetail;
  final String bestSessionPlan;
  final String progressCallout;
  final String nextStep;
  final String nextMoveTitle;
  final String nextHourPrediction;
  final String nextHourDetail;
  final String morningEnergy;
  final String afternoonEnergy;
  final String eveningEnergy;
  final String morningGuidance;
  final String afternoonGuidance;
  final String eveningGuidance;
  final String peakWindow;
  final String lowWindow;
  final String averageSessions;
  final String averageMinutes;

  factory _DashboardMetrics.fromAnalytics({
    required AnalyticsState analytics,
    required List<AnalyticsSnapshot> snapshots,
  }) {
    final now = DateTime.now();
    final weekCutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final weekSnapshots = snapshots
        .where((snapshot) => !snapshot.date.isBefore(weekCutoff))
        .toList();
    final weekMinutes = weekSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.totalMinutes,
    );
    final weekSessions = weekSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.totalSessions,
    );
    final weekTasksDone = weekSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.tasksCompleted,
    );
    final weekTasksCreated = weekSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.tasksCreated,
    );

    final insights = EnergyPredictor.instance.analyzePatterns(
      analytics.energyHistory,
    );
    final recommendations = EnergyPredictor.instance.generateRecommendations(
      insights,
    );
    final nextHourPrediction = analytics.predictEnergyForTime(
      now.add(const Duration(hours: 1)),
    );
    final suggestedSession = EnergyPredictor.instance.suggestNextSession(
      historicalData: analytics.energyHistory,
      requiredEnergy: 70,
    );
    final averageSessions = analytics.getAverageDailySessions(7);
    final averageMinutes = analytics.getAverageDailyMinutes(7);
    final completionRate = weekTasksCreated == 0
        ? null
        : (weekTasksDone / weekTasksCreated * 100).round();

    final nextMoveTitle = nextHourPrediction == null
        ? 'Log a few more check-ins'
        : nextHourPrediction >= 70
        ? 'Use the next hour for deep work'
        : nextHourPrediction >= 55
        ? 'Choose steady progress'
        : 'Keep the next block light';

    final nextStep = recommendations.isNotEmpty
        ? recommendations.first
        : suggestedSession != null
        ? 'Your pattern suggests a stronger focus block around ${_formatDateTime(suggestedSession)}.'
        : 'Keep logging sessions and energy so the workspace can suggest better timing.';

    final progressCallout = weekMinutes == 0
        ? 'You have no tracked focus minutes in the last 7 days yet, so this view is ready for your first session.'
        : 'You logged $weekMinutes focused minutes across $weekSessions sessions this week. ${weekTasksDone > 0 ? 'That helped finish $weekTasksDone tasks.' : 'Keep the momentum going with one more short session today.'}';

    return _DashboardMetrics(
      weekMinutes: weekMinutes,
      weekMinutesDetail: weekMinutes == 0
          ? 'Start a session to build a weekly baseline.'
          : '$weekSessions sessions in the last 7 days',
      streakDetail: analytics.currentStreak == 0
          ? 'One session today starts a fresh streak.'
          : analytics.currentStreak == 1
          ? 'A second day locks in a routine.'
          : 'Protect it with at least one session today.',
      completionValue: completionRate == null ? '--' : '$completionRate%',
      completionDetail: completionRate == null
          ? 'No task creation data in the last 7 days.'
          : '$weekTasksDone done from $weekTasksCreated created this week',
      bestSessionLabel: suggestedSession == null
          ? 'No clear slot yet'
          : _formatDateTime(suggestedSession),
      bestSessionDetail: suggestedSession == null
          ? 'More energy history will improve timing suggestions.'
          : 'Predicted strongest window in the next 12 hours',
      bestSessionPlan: suggestedSession == null
          ? 'Keep checking in after sessions so the predictor can learn your rhythm.'
          : 'If possible, protect ${_formatDateTime(suggestedSession)} for high-energy work.',
      progressCallout: progressCallout,
      nextStep: nextStep,
      nextMoveTitle: nextMoveTitle,
      nextHourPrediction: nextHourPrediction == null
          ? '--'
          : '$nextHourPrediction / 100',
      nextHourDetail: nextHourPrediction == null
          ? 'Not enough energy history for a reliable one-hour forecast.'
          : nextHourPrediction >= 70
          ? 'Good window for complex work and longer focus sessions.'
          : nextHourPrediction >= 55
          ? 'Solid for admin, planning, or medium-effort tasks.'
          : 'Better for cleanup, review, or a short reset break.',
      morningEnergy: _energyLabel(insights.morningEnergy),
      afternoonEnergy: _energyLabel(insights.afternoonEnergy),
      eveningEnergy: _energyLabel(insights.eveningEnergy),
      morningGuidance: _guidanceForEnergy(insights.morningEnergy),
      afternoonGuidance: _guidanceForEnergy(insights.afternoonEnergy),
      eveningGuidance: _guidanceForEnergy(insights.eveningEnergy),
      peakWindow:
          '${_formatHour(insights.peakHour)} at about ${insights.peakEnergy}/100 energy',
      lowWindow:
          '${_formatHour(insights.lowHour)} at about ${insights.lowEnergy}/100 energy',
      averageSessions: averageSessions.toStringAsFixed(1),
      averageMinutes: averageMinutes.toStringAsFixed(0),
    );
  }

  static String _guidanceForEnergy(int value) {
    if (value >= 70) return 'deep work';
    if (value >= 55) return 'planned progress';
    return 'light tasks';
  }

  static String _energyLabel(int value) {
    if (value <= 0) return '--';
    return '$value / 100';
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
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'FlowForge progress',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A calm snapshot of recent focus momentum.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ResponsiveMetricGrid(
            minTileWidth: 140,
            children: <Widget>[
              _SnapshotMetricCard(
                icon: Icons.play_circle_rounded,
                label: 'Sessions',
                value: '${analytics.totalSessions}',
              ),
              _SnapshotMetricCard(
                icon: Icons.timer_rounded,
                label: 'Hours',
                value: '${summary['hours']}',
              ),
              _SnapshotMetricCard(
                icon: Icons.check_circle_rounded,
                label: 'Tasks done',
                value: '${analytics.totalTasksCompleted}',
              ),
              _SnapshotMetricCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${analytics.currentStreak}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ExportService.instance.formatWeeklySummaryText(summary),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({
    required this.children,
    required this.minTileWidth,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = (width / minTileWidth).floor().clamp(1, 4);
        final spacing = 12.0;
        final tileWidth = count == 1
            ? width
            : (width - ((count - 1) * spacing)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: tileWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ActionMetricCard extends StatelessWidget {
  const _ActionMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      padding: const EdgeInsets.all(16),
      colorOpacity: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPlanCard extends StatelessWidget {
  const _ActionPlanCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      padding: const EdgeInsets.all(16),
      colorOpacity: 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      padding: const EdgeInsets.all(16),
      colorOpacity: 0.58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetricCard extends StatelessWidget {
  const _SnapshotMetricCard({
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledFact extends StatelessWidget {
  const _LabeledFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _SurfaceStrip extends StatelessWidget {
  const _SurfaceStrip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding,
    this.colorOpacity = 0.78,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double colorOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(
          alpha: isDark ? colorOpacity : colorOpacity + 0.1,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: child,
    );
  }
}

String _formatHour(int hour) {
  final normalizedHour = hour % 24;
  final period = normalizedHour >= 12 ? 'PM' : 'AM';
  final displayHour = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12;
  return '$displayHour $period';
}

String _formatDateTime(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final dayLabel = target == today
      ? 'Today'
      : target == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : '${value.month}/${value.day}';
  final normalizedHour = value.hour % 24;
  final period = normalizedHour >= 12 ? 'PM' : 'AM';
  final displayHour = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$dayLabel, $displayHour:$minute $period';
}
