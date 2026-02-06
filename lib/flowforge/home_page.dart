import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/session_log.dart';
import 'models/task_energy_requirement.dart';
import 'models/todo_item.dart';

class FlowForgeHome extends StatefulWidget {
  const FlowForgeHome({super.key});

  @override
  State<FlowForgeHome> createState() => _FlowForgeHomeState();
}

class _FlowForgeHomeState extends State<FlowForgeHome>
    with WidgetsBindingObserver {
  static const String _stateKey = 'flowforge_state_v1';
  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(20, 6, 20, 130);
  static const double _sectionGap = 14;
  static const List<int> _minutePresets = <int>[15, 25, 45, 60];
  static const List<int> _todoEstimatePresets = <int>[10, 15, 25, 45, 60, 90];
  static const int _activityDays = 84;
  static const int _maxSessionLogs = 420;
  static const List<_EnergyPreset> _energyPresets = <_EnergyPreset>[
    _EnergyPreset(
      value: 25,
      label: 'Low',
      hint: 'Recovery mode',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF5F7A8A),
    ),
    _EnergyPreset(
      value: 45,
      label: 'Warm',
      hint: 'Build momentum',
      icon: Icons.eco_rounded,
      color: Color(0xFF4F8A63),
    ),
    _EnergyPreset(
      value: 65,
      label: 'Steady',
      hint: 'Main work mode',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFBA7A32),
    ),
    _EnergyPreset(
      value: 85,
      label: 'Surging',
      hint: 'Deep push',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF8F3A2A),
    ),
  ];

  final List<TextEditingController> _taskControllers =
      List<TextEditingController>.generate(3, (_) => TextEditingController());
  final TextEditingController _winController = TextEditingController();
  final TextEditingController _frictionController = TextEditingController();
  final TextEditingController _tomorrowController = TextEditingController();
  final TextEditingController _todoInputController = TextEditingController();

  late List<bool> _taskDone;
  late double _energy;
  late int _focusMinutes;
  late int _remainingSeconds;
  late TaskEnergyRequirement _newTodoEnergyRequirement;
  late int _newTodoEstimateMinutes;

  int _tabIndex = 0;
  bool _isRunning = false;
  int? _sessionEndEpochMs;
  String? _focusedTodoId;
  bool _showFinishedTodos = false;
  String _shutdownNote = '';
  List<SessionLog> _logs = <SessionLog>[];
  List<TodoItem> _todos = <TodoItem>[];
  Timer? _ticker;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taskDone = List<bool>.filled(3, false);
    _energy = 65;
    _focusMinutes = 45;
    _remainingSeconds = _focusMinutes * 60;
    _newTodoEnergyRequirement = TaskEnergyRequirement.medium;
    _newTodoEstimateMinutes = 25;

    const defaults = <String>[
      'Ship the hardest task first',
      'Protect one no-meeting focus block',
      'Write a clean shutdown note',
    ];

    for (var i = 0; i < _taskControllers.length; i++) {
      _taskControllers[i].text = defaults[i];
      _taskControllers[i].addListener(_queueSave);
    }
    _winController.addListener(_queueSave);
    _frictionController.addListener(_queueSave);
    _tomorrowController.addListener(_queueSave);

    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _saveDebounce?.cancel();
    for (final controller in _taskControllers) {
      controller.dispose();
    }
    _winController.dispose();
    _frictionController.dispose();
    _tomorrowController.dispose();
    _todoInputController.dispose();
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
      _queueSave();
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) {
      return;
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    var completedWhileAway = false;

    setState(() {
      final rawEnergy = payload['energy'];
      if (rawEnergy is num) {
        _energy = _snapEnergy(rawEnergy.toDouble());
      }

      final taskTexts = payload['task_texts'];
      if (taskTexts is List) {
        for (
          var i = 0;
          i < _taskControllers.length && i < taskTexts.length;
          i++
        ) {
          final value = taskTexts[i];
          if (value is String && value.trim().isNotEmpty) {
            _taskControllers[i].text = value;
          }
        }
      }

      final rawDone = payload['task_done'];
      if (rawDone is List) {
        for (var i = 0; i < _taskDone.length && i < rawDone.length; i++) {
          final value = rawDone[i];
          if (value is bool) {
            _taskDone[i] = value;
          }
        }
      }

      final rawFocus = payload['focus_minutes'];
      if (rawFocus is int && _minutePresets.contains(rawFocus)) {
        _focusMinutes = rawFocus;
      }
      final fullSessionSeconds = _focusMinutes * 60;

      final rawRemaining = payload['remaining_seconds'];
      if (rawRemaining is int &&
          rawRemaining > 0 &&
          rawRemaining <= fullSessionSeconds) {
        _remainingSeconds = rawRemaining;
      } else {
        _remainingSeconds = fullSessionSeconds;
      }

      final rawWin = payload['win'];
      if (rawWin is String) {
        _winController.text = rawWin;
      }
      final rawFriction = payload['friction'];
      if (rawFriction is String) {
        _frictionController.text = rawFriction;
      }
      final rawTomorrow = payload['tomorrow'];
      if (rawTomorrow is String) {
        _tomorrowController.text = rawTomorrow;
      }
      final rawNote = payload['shutdown_note'];
      if (rawNote is String) {
        _shutdownNote = rawNote;
      }

      _logs = _decodeLogs(payload['logs']);
      _todos = _decodeTodos(payload['todos']);
      _showFinishedTodos = payload['show_finished_todos'] == true;

      final savedFocusTodoId = payload['focused_todo_id'];
      _focusedTodoId = _pickFocusedTodoId(
        _todos,
        preferredId: savedFocusTodoId is String ? savedFocusTodoId : null,
      );

      _isRunning = payload['is_running'] == true;
      final rawSessionEndEpochMs = payload['session_end_epoch_ms'];
      _sessionEndEpochMs = rawSessionEndEpochMs is int
          ? rawSessionEndEpochMs
          : null;

      if (_isRunning && _sessionEndEpochMs != null) {
        final remainingFromDeadline =
            ((_sessionEndEpochMs! - DateTime.now().millisecondsSinceEpoch) /
                    1000)
                .ceil();
        if (remainingFromDeadline > 0) {
          _remainingSeconds = min(fullSessionSeconds, remainingFromDeadline);
        } else {
          _isRunning = false;
          _sessionEndEpochMs = null;
          _remainingSeconds = fullSessionSeconds;
          _logs = <SessionLog>[
            SessionLog(completedAt: DateTime.now(), minutes: _focusMinutes),
            ..._logs,
          ].take(_maxSessionLogs).toList();
          completedWhileAway = true;
        }
      } else {
        _isRunning = false;
        _sessionEndEpochMs = null;
      }
    });

    _ensureTickerRunning();

    if (completedWhileAway) {
      _queueSave();
      _showSnack('Focus session finished while you were away. Session logged.');
    }
  }

  List<SessionLog> _decodeLogs(Object? rawLogs) {
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
    return parsed.take(_maxSessionLogs).toList();
  }

  List<TodoItem> _decodeTodos(Object? rawTodos) {
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

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'energy': _energy,
      'task_texts': _taskControllers
          .map((controller) => controller.text)
          .toList(),
      'task_done': _taskDone,
      'focus_minutes': _focusMinutes,
      'remaining_seconds': _remainingSeconds,
      'is_running': _isRunning,
      'session_end_epoch_ms': _sessionEndEpochMs,
      'win': _winController.text,
      'friction': _frictionController.text,
      'tomorrow': _tomorrowController.text,
      'shutdown_note': _shutdownNote,
      'focused_todo_id': _focusedTodoId,
      'show_finished_todos': _showFinishedTodos,
      'logs': _logs.map((log) => log.toJson()).toList(),
      'todos': _todos.map((todo) => todo.toJson()).toList(),
    };
    await prefs.setString(_stateKey, jsonEncode(payload));
  }

  void _queueSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _saveState);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
      return;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_isRunning) {
      return;
    }

    if (_remainingSeconds <= 0) {
      _remainingSeconds = _focusMinutes * 60;
    }

    setState(() {
      _isRunning = true;
      _sessionEndEpochMs =
          DateTime.now().millisecondsSinceEpoch + (_remainingSeconds * 1000);
    });
    _ensureTickerRunning();
    _queueSave();
  }

  void _ensureTickerRunning() {
    _ticker?.cancel();
    if (!_isRunning) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRunning) {
        timer.cancel();
        return;
      }

      final completed = _syncTimerWithWallClock();
      if (completed) {
        timer.cancel();
      }
    });
  }

  bool _syncTimerWithWallClock({bool isAppResume = false}) {
    if (!_isRunning) {
      return false;
    }

    final endEpochMs = _sessionEndEpochMs;
    if (endEpochMs == null) {
      setState(() {
        _isRunning = false;
        _remainingSeconds = _focusMinutes * 60;
      });
      _queueSave();
      return false;
    }

    final fullSessionSeconds = _focusMinutes * 60;
    final remainingSeconds =
        ((endEpochMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remainingSeconds <= 0) {
      _handleSessionComplete(fromResume: isAppResume);
      return true;
    }

    final clamped = min(fullSessionSeconds, remainingSeconds);
    if (_remainingSeconds != clamped) {
      setState(() {
        _remainingSeconds = clamped;
      });
    }

    return false;
  }

  void _pauseTimer() {
    if (!_isRunning) {
      return;
    }

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
    setState(() {
      _isRunning = false;
      _sessionEndEpochMs = null;
      _remainingSeconds = pausedRemaining;
    });
    _queueSave();
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _sessionEndEpochMs = null;
      _remainingSeconds = _focusMinutes * 60;
    });
    _queueSave();
  }

  Future<void> _confirmResetTimer() async {
    if (!_hasFocusProgress) {
      return;
    }

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const ValueKey<String>('focus-reset-dialog'),
          title: const Text('Reset focus session?'),
          content: Text(
            'This will clear your current timer and return it to $_focusMinutes minutes.',
          ),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('focus-reset-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey<String>('focus-reset-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true && mounted) {
      _resetTimer();
    }
  }

  void _handleSessionComplete({bool fromResume = false}) {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _sessionEndEpochMs = null;
      _remainingSeconds = _focusMinutes * 60;
      _logs = <SessionLog>[
        SessionLog(completedAt: DateTime.now(), minutes: _focusMinutes),
        ..._logs,
      ].take(_maxSessionLogs).toList();
    });
    _queueSave();

    _showSnack(
      fromResume
          ? 'Session completed while you were away. Logged $_focusMinutes minutes.'
          : 'Session complete. Logged $_focusMinutes minutes.',
    );
  }

  void _setFocusMinutes(int minutes) {
    if (_isRunning || _focusMinutes == minutes) {
      return;
    }

    setState(() {
      _focusMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _focusedTodoId = _pickFocusedTodoId(_todos, preferredId: _focusedTodoId);
    });
    _queueSave();
  }

  void _setEnergy(double value) {
    final snapped = _snapEnergy(value);
    final recommendedFocus = _recommendedFocusMinutesFor(snapped);
    final shouldAutoSyncFocus =
        !_isRunning && _focusMinutes != recommendedFocus;
    final energyChanged = _energy != snapped;
    if (!energyChanged && !shouldAutoSyncFocus) {
      return;
    }

    setState(() {
      _energy = snapped;
      if (shouldAutoSyncFocus) {
        _focusMinutes = recommendedFocus;
        _remainingSeconds = recommendedFocus * 60;
      }
      _focusedTodoId = _pickFocusedTodoId(_todos, preferredId: _focusedTodoId);
    });
    _queueSave();
  }

  void _setEnergyPreset(_EnergyPreset preset) {
    _setEnergy(preset.value.toDouble());
  }

  void _setTaskDone(int index, bool value) {
    setState(() {
      _taskDone[index] = value;
    });
    _queueSave();
  }

  void _setNewTodoEnergyRequirement(TaskEnergyRequirement requirement) {
    setState(() {
      _newTodoEnergyRequirement = requirement;
    });
  }

  void _setNewTodoEstimateMinutes(int minutes) {
    setState(() {
      _newTodoEstimateMinutes = minutes;
    });
  }

  void _addTodo() {
    final text = _todoInputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final item = TodoItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      title: text,
      isDone: false,
      createdAt: DateTime.now(),
      energyRequirement: _newTodoEnergyRequirement,
      estimateMinutes: _newTodoEstimateMinutes,
    );

    setState(() {
      final updatedTodos = <TodoItem>[..._todos, item];
      _todos = updatedTodos;
      _focusedTodoId = _pickFocusedTodoId(
        updatedTodos,
        preferredId: _focusedTodoId ?? item.id,
      );
      _todoInputController.clear();
    });
    _queueSave();
  }

  void _setFocusedTodo(String id) {
    if (_focusedTodoId == id) {
      return;
    }
    if (!_todos.any((todo) => todo.id == id && !todo.isDone)) {
      return;
    }

    setState(() {
      _focusedTodoId = id;
    });
    _queueSave();
  }

  void _toggleTodo(String id, bool value) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) {
      return;
    }

    final existing = _todos[index];
    if (existing.isDone == value) {
      return;
    }

    setState(() {
      final updated = existing.copyWith(isDone: value);
      final updatedTodos = List<TodoItem>.from(_todos)..[index] = updated;
      _todos = updatedTodos;

      final preferredId = value
          ? (_focusedTodoId == id ? null : _focusedTodoId)
          : id;
      _focusedTodoId = _pickFocusedTodoId(
        updatedTodos,
        preferredId: preferredId,
      );
    });
    _queueSave();
  }

  void _deleteTodo(String id) {
    setState(() {
      final updatedTodos = _todos.where((todo) => todo.id != id).toList();
      _todos = updatedTodos;
      _focusedTodoId = _pickFocusedTodoId(
        updatedTodos,
        preferredId: _focusedTodoId == id ? null : _focusedTodoId,
      );
    });
    _queueSave();
  }

  void _clearCompletedTodos() {
    if (_completedTodoCount == 0) {
      return;
    }
    setState(() {
      final updatedTodos = _todos.where((todo) => !todo.isDone).toList();
      _todos = updatedTodos;
      _focusedTodoId = _pickFocusedTodoId(
        updatedTodos,
        preferredId: _focusedTodoId,
      );
      _showFinishedTodos = false;
    });
    _queueSave();
  }

  void _draftShutdownNote() {
    final completed = _taskDone.where((item) => item).length;
    final sessionsToday = _logs
        .where((log) => _isSameDay(log.completedAt, DateTime.now()))
        .length;
    final todosClosed = _completedTodoCount;
    final win = _cleanSummary(
      _winController.text,
      fallback: 'Made progress where it mattered.',
    );
    final friction = _cleanSummary(
      _frictionController.text,
      fallback: 'Context switching diluted focus at points.',
    );
    final tomorrow = _cleanSummary(
      _tomorrowController.text,
      fallback: 'Begin with the hardest open loop.',
    );

    setState(() {
      _shutdownNote =
          'Closed $completed of ${_taskDone.length} priorities and logged $sessionsToday focus '
          '${sessionsToday == 1 ? 'session' : 'sessions'}, with $todosClosed todo '
          '${todosClosed == 1 ? 'done' : 'items done'}. '
          'Win: $win Friction: $friction Tomorrow first move: $tomorrow';
    });
    _queueSave();
  }

  void _resetDay() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _sessionEndEpochMs = null;
      _energy = 65;
      _taskDone = List<bool>.filled(3, false);
      _remainingSeconds = _focusMinutes * 60;
      _logs = <SessionLog>[];
      final openTodos = _todos.where((todo) => !todo.isDone).toList();
      _todos = openTodos;
      _focusedTodoId = _pickFocusedTodoId(
        openTodos,
        preferredId: _focusedTodoId,
      );
      _showFinishedTodos = false;
      _shutdownNote = '';
      _winController.clear();
      _frictionController.clear();
      _tomorrowController.clear();
      _todoInputController.clear();
      _newTodoEnergyRequirement = TaskEnergyRequirement.medium;
      _newTodoEstimateMinutes = 25;
    });
    _queueSave();
  }

  String? _pickFocusedTodoId(List<TodoItem> todos, {String? preferredId}) {
    final openTodos = todos.where((todo) => !todo.isDone).toList();
    if (openTodos.isEmpty) {
      return null;
    }

    if (preferredId != null &&
        openTodos.any((todo) => todo.id == preferredId)) {
      return preferredId;
    }

    openTodos.sort((a, b) {
      final scoreCompare = _todoSuitabilityScore(
        a,
      ).compareTo(_todoSuitabilityScore(b));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return openTodos.first.id;
  }

  int get _momentumScore {
    final completed = _taskDone.where((item) => item).length;
    final completionScore = (completed / _taskDone.length) * 40;
    final energyScore = _energy * 0.25;
    final sessions = _logs
        .where((log) => _isSameDay(log.completedAt, DateTime.now()))
        .length;
    final sessionScore = min(4, sessions) * 5;
    final totalTodoEffort = _todos.fold<int>(
      0,
      (sum, todo) => sum + todo.estimateMinutes,
    );
    final completedTodoEffort = _todos
        .where((todo) => todo.isDone)
        .fold<int>(0, (sum, todo) => sum + todo.estimateMinutes);
    final todoScore = totalTodoEffort == 0
        ? 0
        : (completedTodoEffort / totalTodoEffort) * 15;
    return max(
      0,
      min(
        100,
        (completionScore + energyScore + sessionScore + todoScore).round(),
      ),
    );
  }

  _EnergyPreset _closestEnergyPreset(double value) {
    var closest = _energyPresets.first;
    var closestDistance = (closest.value - value).abs();
    for (final preset in _energyPresets.skip(1)) {
      final distance = (preset.value - value).abs();
      if (distance < closestDistance) {
        closest = preset;
        closestDistance = distance;
      }
    }
    return closest;
  }

  double _snapEnergy(double value) {
    return _closestEnergyPreset(value).value.toDouble();
  }

  _EnergyPreset get _activeEnergyPreset => _closestEnergyPreset(_energy);

  int _recommendedFocusMinutesFor(double energy) {
    if (energy >= 80) {
      return 60;
    }
    if (energy >= 60) {
      return 45;
    }
    if (energy >= 40) {
      return 25;
    }
    return 15;
  }

  int get _recommendedFocusMinutes => _recommendedFocusMinutesFor(_energy);

  String get _energyGuidance {
    if (_energy >= 80) {
      return 'Great window for deep work. Protect one hard 60-minute block.';
    }
    if (_energy >= 60) {
      return 'Solid pace. Aim for a meaningful block and one decisive todo.';
    }
    if (_energy >= 40) {
      return 'Medium fuel. Use shorter sprints and close easy wins first.';
    }
    return 'Low battery. Keep scope tight and knock out lightweight tasks.';
  }

  String get _energyLabel {
    if (_energy >= 80) {
      return 'Surging';
    }
    if (_energy >= 60) {
      return 'Steady';
    }
    if (_energy >= 40) {
      return 'Warming up';
    }
    return 'Low battery';
  }

  int get _currentEnergyScore => _energy.round();

  List<TodoItem> get _openTodos =>
      _todos.where((todo) => !todo.isDone).toList(growable: false);

  List<TodoItem> get _completedTodos {
    final completed = _todos
        .where((todo) => todo.isDone)
        .toList(growable: false);
    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return completed;
  }

  TodoItem? get _focusedTodo {
    final focusedId = _focusedTodoId;
    if (focusedId == null) {
      return null;
    }
    for (final todo in _openTodos) {
      if (todo.id == focusedId) {
        return todo;
      }
    }
    return null;
  }

  List<TodoItem> get _sortedOpenTodos {
    final sorted = List<TodoItem>.from(_openTodos)
      ..sort((a, b) {
        final aFocused = a.id == _focusedTodoId;
        final bFocused = b.id == _focusedTodoId;
        if (aFocused && !bFocused) {
          return -1;
        }
        if (bFocused && !aFocused) {
          return 1;
        }

        final scoreCompare = _todoSuitabilityScore(
          a,
        ).compareTo(_todoSuitabilityScore(b));
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    return sorted;
  }

  List<TodoItem> get _queuedTodos {
    final focusedId = _focusedTodoId;
    if (focusedId == null) {
      return _sortedOpenTodos;
    }
    return _sortedOpenTodos
        .where((todo) => todo.id != focusedId)
        .toList(growable: false);
  }

  TodoItem? get _nextBestTodo {
    if (_sortedOpenTodos.isEmpty) {
      return null;
    }
    return _sortedOpenTodos.first;
  }

  int _todoSuitabilityScore(TodoItem todo) {
    final energyGap = max(
      0,
      todo.energyRequirement.minEnergy - _currentEnergyScore,
    );
    final timeGap = max(0, todo.estimateMinutes - _focusMinutes);
    return (energyGap * 2) + timeGap;
  }

  bool _isEnergyFit(TodoItem todo) {
    return _currentEnergyScore >= todo.energyRequirement.minEnergy;
  }

  bool _isTimeFit(TodoItem todo) {
    return _focusMinutes >= todo.estimateMinutes;
  }

  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  List<_DailySessionActivity> get _activitySeries {
    final today = _startOfDay(DateTime.now());
    final oldestDay = today.subtract(const Duration(days: _activityDays - 1));
    final byDay = <DateTime, _DailySessionActivity>{};

    for (final log in _logs) {
      final day = _startOfDay(log.completedAt);
      if (day.isBefore(oldestDay) || day.isAfter(today)) {
        continue;
      }
      final current = byDay[day];
      if (current == null) {
        byDay[day] = _DailySessionActivity(
          day: day,
          sessions: 1,
          minutes: log.minutes,
        );
      } else {
        byDay[day] = _DailySessionActivity(
          day: day,
          sessions: current.sessions + 1,
          minutes: current.minutes + log.minutes,
        );
      }
    }

    return List<_DailySessionActivity>.generate(_activityDays, (index) {
      final day = oldestDay.add(Duration(days: index));
      return byDay[day] ??
          _DailySessionActivity(day: day, sessions: 0, minutes: 0);
    });
  }

  int get _sessionsThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return _logs.where((log) => !log.completedAt.isBefore(start)).length;
  }

  int get _minutesThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return _logs
        .where((log) => !log.completedAt.isBefore(start))
        .fold<int>(0, (sum, log) => sum + log.minutes);
  }

  String _todoConstraintHint(TodoItem todo) {
    final energyFit = _isEnergyFit(todo);
    final timeFit = _isTimeFit(todo);
    if (energyFit && timeFit) {
      return 'Fits your current energy and focus block.';
    }
    if (!energyFit && !timeFit) {
      return 'Needs more energy and more uninterrupted time.';
    }
    if (!energyFit) {
      return 'Needs a higher-energy window.';
    }
    return 'Needs a longer focus block than your current timer.';
  }

  int get _openTodoCount => _todos.where((todo) => !todo.isDone).length;

  int get _completedTodoCount => _todos.where((todo) => todo.isDone).length;

  bool get _hasFocusProgress =>
      _isRunning || _remainingSeconds != _focusMinutes * 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF7F3E8), Color(0xFFE8F2EA)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -70,
              right: -60,
              child: _backgroundOrb(const Color(0xFFF9C66B), 200),
            ),
            Positioned(
              top: 180,
              left: -70,
              child: _backgroundOrb(const Color(0xFF98C9B6), 180),
            ),
            Positioned(
              bottom: -80,
              right: 10,
              child: _backgroundOrb(const Color(0xFFA8BED8), 220),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _header(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_tabIndex),
                        child: _tabContent(),
                      ),
                    ),
                  ),
                  _bottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'FlowForge',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFullDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5A5852),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1F7A6A),
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF1F7A6A).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Momentum',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '$_momentumScore',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    switch (_tabIndex) {
      case 0:
        return _todayTab();
      case 1:
        return _focusTab();
      case 2:
      default:
        return _reflectTab();
    }
  }

  Widget _todayTab() {
    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily Intent',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'I use this app to be deliberate: three priorities, one deep session, then a clean shutdown.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF55524C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Energy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_energy.round()}% · $_energyLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF55524C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _energyPresets.map((preset) {
                    final selected = preset.value == _activeEnergyPreset.value;
                    return ChoiceChip(
                      key: ValueKey<String>('energy-preset-${preset.value}'),
                      tooltip: preset.hint,
                      selected: selected,
                      selectedColor: preset.color.withValues(alpha: 0.18),
                      side: BorderSide(
                        color: selected
                            ? preset.color.withValues(alpha: 0.6)
                            : const Color(0xFFCFCFC9),
                      ),
                      avatar: Icon(preset.icon, size: 16, color: preset.color),
                      label: Text('${preset.label} ${preset.value}%'),
                      onSelected: (_) => _setEnergyPreset(preset),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  _activeEnergyPreset.hint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF625D54),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC4DCCE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Suggested focus block: $_recommendedFocusMinutes min',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _energyGuidance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4D554E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRunning
                            ? 'Focus timer will auto-sync after this session.'
                            : 'Focus timer auto-syncs instantly when energy changes.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF486153),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Top Three',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _taskControllers.length; i++) ...<Widget>[
                  _taskRow(i),
                  if (i < _taskControllers.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          _todoPanel(),
        ],
      ),
    );
  }

  Widget _taskRow(int index) {
    final complete = _taskDone[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFE4F3EB) : const Color(0xFFF4F3EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: complete,
            activeColor: const Color(0xFF1F7A6A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) => _setTaskDone(index, value ?? false),
          ),
          Expanded(
            child: TextField(
              controller: _taskControllers[index],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Priority ${index + 1}',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                decoration: complete ? TextDecoration.lineThrough : null,
                color: complete ? const Color(0xFF5B7F6D) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todoPanel() {
    final focusedTodo = _focusedTodo;
    final queuedTodos = _queuedTodos;
    final completedTodos = _completedTodos;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Todos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$_openTodoCount open · $_completedTodoCount finished',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF625F58)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('todo-input'),
                  controller: _todoInputController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTodo(),
                  decoration: const InputDecoration(
                    hintText: 'Add a quick todo...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey<String>('todo-add-button'),
                onPressed: _addTodo,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A6A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TaskEnergyRequirement.values
                .map(
                  (requirement) => ChoiceChip(
                    key: ValueKey<String>('todo-energy-${requirement.name}'),
                    selected: _newTodoEnergyRequirement == requirement,
                    onSelected: (_) =>
                        _setNewTodoEnergyRequirement(requirement),
                    selectedColor: requirement.accent.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: requirement.accent.withValues(alpha: 0.35),
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          requirement.icon,
                          size: 15,
                          color: requirement.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(requirement.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _todoEstimatePresets
                .map(
                  (minutes) => ChoiceChip(
                    key: ValueKey<String>('todo-effort-$minutes'),
                    selected: _newTodoEstimateMinutes == minutes,
                    onSelected: (_) => _setNewTodoEstimateMinutes(minutes),
                    selectedColor: const Color(0xFFE4EEF8),
                    label: Text('$minutes min'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'New task: ${_newTodoEnergyRequirement.label} energy, $_newTodoEstimateMinutes minutes.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5F5B55)),
          ),
          if (focusedTodo == null && _nextBestTodo != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC3D4C7)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _isEnergyFit(_nextBestTodo!)
                        ? Icons.bolt_rounded
                        : Icons.schedule_rounded,
                    color: const Color(0xFF2C6A52),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Best next: ${_nextBestTodo!.title} • ${_todoConstraintHint(_nextBestTodo!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF395044),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_todos.isEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Nothing captured yet. Add small tasks here so your Top Three stay clean.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5E5A54)),
            ),
          ],
          if (focusedTodo != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Now Focusing',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'One thing at a time. This task stays pinned until you finish it or switch focus.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF57534C)),
            ),
            _todoRow(focusedTodo, isFocused: true),
          ] else if (_openTodoCount > 0) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Pick one task to focus. Single-task mode works best when one item is active.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF57534C)),
            ),
          ],
          if (queuedTodos.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Queue (${queuedTodos.length})',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            ...queuedTodos.map(_todoRow),
          ],
          if (_openTodoCount == 0 && _todos.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Open list cleared. Great stopping point.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF4E5F53)),
            ),
          ],
          if (completedTodos.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Finished (${completedTodos.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton(
                  key: const ValueKey<String>('toggle-finished-todos'),
                  onPressed: () {
                    setState(() {
                      _showFinishedTodos = !_showFinishedTodos;
                    });
                    _queueSave();
                  },
                  child: Text(_showFinishedTodos ? 'Hide' : 'Show'),
                ),
              ],
            ),
            if (_showFinishedTodos) ...completedTodos.map(_todoRow),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearCompletedTodos,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text('Clear finished (${completedTodos.length})'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _todoRow(TodoItem todo, {bool isFocused = false}) {
    final isDone = todo.isDone;
    final energyFits = _isEnergyFit(todo);
    final timeFits = _isTimeFit(todo);
    final fitColor = energyFits && timeFits
        ? const Color(0xFF2E6A4E)
        : const Color(0xFF7B5D2C);
    final highlightColor = isDone
        ? const Color(0xFFE4F3EB)
        : isFocused
        ? const Color(0xFFE6F4EE)
        : const Color(0xFFF3F1EC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlightColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? const Color(0xFF2E7A63) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Checkbox(
            value: isDone,
            activeColor: const Color(0xFF1F7A6A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) => _toggleTodo(todo.id, value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  todo.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? const Color(0xFF50785F) : null,
                  ),
                ),
                if (isFocused && !isDone) ...<Widget>[
                  const SizedBox(height: 4),
                  _todoTag(
                    icon: Icons.center_focus_strong_rounded,
                    text: 'Focused now',
                    color: const Color(0xFF2E7A63),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _todoTag(
                      icon: todo.energyRequirement.icon,
                      text: '${todo.energyRequirement.label} energy',
                      color: todo.energyRequirement.accent,
                    ),
                    _todoTag(
                      icon: Icons.timer_outlined,
                      text: '${todo.estimateMinutes} min',
                      color: const Color(0xFF3E6287),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDone
                      ? 'Completed.'
                      : isFocused
                      ? 'This is your active task. Tap another open task to switch focus.'
                      : _todoConstraintHint(todo),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDone ? const Color(0xFF4E705B) : fitColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isDone)
                IconButton(
                  tooltip: isFocused ? 'Current focus task' : 'Focus this task',
                  onPressed: isFocused ? null : () => _setFocusedTodo(todo.id),
                  icon: Icon(
                    isFocused
                        ? Icons.center_focus_strong_rounded
                        : Icons.center_focus_weak_rounded,
                  ),
                ),
              IconButton(
                tooltip: 'Delete todo',
                onPressed: () => _deleteTodo(todo.id),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todoTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9D7CF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF1F7A6A)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: const Color(0xFF4D5F52)),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1D19),
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusTab() {
    final focusedTodo = _focusedTodo;
    final totalSeconds = _focusMinutes * 60;
    final completion = (1 - (_remainingSeconds / totalSeconds)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panel(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween<double>(
                          begin: 0,
                          end: completion.toDouble(),
                        ),
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 230,
                            height: 230,
                            child: CircularProgressIndicator(
                              strokeWidth: 13,
                              value: value,
                              backgroundColor: const Color(0xFFD8D7D2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isRunning
                                    ? const Color(0xFF1F7A6A)
                                    : const Color(0xFF2C527A),
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeInOut,
                        width: _isRunning ? 152 : 142,
                        height: _isRunning ? 152 : 142,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isRunning
                                ? const <Color>[
                                    Color(0xFF1F7A6A),
                                    Color(0xFF74B99A),
                                  ]
                                : const <Color>[
                                    Color(0xFF3A648F),
                                    Color(0xFF8DA8C9),
                                  ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color:
                                  (_isRunning
                                          ? const Color(0xFF1F7A6A)
                                          : const Color(0xFF355C86))
                                      .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _formatDuration(_remainingSeconds),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRunning
                                  ? 'Flow in progress'
                                  : 'Ready to focus',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                        ),
                        label: Text(
                          _isRunning ? 'Pause Session' : 'Start Session',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _toggleTimer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      key: const ValueKey<String>('focus-reset-button'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1F7A6A),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _hasFocusProgress ? _confirmResetTimer : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: _minutePresets
                      .map(
                        (minutes) => ChoiceChip(
                          label: Text('$minutes min'),
                          selectedColor: const Color(0xFFDCF1E7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: minutes == _focusMinutes,
                          onSelected: (_) => _setFocusMinutes(minutes),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0D6DD)),
                  ),
                  child: Text(
                    'Energy says $_recommendedFocusMinutes minutes is your best block right now.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B515A),
                    ),
                  ),
                ),
                if (focusedTodo != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC4DCCE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Current target',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          focusedTodo.title,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            _todoTag(
                              icon: focusedTodo.energyRequirement.icon,
                              text:
                                  '${focusedTodo.energyRequirement.label} energy',
                              color: focusedTodo.energyRequirement.accent,
                            ),
                            _todoTag(
                              icon: Icons.timer_outlined,
                              text: '${focusedTodo.estimateMinutes} min',
                              color: const Color(0xFF3E6287),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (_openTodoCount > 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Pick one open todo in Today tab so this session has a single target.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF56615A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: _sectionGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _statPill(
                icon: Icons.bolt_rounded,
                label: 'Sessions this week',
                value: '$_sessionsThisWeek',
              ),
              _statPill(
                icon: Icons.timer_outlined,
                label: 'Minutes this week',
                value: '$_minutesThisWeek',
              ),
            ],
          ),
          const SizedBox(height: _sectionGap),
          _activityBoard(),
          const SizedBox(height: _sectionGap),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  Text(
                    'No sessions yet. Start one and this timeline will build itself.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5B5A56),
                    ),
                  ),
                for (final log in _logs.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF1F7A6A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${log.minutes} min session',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          _formatTime(log.completedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF66635D)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityBoard() {
    final series = _activitySeries;
    final maxSessions = series.fold<int>(0, (maxValue, item) {
      return item.sessions > maxValue ? item.sessions : maxValue;
    });
    final weeks = <List<_DailySessionActivity>>[];
    for (var index = 0; index < series.length; index += 7) {
      final end = min(index + 7, series.length);
      weeks.add(series.sublist(index, end));
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Focus Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Git-style board for the last 12 weeks. $_sessionsThisWeek sessions this week ($_minutesThisWeek min).',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5D5B56)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0DCCF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 1),
                  child: Column(
                    children: const <Widget>[
                      _ActivityDayLabel(label: 'M'),
                      SizedBox(height: 12),
                      _ActivityDayLabel(label: 'W'),
                      SizedBox(height: 12),
                      _ActivityDayLabel(label: 'F'),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List<Widget>.generate(weeks.length, (
                        weekIndex,
                      ) {
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
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Tooltip(
                                  message:
                                      '${_formatShortDate(day.day)} · ${day.sessions} '
                                      '${day.sessions == 1 ? 'session' : 'sessions'} · '
                                      '${day.minutes} min',
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF6B6963),
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
                    color: _activityColorForDay(sampleSessions, maxSessions),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF6B6963),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reflectTab() {
    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Shutdown Ritual',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'I keep this simple so tomorrow starts clean.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF595751),
                  ),
                ),
                const SizedBox(height: 14),
                _promptField(
                  label: 'Biggest win',
                  controller: _winController,
                  hint: 'What moved the needle today?',
                ),
                const SizedBox(height: 12),
                _promptField(
                  label: 'Main friction',
                  controller: _frictionController,
                  hint: 'What slowed me down?',
                ),
                const SizedBox(height: 12),
                _promptField(
                  label: 'First move tomorrow',
                  controller: _tomorrowController,
                  hint: 'How do I start fast tomorrow morning?',
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Draft Shutdown Note'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2C527A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _draftShutdownNote,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _resetDay,
                      child: const Text('Reset Day'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_shutdownNote.isNotEmpty) ...<Widget>[
            const SizedBox(height: _sectionGap),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Daily Close',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _shutdownNote,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF292723),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _promptField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F4F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFDFCF8), Color(0xFFF7F4EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2DDD1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2B2A28).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _bottomBar() {
    const items = <_NavItem>[
      _NavItem(label: 'Today', icon: Icons.today_rounded),
      _NavItem(label: 'Focus', icon: Icons.bolt_rounded),
      _NavItem(label: 'Reflect', icon: Icons.nights_stay_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1D22),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF111318).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            final selected = _tabIndex == index;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _tabIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2A6E62)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 20,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFB9BAC0),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFB9BAC0),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  String _cleanSummary(String input, {required String fallback}) {
    final singleLine = input.trim().replaceAll('\n', ' ');
    if (singleLine.isEmpty) {
      return fallback;
    }
    return singleLine.endsWith('.') ? singleLine : '$singleLine.';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final marker = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $marker';
  }

  Color _activityColorForDay(int sessions, int maxSessions) {
    if (sessions <= 0 || maxSessions <= 0) {
      return const Color(0xFFE8E5DD);
    }
    final normalized = sessions / maxSessions;
    if (normalized >= 0.85) {
      return const Color(0xFF1F7A6A);
    }
    if (normalized >= 0.6) {
      return const Color(0xFF3B9B84);
    }
    if (normalized >= 0.35) {
      return const Color(0xFF74B99A);
    }
    return const Color(0xFFBBDCCB);
  }

  String _formatShortDate(DateTime dateTime) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatFullDate(DateTime dateTime) {
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _EnergyPreset {
  const _EnergyPreset({
    required this.value,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
}

class _ActivityDayLabel extends StatelessWidget {
  const _ActivityDayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF7A756B),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DailySessionActivity {
  const _DailySessionActivity({
    required this.day,
    required this.sessions,
    required this.minutes,
  });

  final DateTime day;
  final int sessions;
  final int minutes;
}
