import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/energy_state.dart';
import '../state/schedule_state.dart';
import '../state/task_state.dart';
import 'flow_ui.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleState>().loadCalendarEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleState>();
    final energy = context.watch<EnergyState>().energy;

    return FlowPageScaffold(
      energy: energy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScheduleHeader(
            schedule: schedule,
            onRefresh: () => schedule.loadCalendarEvents(),
            onAutoSchedule: schedule.isLoading ? null : _runAutoSchedule,
          ),
          const SizedBox(height: 14),
          _buildDaySelector(schedule),
          if (schedule.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (schedule.error != null) ...[
            const SizedBox(height: 12),
            FlowScopeBanner(
              icon: Icons.warning_amber_rounded,
              title: 'Schedule sync needs attention',
              message: schedule.error!,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
          if (!schedule.isAvailable) ...[
            const SizedBox(height: 12),
            FlowScopeBanner(
              icon: Icons.cloud_off_rounded,
              title: 'Scheduling service unavailable',
              message:
                  'Start the scheduler service to preview calendar-aware task blocks.',
              color: Theme.of(context).colorScheme.error,
              action: TextButton(
                onPressed: () => schedule.checkAvailability(),
                child: const Text('Retry'),
              ),
            ),
          ],
          if (schedule.unschedulable.isNotEmpty) ...[
            const SizedBox(height: 12),
            FlowScopeBanner(
              icon: Icons.event_busy_rounded,
              title:
                  '${schedule.unschedulable.length} task${schedule.unschedulable.length == 1 ? '' : 's'} need manual planning',
              message:
                  'There was not enough open calendar space for every task.',
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
          const SizedBox(height: 14),
          Expanded(child: _buildTimeline(schedule)),
          if (schedule.scheduledBlocks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildPreviewBar(schedule),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(ScheduleState schedule) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day + i),
    );

    return FlowSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      radius: FlowUiTokens.radiusLg,
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final day = days[index];
            final isSelected = _isSameDay(day, _selectedDay);
            final isToday = _isSameDay(day, now);
            final count =
                schedule.eventsForDay(day).length +
                schedule.blocksForDay(day).length;

            return _DayChip(
              day: day,
              count: count,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => setState(() => _selectedDay = day),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeline(ScheduleState schedule) {
    final items = _timelineItems(schedule)
      ..sort((a, b) => a.start.compareTo(b.start));

    if (items.isEmpty) {
      return Center(
        child: FlowEmptyState(
          icon: Icons.event_available_rounded,
          title: 'No events on this day',
          message:
              'Your calendar is clear. Use auto-schedule to turn open space into focus blocks.',
          action: FilledButton.icon(
            onPressed: schedule.isLoading ? null : _runAutoSchedule,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: const Text('Auto-schedule'),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _TimelineCard(item: items[index]),
    );
  }

  List<_TimelineItem> _timelineItems(ScheduleState schedule) {
    final items = <_TimelineItem>[];

    for (final event in schedule.eventsForDay(_selectedDay)) {
      items.add(
        _TimelineItem(
          start: event.start,
          end: event.end,
          title: event.summary,
          subtitle: event.location,
          type: event.isBlocker ? _ItemType.blocker : _ItemType.event,
        ),
      );
    }

    for (final block in schedule.blocksForDay(_selectedDay)) {
      items.add(
        _TimelineItem(
          start: block.start,
          end: block.end,
          title: block.taskTitle,
          type: _ItemType.scheduledTask,
        ),
      );
    }

    return items;
  }

  Widget _buildPreviewBar(ScheduleState schedule) {
    final count = schedule.scheduledBlocks.length;

    return FlowSurfaceCard(
      radius: FlowUiTokens.radiusLg,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FlowMetaChip(
            icon: Icons.auto_fix_high_rounded,
            label: '$count proposed task block${count == 1 ? '' : 's'}',
            filled: true,
          ),
          TextButton(
            onPressed: schedule.loadCalendarEvents,
            child: const Text('Discard'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final success = await schedule.acceptSchedule();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Schedule saved to your calendar.'
                        : 'Could not save schedule.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAutoSchedule() async {
    final schedule = context.read<ScheduleState>();
    final tasks = context.read<TaskState>();
    await schedule.autoSchedule(tasks.todos);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.schedule,
    required this.onRefresh,
    required this.onAutoSchedule,
  });

  final ScheduleState schedule;
  final VoidCallback onRefresh;
  final VoidCallback? onAutoSchedule;

  @override
  Widget build(BuildContext context) {
    final eventCount = schedule.calendarEvents.length;
    final previewCount = schedule.scheduledBlocks.length;

    return FlowPageHeader(
      icon: Icons.calendar_month_rounded,
      eyebrow: 'Calendar-aware planning',
      title: 'Schedule',
      subtitle:
          'Blend existing calendar events with energy-aware task blocks before committing them.',
      badges: [
        FlowStatPill(
          icon: Icons.event_note_rounded,
          label: 'events',
          value: '$eventCount',
        ),
        FlowStatPill(
          icon: Icons.task_alt_rounded,
          label: 'preview',
          value: '$previewCount',
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
      actions: [
        IconButton.filledTonal(
          onPressed: schedule.isLoading ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh calendar',
        ),
        FilledButton.icon(
          onPressed: onAutoSchedule,
          icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
          label: const Text('Auto-schedule'),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekday = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][day.weekday - 1];
    final accent = isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer.withValues(alpha: 0.82)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(FlowUiTokens.radiusMd),
            border: Border.all(
              color: isToday || isSelected
                  ? scheme.primary.withValues(alpha: isSelected ? 0.44 : 0.7)
                  : scheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isSelected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: count > 0 ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = switch (item.type) {
      _ItemType.event => scheme.primary,
      _ItemType.blocker => scheme.tertiary,
      _ItemType.scheduledTask => scheme.secondary,
    };
    final icon = switch (item.type) {
      _ItemType.event => Icons.event_rounded,
      _ItemType.blocker => Icons.directions_transit_rounded,
      _ItemType.scheduledTask => Icons.task_alt_rounded,
    };
    final duration = item.end.difference(item.start).inMinutes;
    final subtitle = item.subtitle != null && item.subtitle!.trim().isNotEmpty
        ? '${_formatTime(item.start)}-${_formatTime(item.end)} · ${item.subtitle}'
        : '${_formatTime(item.start)}-${_formatTime(item.end)} · ${duration}min';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            _formatTime(item.start),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          width: 3,
          height: 74,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.34),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FlowSurfaceCard(
            radius: FlowUiTokens.radiusMd,
            padding: const EdgeInsets.all(14),
            tint: accent,
            opacity: 0.08,
            borderOpacity: 0.2,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

enum _ItemType { event, blocker, scheduledTask }

class _TimelineItem {
  const _TimelineItem({
    required this.start,
    required this.end,
    required this.title,
    required this.type,
    this.subtitle,
  });

  final DateTime start;
  final DateTime end;
  final String title;
  final String? subtitle;
  final _ItemType type;
}
