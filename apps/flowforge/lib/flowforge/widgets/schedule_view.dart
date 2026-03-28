import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/schedule_state.dart';
import '../state/task_state.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final schedule = context.watch<ScheduleState>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Schedule'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => schedule.loadCalendarEvents(),
            tooltip: 'Aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: schedule.isLoading ? null : () => _runAutoSchedule(),
            tooltip: 'Auto-Schedule',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(scheme),
          if (schedule.isLoading)
            const LinearProgressIndicator()
          else if (schedule.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                schedule.error!,
                style: TextStyle(color: scheme.error),
              ),
            ),
          if (!schedule.isAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: scheme.errorContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded, color: scheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scheduling Service nicht erreichbar',
                          style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => schedule.checkAvailability(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: _buildTimeline(scheme, schedule)),
          if (schedule.scheduledBlocks.isNotEmpty) _buildPreviewBar(scheme, schedule),
        ],
      ),
    );
  }

  Widget _buildDaySelector(ColorScheme scheme) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday = _isSameDay(day, now);
          final weekday = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][day.weekday - 1];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: isToday
                      ? Border.all(color: scheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(ColorScheme scheme, ScheduleState schedule) {
    final events = schedule.eventsForDay(_selectedDay);
    final blocks = schedule.blocksForDay(_selectedDay);

    // Merge and sort all items by start time
    final items = <_TimelineItem>[];
    for (final e in events) {
      items.add(_TimelineItem(
        start: e.start,
        end: e.end,
        title: e.summary,
        subtitle: e.location,
        type: e.isBlocker ? _ItemType.blocker : _ItemType.event,
      ));
    }
    for (final b in blocks) {
      items.add(_TimelineItem(
        start: b.start,
        end: b.end,
        title: b.taskTitle,
        subtitle: null,
        type: _ItemType.scheduledTask,
      ));
    }
    items.sort((a, b) => a.start.compareTo(b.start));

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Keine Events an diesem Tag',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildTimelineCard(scheme, items[i]),
    );
  }

  Widget _buildTimelineCard(ColorScheme scheme, _TimelineItem item) {
    final Color color;
    final IconData icon;

    switch (item.type) {
      case _ItemType.event:
        color = scheme.primary;
        icon = Icons.event_rounded;
      case _ItemType.blocker:
        color = scheme.tertiary;
        icon = Icons.directions_transit_rounded;
      case _ItemType.scheduledTask:
        color = scheme.secondary;
        icon = Icons.task_alt_rounded;
    }

    final timeStr =
        '${_formatTime(item.start)} – ${_formatTime(item.end)}';
    final duration = item.end.difference(item.start).inMinutes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              _formatTime(item.start),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 0,
              color: color.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle != null
                                ? '$timeStr · ${item.subtitle}'
                                : '$timeStr · ${duration}min',
                            style: TextStyle(
                              fontSize: 12,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBar(ColorScheme scheme, ScheduleState schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded, color: scheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${schedule.scheduledBlocks.length} Tasks geplant',
              style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              // Clear preview
              schedule.loadCalendarEvents();
            },
            child: const Text('Verwerfen'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () async {
              final success = await schedule.acceptSchedule();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Schedule in Kalender geschrieben!'
                        : 'Fehler beim Speichern'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Annehmen'),
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

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
