import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/todo_item.dart';
import '../models/task_energy_requirement.dart';
import '../models/calendar_event.dart';
import '../models/scheduled_block.dart';

class SchedulingApiService {
  SchedulingApiService._();
  static final instance = SchedulingApiService._();

  // Default to localhost; override via configure() for production
  String _baseUrl = 'http://localhost:3001';

  void configure({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  String get baseUrl => _baseUrl;

  /// Sync tasks to the scheduling service
  Future<bool> syncTasks(List<TodoItem> todos) async {
    try {
      final tasks = todos.map((t) {
        return <String, dynamic>{
          'id': t.id,
          'title': t.title,
          'isDone': t.isDone,
          'estimateMinutes': t.estimateMinutes,
          'energyRequirement': t.energyRequirement.storageValue,
          'priority': t.priority,
          'deadline': t.deadline?.toIso8601String(),
          'projectId': t.projectId,
          'tags': t.tags,
          'blockedBy': t.blockedBy,
          'scheduledStart': t.scheduledStart?.toIso8601String(),
          'scheduledCalendarUid': t.scheduledCalendarUid,
        };
      }).toList();

      final res = await http.post(
        Uri.parse('$_baseUrl/api/tasks/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': tasks}),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('SchedulingAPI syncTasks error: $e');
      return false;
    }
  }

  /// Fetch calendar events from Baikal (via scheduling service proxy)
  Future<List<CalendarEvent>> fetchCalendarEvents({
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final params = <String, String>{};
      if (start != null) params['start'] = start.toIso8601String();
      if (end != null) params['end'] = end.toIso8601String();

      final uri = Uri.parse('$_baseUrl/api/calendar/events')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final res = await http.get(uri);
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final events = (data['events'] as List<dynamic>)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();

      return events;
    } catch (e) {
      debugPrint('SchedulingAPI fetchCalendarEvents error: $e');
      return [];
    }
  }

  /// Run the auto-scheduler and get a preview
  Future<ScheduleResult?> runSchedule() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/schedule/run'),
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ScheduleResult.fromJson(data);
    } catch (e) {
      debugPrint('SchedulingAPI runSchedule error: $e');
      return null;
    }
  }

  /// Accept the current schedule preview (writes to Baikal)
  Future<bool> acceptSchedule() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/schedule/accept'),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('SchedulingAPI acceptSchedule error: $e');
      return false;
    }
  }

  /// Push energy profile to the scheduling service
  Future<bool> pushEnergyProfile(Map<int, double> hourlyEnergy) async {
    try {
      final hourly = <String, dynamic>{};
      hourlyEnergy.forEach((k, v) => hourly[k.toString()] = v);

      final res = await http.put(
        Uri.parse('$_baseUrl/api/energy-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hourly': hourly}),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('SchedulingAPI pushEnergyProfile error: $e');
      return false;
    }
  }

  /// Check if the scheduling service is reachable
  Future<bool> isAvailable() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ScheduleResult {
  const ScheduleResult({
    required this.scheduled,
    required this.unschedulable,
  });

  final List<ScheduledBlock> scheduled;
  final List<UnschedulableTask> unschedulable;

  factory ScheduleResult.fromJson(Map<String, dynamic> json) {
    return ScheduleResult(
      scheduled: (json['scheduled'] as List<dynamic>)
          .map((e) => ScheduledBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      unschedulable: (json['unschedulable'] as List<dynamic>)
          .map((e) => UnschedulableTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
