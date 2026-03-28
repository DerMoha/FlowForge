import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_core/shared_core.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Manages cross-app XP events via file-based event system.
///
/// Both FlowForge and AI Tutor read/write to a shared directory:
/// ~/Library/Application Support/StudyForge/events/
class XpEventService {
  static const _source = 'ai_tutor';

  /// Get the shared events directory.
  Future<Directory> _eventsDir() async {
    final appSupport = await getApplicationSupportDirectory();
    // Go up from app-specific to shared StudyForge directory
    final sharedDir = Directory(
      p.join(appSupport.parent.path, 'StudyForge', 'events'),
    );
    if (!sharedDir.existsSync()) {
      sharedDir.createSync(recursive: true);
    }
    return sharedDir;
  }

  /// Emit an XP event.
  Future<void> emitEvent({
    required String eventType,
    required int xpAmount,
    required int durationMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    final event = XpEvent(
      id: _uuid.v4(),
      source: _source,
      eventType: eventType,
      xpAmount: xpAmount,
      durationMinutes: durationMinutes,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    final dir = await _eventsDir();
    final file = File(p.join(dir.path, '${event.id}.json'));
    await file.writeAsString(jsonEncode(event.toJson()));
  }

  /// Consume unprocessed events from the other app.
  Future<List<XpEvent>> consumeEvents() async {
    final dir = await _eventsDir();
    if (!dir.existsSync()) return [];

    final events = <XpEvent>[];
    final files = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.json'),
        );

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final event = XpEvent.fromJson(json);

        // Only consume events from the other app
        if (event.source != _source) {
          events.add(event);
          await file.delete(); // Mark as consumed
        }
      } catch (_) {
        // Skip malformed events
      }
    }

    return events;
  }

  /// Get the shared user profile path.
  Future<File> _profileFile() async {
    final appSupport = await getApplicationSupportDirectory();
    final sharedDir = Directory(
      p.join(appSupport.parent.path, 'StudyForge'),
    );
    if (!sharedDir.existsSync()) {
      sharedDir.createSync(recursive: true);
    }
    return File(p.join(sharedDir.path, 'profile.json'));
  }

  /// Read the shared user profile.
  Future<Map<String, dynamic>?> readSharedProfile() async {
    final file = await _profileFile();
    if (!file.existsSync()) return null;
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Write/update the shared user profile.
  Future<void> writeSharedProfile(Map<String, dynamic> profile) async {
    final file = await _profileFile();
    await file.writeAsString(jsonEncode(profile));
  }
}
