import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../focus_notification_service.dart';
import '../models/session_log.dart';

/// Manages focus timer sessions and notifications
class TimerState extends ChangeNotifier with WidgetsBindingObserver {
  static const List<int> minutePresets = [15, 25, 45, 60];

  int _focusMinutes = 45;
  int _remainingSeconds = 45 * 60;
  bool _isRunning = false;
  int? _sessionEndEpochMs;
  Timer? _ticker;
  int? _lastSessionNotificationBucket;

  List<SessionLog> _logs = [];

  // Callbacks
  VoidCallback? onSessionComplete;

  int get focusMinutes => _focusMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  List<SessionLog> get logs => List.unmodifiable(_logs);

  bool get hasFocusProgress =>
      _isRunning || _remainingSeconds != _focusMinutes * 60;

  /// Get sessions this week
  int get sessionsThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return _logs.where((log) => !log.completedAt.isBefore(start)).length;
  }

  /// Get minutes this week
  int get minutesThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return _logs
        .where((log) => !log.completedAt.isBefore(start))
        .fold<int>(0, (sum, log) => sum + log.minutes);
  }

  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Initialize state
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await FocusNotificationService.instance.initialize();
    await _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimerWithWallClock(isAppResume: true);
      _ensureTickerRunning();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveState();
    }
  }

  /// Set focus duration
  void setFocusMinutes(int minutes) {
    if (_isRunning || _focusMinutes == minutes) return;

    _focusMinutes = minutes;
    _remainingSeconds = minutes * 60;
    notifyListeners();
    _saveState();
  }

  /// Toggle timer (start/pause)
  void toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  /// Start the timer
  void _startTimer() {
    if (_isRunning) return;

    if (_remainingSeconds <= 0) {
      _remainingSeconds = _focusMinutes * 60;
    }

    _isRunning = true;
    _sessionEndEpochMs =
        DateTime.now().millisecondsSinceEpoch + (_remainingSeconds * 1000);
    notifyListeners();
    _ensureTickerRunning();
    _syncFocusSessionNotification(force: true);
    _saveState();
  }

  /// Pause the timer
  void _pauseTimer() {
    if (!_isRunning) return;

    final endEpochMs = _sessionEndEpochMs;
    var pausedRemaining = _remainingSeconds;

    if (endEpochMs != null) {
      final fromDeadline =
          ((endEpochMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (fromDeadline <= 0) {
        _handleSessionComplete();
        return;
      }
      pausedRemaining = min(_focusMinutes * 60, fromDeadline);
    }

    _ticker?.cancel();
    _isRunning = false;
    _sessionEndEpochMs = null;
    _remainingSeconds = pausedRemaining;
    notifyListeners();
    _clearFocusSessionNotification();
    _saveState();
  }

  /// Reset timer
  void resetTimer() {
    _ticker?.cancel();
    _isRunning = false;
    _sessionEndEpochMs = null;
    _remainingSeconds = _focusMinutes * 60;
    notifyListeners();
    _clearFocusSessionNotification();
    _saveState();
  }

  /// Handle session completion
  void _handleSessionComplete({bool fromResume = false}) {
    _ticker?.cancel();
    _isRunning = false;
    _sessionEndEpochMs = null;
    _remainingSeconds = _focusMinutes * 60;

    _logs = [
      SessionLog(completedAt: DateTime.now(), minutes: _focusMinutes),
      ..._logs,
    ].take(100).toList();

    notifyListeners();
    _clearFocusSessionNotification();
    _showFocusSessionCompleteNotification();
    _saveState();

    onSessionComplete?.call();
  }

  /// Ensure ticker is running if timer is active
  void _ensureTickerRunning() {
    _ticker?.cancel();
    if (!_isRunning) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      final completed = _syncTimerWithWallClock();
      if (completed) {
        timer.cancel();
      }
    });
  }

  /// Sync timer with wall clock
  bool _syncTimerWithWallClock({bool isAppResume = false}) {
    if (!_isRunning) return false;

    final endEpochMs = _sessionEndEpochMs;
    if (endEpochMs == null) {
      _isRunning = false;
      _remainingSeconds = _focusMinutes * 60;
      notifyListeners();
      _clearFocusSessionNotification();
      _saveState();
      return false;
    }

    final fullSessionSeconds = _focusMinutes * 60;
    final remaining =
        ((endEpochMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();

    if (remaining <= 0) {
      _handleSessionComplete(fromResume: isAppResume);
      return true;
    }

    final clamped = min(fullSessionSeconds, remaining);
    if (_remainingSeconds != clamped) {
      _remainingSeconds = clamped;
      notifyListeners();
    }

    _syncFocusSessionNotification();
    return false;
  }

  /// Notification helpers
  int _sessionNotificationBucket(int remaining) {
    if (remaining <= 60) {
      return remaining ~/ 10;
    }
    return remaining ~/ 60;
  }

  void _syncFocusSessionNotification({bool force = false}) {
    if (!_isRunning) return;

    final bucket = _sessionNotificationBucket(_remainingSeconds);
    if (!force && _lastSessionNotificationBucket == bucket) return;

    _lastSessionNotificationBucket = bucket;
    unawaited(
      FocusNotificationService.instance.showActiveSession(
        remainingSeconds: _remainingSeconds,
        focusMinutes: _focusMinutes,
      ),
    );
  }

  void _clearFocusSessionNotification() {
    _lastSessionNotificationBucket = null;
    unawaited(FocusNotificationService.instance.cancelActiveSession());
  }

  void _showFocusSessionCompleteNotification() {
    _lastSessionNotificationBucket = null;
    unawaited(
      FocusNotificationService.instance.showSessionComplete(
        focusMinutes: _focusMinutes,
      ),
    );
  }

  /// Load state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawFocus = prefs.getInt('timer_focus_minutes');
      if (rawFocus != null && minutePresets.contains(rawFocus)) {
        _focusMinutes = rawFocus;
      }

      final fullSessionSeconds = _focusMinutes * 60;
      final rawRemaining = prefs.getInt('timer_remaining_seconds');
      if (rawRemaining != null &&
          rawRemaining > 0 &&
          rawRemaining <= fullSessionSeconds) {
        _remainingSeconds = rawRemaining;
      } else {
        _remainingSeconds = fullSessionSeconds;
      }

      _isRunning = prefs.getBool('timer_is_running') ?? false;
      _sessionEndEpochMs = prefs.getInt('timer_session_end_epoch_ms');

      // Load logs
      final logsJson = prefs.getStringList('timer_logs') ?? [];
      _logs = logsJson
          .map((json) {
            try {
              return SessionLog.fromJson(json as dynamic);
            } catch (_) {
              return null;
            }
          })
          .whereType<SessionLog>()
          .toList();

      // Check if session completed while away
      if (_isRunning && _sessionEndEpochMs != null) {
        final remainingFromDeadline =
            ((_sessionEndEpochMs! - DateTime.now().millisecondsSinceEpoch) /
                    1000)
                .ceil();

        if (remainingFromDeadline <= 0) {
          _isRunning = false;
          _sessionEndEpochMs = null;
          _remainingSeconds = fullSessionSeconds;
          _logs = [
            SessionLog(completedAt: DateTime.now(), minutes: _focusMinutes),
            ..._logs,
          ].take(100).toList();
          await _saveState();
        }
      }

      notifyListeners();

      _ensureTickerRunning();
      if (_isRunning) {
        _syncFocusSessionNotification(force: true);
      } else {
        _clearFocusSessionNotification();
      }
    } catch (e) {
      debugPrint('Error loading timer state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('timer_focus_minutes', _focusMinutes);
      await prefs.setInt('timer_remaining_seconds', _remainingSeconds);
      await prefs.setBool('timer_is_running', _isRunning);

      if (_sessionEndEpochMs != null) {
        await prefs.setInt('timer_session_end_epoch_ms', _sessionEndEpochMs!);
      } else {
        await prefs.remove('timer_session_end_epoch_ms');
      }

      final logsJson = _logs.map((log) => log.toJson()).toList();
      await prefs.setStringList(
        'timer_logs',
        logsJson.map((json) => json.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving timer state: $e');
    }
  }

  /// Clear all logs (for testing/reset)
  void clearLogs() {
    _logs = [];
    notifyListeners();
    _saveState();
  }
}
