import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FocusNotificationService {
  FocusNotificationService._();

  static final FocusNotificationService instance = FocusNotificationService._();

  static const String _channelId = 'focus_session_channel';
  static const String _channelName = 'Focus Sessions';
  static const String _channelDescription =
      'Live updates for active focus sessions.';
  static const int _activeSessionNotificationId = 4100;
  static const int _sessionCompleteNotificationId = 4101;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    try {
      await _notifications.initialize(settings: initializationSettings);
      _initialized = true;
      await _requestPermissions();
    } catch (_) {
      // Keep notification support best-effort to avoid hard failures.
    }
  }

  Future<void> _requestPermissions() async {
    if (!_initialized || kIsWeb) {
      return;
    }

    try {
      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return;
      }

      if (Platform.isIOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      if (Platform.isMacOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // Permission prompts are optional; ignore platform/plugin failures.
    }
  }

  Future<void> showActiveSession({
    required int remainingSeconds,
    required int focusMinutes,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    final remainingLabel = _formatDuration(max(0, remainingSeconds));
    final body = '$remainingLabel left in your $focusMinutes min focus block';

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );

    try {
      await _notifications.show(
        id: _activeSessionNotificationId,
        title: 'Focus session running',
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Keep timer flow resilient if notification API is unavailable.
    }
  }

  Future<void> cancelActiveSession() async {
    if (!_initialized || kIsWeb) {
      return;
    }

    try {
      await _notifications.cancel(id: _activeSessionNotificationId);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  Future<void> showSessionComplete({required int focusMinutes}) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.cancel(id: _activeSessionNotificationId);
      await _notifications.show(
        id: _sessionCompleteNotificationId,
        title: 'Focus session complete',
        body: 'Logged $focusMinutes focused minutes.',
        notificationDetails: details,
      );
    } catch (_) {
      // Completion alert is a nice-to-have and should never crash the app.
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
}
