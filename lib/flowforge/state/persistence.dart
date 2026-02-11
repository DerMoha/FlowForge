import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_log.dart';
import '../models/todo_item.dart';

class FlowForgeStorage {
  static const String stateKey = 'flowforge_state_v1';
  static const int maxSessionLogs = 420;

  static Future<Map<String, dynamic>?> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(stateKey);
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRaw(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(stateKey, jsonEncode(payload));
  }

  static List<SessionLog> decodeLogs(Object? rawLogs) {
    if (rawLogs is! List) {
      return <SessionLog>[];
    }

    final parsed = <SessionLog>[];
    for (final item in rawLogs) {
      if (item is Map) {
        try {
          parsed.add(SessionLog.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Ignore malformed entries and keep loading.
        }
      }
    }

    parsed.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return parsed.take(maxSessionLogs).toList();
  }

  static List<TodoItem> decodeTodos(Object? rawTodos) {
    if (rawTodos is! List) {
      return <TodoItem>[];
    }

    final parsed = <TodoItem>[];
    for (final item in rawTodos) {
      if (item is Map) {
        try {
          parsed.add(TodoItem.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Ignore malformed todo entries and keep loading.
        }
      }
    }

    parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return parsed.take(64).toList();
  }
}
