import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';
import '../models/scheduled_block.dart';
import '../models/todo_item.dart';
import '../services/scheduling_api_service.dart';

class ScheduleState extends ChangeNotifier {
  final SchedulingApiService _api = SchedulingApiService.instance;

  List<CalendarEvent> _calendarEvents = [];
  List<ScheduledBlock> _scheduledBlocks = [];
  List<UnschedulableTask> _unschedulable = [];
  bool _isLoading = false;
  bool _isAvailable = false;
  String? _error;

  List<CalendarEvent> get calendarEvents => _calendarEvents;
  List<ScheduledBlock> get scheduledBlocks => _scheduledBlocks;
  List<UnschedulableTask> get unschedulable => _unschedulable;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String? get error => _error;

  /// Check if scheduling service is reachable
  Future<void> checkAvailability() async {
    _isAvailable = await _api.isAvailable();
    notifyListeners();
  }

  /// Fetch calendar events for display
  Future<void> loadCalendarEvents({DateTime? start, DateTime? end}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _calendarEvents = await _api.fetchCalendarEvents(
        start: start ?? DateTime.now(),
        end: end ?? DateTime.now().add(const Duration(days: 7)),
      );
    } catch (e) {
      _error = 'Calendar could not be loaded.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sync tasks and run auto-scheduler
  Future<void> autoSchedule(List<TodoItem> tasks) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Sync tasks
      final synced = await _api.syncTasks(tasks);
      if (!synced) {
        _error = 'Tasks could not be synced.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Run scheduler
      final result = await _api.runSchedule();
      if (result == null) {
        _error = 'Scheduling failed.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _scheduledBlocks = result.scheduled;
      _unschedulable = result.unschedulable;
    } catch (e) {
      _error = 'Scheduling error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Accept the schedule preview (writes to calendar)
  Future<bool> acceptSchedule() async {
    final success = await _api.acceptSchedule();
    if (success) {
      _scheduledBlocks = [];
      _unschedulable = [];
      await loadCalendarEvents();
    }
    return success;
  }

  /// Get events for a specific day
  List<CalendarEvent> eventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _calendarEvents
        .where((e) => e.start.isBefore(dayEnd) && e.end.isAfter(dayStart))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Get scheduled blocks for a specific day
  List<ScheduledBlock> blocksForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _scheduledBlocks
        .where((b) => b.start.isBefore(dayEnd) && b.end.isAfter(dayStart))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }
}
