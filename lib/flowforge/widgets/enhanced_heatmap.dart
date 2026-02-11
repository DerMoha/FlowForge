import 'package:flutter/material.dart';
import '../models/daily_session_activity.dart';

enum HeatmapMetric {
  sessions,
  minutes,
  intensity,
}

/// Enhanced activity heatmap with 3D effects and interactions
class EnhancedActivityHeatmap extends StatefulWidget {
  const EnhancedActivityHeatmap({
    super.key,
    required this.activities,
    this.metric = HeatmapMetric.sessions,
    this.cellSize = 12,
    this.cellSpacing = 4,
  });

  final List<DailySessionActivity> activities;
  final HeatmapMetric metric;
  final double cellSize;
  final double cellSpacing;

  @override
  State<EnhancedActivityHeatmap> createState() => _EnhancedActivityHeatmapState();
}

class _EnhancedActivityHeatmapState extends State<EnhancedActivityHeatmap> {
  DailySessionActivity? _hoveredActivity;
  HeatmapMetric _currentMetric = HeatmapMetric.sessions;

  @override
  void initState() {
    super.initState();
    _currentMetric = widget.metric;
  }

  int _getMetricValue(DailySessionActivity activity) {
    switch (_currentMetric) {
      case HeatmapMetric.sessions:
        return activity.sessions;
      case HeatmapMetric.minutes:
        return activity.minutes;
      case HeatmapMetric.intensity:
        return activity.sessions > 0 ? (activity.minutes / activity.sessions).round() : 0;
    }
  }

  Color _getColorForValue(int value, int maxValue) {
    if (value == 0) {
      return Colors.grey.withOpacity(0.1);
    }

    final intensity = (value / maxValue).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    // Create gradient from primary to secondary based on intensity
    return Color.lerp(
      theme.colorScheme.primary.withOpacity(0.3),
      theme.colorScheme.secondary,
      intensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate max value for scaling
    final maxValue = widget.activities.fold<int>(
      0,
      (max, activity) {
        final value = _getMetricValue(activity);
        return value > max ? value : max;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric selector
        Wrap(
          spacing: 8,
          children: [
            _MetricChip(
              label: 'Sessions',
              isSelected: _currentMetric == HeatmapMetric.sessions,
              onTap: () => setState(() => _currentMetric = HeatmapMetric.sessions),
            ),
            _MetricChip(
              label: 'Minutes',
              isSelected: _currentMetric == HeatmapMetric.minutes,
              onTap: () => setState(() => _currentMetric = HeatmapMetric.minutes),
            ),
            _MetricChip(
              label: 'Intensity',
              isSelected: _currentMetric == HeatmapMetric.intensity,
              onTap: () => setState(() => _currentMetric = HeatmapMetric.intensity),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Heatmap grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildWeekRows(maxValue),
          ),
        ),

        // Tooltip
        if (_hoveredActivity != null) ...[
          const SizedBox(height: 12),
          _HeatmapTooltip(
            activity: _hoveredActivity!,
            metric: _currentMetric,
          ),
        ],

        const SizedBox(height: 16),

        // Legend
        Row(
          children: [
            Text(
              'Less',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 5; i++) ...[
              Container(
                width: widget.cellSize,
                height: widget.cellSize,
                decoration: BoxDecoration(
                  color: _getColorForValue(
                    (maxValue * (i + 1) / 5).round(),
                    maxValue,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
            ],
            const SizedBox(width: 8),
            Text(
              'More',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildWeekRows(int maxValue) {
    final weeks = <List<DailySessionActivity>>[];
    var currentWeek = <DailySessionActivity>[];

    for (final activity in widget.activities) {
      currentWeek.add(activity);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks.map((week) => _buildWeekRow(week, maxValue)).toList();
  }

  Widget _buildWeekRow(List<DailySessionActivity> week, int maxValue) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.cellSpacing),
      child: Row(
        children: week.map((activity) {
          final value = _getMetricValue(activity);
          final color = _getColorForValue(value, maxValue);

          return Padding(
            padding: EdgeInsets.only(right: widget.cellSpacing),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredActivity = activity),
              onExit: (_) => setState(() => _hoveredActivity = null),
              child: _HeatmapCell(
                value: value,
                color: color,
                size: widget.cellSize,
                isHovered: _hoveredActivity?.day == activity.day,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.value,
    required this.color,
    required this.size,
    required this.isHovered,
  });

  final int value;
  final Color color;
  final double size;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: isHovered
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        boxShadow: value > 0
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: isHovered ? 4 : 2,
                  offset: Offset(0, isHovered ? 2 : 1),
                ),
              ]
            : null,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _HeatmapTooltip extends StatelessWidget {
  const _HeatmapTooltip({
    required this.activity,
    required this.metric,
  });

  final DailySessionActivity activity;
  final HeatmapMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String metricText;
    switch (metric) {
      case HeatmapMetric.sessions:
        metricText = '${activity.sessions} session${activity.sessions != 1 ? 's' : ''}';
        break;
      case HeatmapMetric.minutes:
        metricText = '${activity.minutes} minutes';
        break;
      case HeatmapMetric.intensity:
        final avg = activity.sessions > 0
            ? (activity.minutes / activity.sessions).round()
            : 0;
        metricText = '$avg min/session';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(activity.day),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metricText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Compact year-in-review visualization
class YearInReview extends StatefulWidget {
  const YearInReview({
    super.key,
    required this.activities,
  });

  final List<DailySessionActivity> activities;

  @override
  State<YearInReview> createState() => _YearInReviewState();
}

class _YearInReviewState extends State<YearInReview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSessions = widget.activities.fold<int>(
      0,
      (sum, activity) => sum + activity.sessions,
    );
    final totalMinutes = widget.activities.fold<int>(
      0,
      (sum, activity) => sum + activity.minutes,
    );
    final activeDays = widget.activities.where((a) => a.sessions > 0).length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              'Year in Review',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatCard(
              context,
              Icons.play_circle_rounded,
              'Total Sessions',
              (totalSessions * _controller.value).round(),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              Icons.timer_rounded,
              'Total Minutes',
              (totalMinutes * _controller.value).round(),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              Icons.calendar_today_rounded,
              'Active Days',
              (activeDays * _controller.value).round(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    int value,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
