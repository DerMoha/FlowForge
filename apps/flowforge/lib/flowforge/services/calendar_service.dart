import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_item.dart';

class CalendarService {
  CalendarService._();
  static final instance = CalendarService._();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  String? _defaultCalendarId;
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return false;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data!.isNotEmpty) {
        // Find default or first writable calendar
        final calendars = calendarsResult.data!;
        final defaultCalendar = calendars.firstWhere(
          (c) => c.isDefault ?? false,
          orElse: () => calendars.firstWhere(
            (c) => c.isReadOnly == false,
            orElse: () => calendars.first,
          ),
        );
        _defaultCalendarId = defaultCalendar.id;
        _initialized = true;
        return true;
      }
    } catch (e) {
      debugPrint('Calendar init error: $e');
    }
    return false;
  }

  Future<String?> syncTaskToCalendar(TodoItem task) async {
    if (task.deadline == null) return null;

    final hasAccess = await initialize();
    if (!hasAccess || _defaultCalendarId == null) return null;

    try {
      final deadline = task.deadline!;
      // Assume tasks with deadlines take the estimated minutes at the deadline time
      final endTime = deadline.add(Duration(minutes: task.estimateMinutes));

      final eventToCreate = Event(
        _defaultCalendarId,
        title: task.title,
        status: task.status.name == 'completed'
            ? EventStatus.Confirmed
            : EventStatus.Tentative,
        start: tz.TZDateTime.from(deadline, tz.local),
        end: tz.TZDateTime.from(endTime, tz.local),
      );

      // If the task previously had an event ID, try to update it
      // Note: we'd need to extend TodoItem to store eventId if we wanted exact updates
      // Instead, we just create new events for simplicity if this is a first-time sync

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(
        eventToCreate,
      );
      if (result?.isSuccess == true) {
        return result?.data;
      }
    } catch (e) {
      debugPrint('Sync task to calendar error: $e');
    }
    return null;
  }
}
