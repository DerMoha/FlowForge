import 'dart:math';

import 'package:flutter/material.dart';

import '../models/daily_session_activity.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final series = state.activitySeries;
    final maxSessions = series.fold<int>(
      0,
      (maxVal, item) => item.sessions > maxVal ? item.sessions : maxVal,
    );
    final weeks = <List<DailySessionActivity>>[];
    for (var index = 0; index < series.length; index += 7) {
      final end = min(index + 7, series.length);
      weeks.add(series.sublist(index, end));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Last 12 weeks: ${state.sessionsThisWeek} sessions this week (${state.minutesThisWeek} min).',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 1),
                child: Column(
                  children: const <Widget>[
                    _DayLabel(label: 'M'),
                    SizedBox(height: 12),
                    _DayLabel(label: 'W'),
                    SizedBox(height: 12),
                    _DayLabel(label: 'F'),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.generate(weeks.length, (weekIndex) {
                      final week = weeks[weekIndex];
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Column(
                          children: List<Widget>.generate(7, (dayIndex) {
                            if (dayIndex >= week.length) {
                              return const SizedBox(width: 14, height: 14);
                            }
                            final day = week[dayIndex];
                            final cellColor = _activityColorForDay(
                              day.sessions,
                              maxSessions,
                              scheme,
                            );
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Tooltip(
                                message:
                                    '${formatShortDate(day.day)} · ${day.sessions} '
                                    '${day.sessions == 1 ? 'session' : 'sessions'} · '
                                    '${day.minutes} min',
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              'Less',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            ...List<Widget>.generate(5, (index) {
              final sampleSessions = maxSessions == 0
                  ? index
                  : ((maxSessions * index) / 4).round();
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      _activityColorForDay(sampleSessions, maxSessions, scheme),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text(
              'More',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _activityColorForDay(
    int sessions,
    int maxSessions,
    ColorScheme scheme,
  ) {
    if (sessions <= 0 || maxSessions <= 0) {
      return scheme.surfaceContainerHighest;
    }
    final normalized = sessions / maxSessions;
    if (normalized >= 0.85) return scheme.primary;
    if (normalized >= 0.6) return scheme.primary.withValues(alpha: 0.85);
    if (normalized >= 0.35) return scheme.primary.withValues(alpha: 0.6);
    return scheme.primary.withValues(alpha: 0.35);
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
