import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../focus_notification_service.dart';
import '../models/daily_session_activity.dart';
import '../models/energy_preset.dart';
import '../models/session_log.dart';
import '../models/task_energy_requirement.dart';
import '../models/task_status.dart';
import '../models/todo_item.dart';
import '../utils/date_helpers.dart';
import 'persistence.dart';

class FlowForgeState extends ChangeNotifier with WidgetsBindingObserver {
  static const List<int> minutePresets = <int>[15, 25, 45, 60];
  static const List<int> todoEstimatePresets = <int>[10, 15, 25, 45, 60, 90];
  static const int activityDays = 84;

  // ---------------------------------------------------------------------------
  // Text editing controllers (owned by state, disposed here)
  // ---------------------------------------------------------------------------
  final List<TextEditingController> taskControllers =
      List<TextEditingController>.generate(3, (_) => TextEditingController());
  final TextEditingController winController = TextEditingController();
  final TextEditingController frictionController = TextEditingController();
  final TextEditingController tomorrowController = TextEditingController();
  final TextEditingController todoInputController = TextEditingController();
  final FocusNode todoInputFocusNode = FocusNode();

  // ---------------------------------------------------------------------------
  // Mutable state
  // ---------------------------------------------------------------------------
  late List<bool> taskDone;
  late double energy;
  late int focusMinutes;
  late int remainingSeconds;
  late TaskEnergyRequirement newTodoEnergyRequirement;
  late int newTodoEstimateMinutes;
  DateTime? newTodoDeadline;

  bool isRunning = false;
  bool showTodoComposerDetails = false;
  bool hasCustomTodoEstimate = false;
  int? sessionEndEpochMs;
  String? focusedTodoId;
  bool showFinishedTodos = false;
  String shutdownNote = '';
  List<SessionLog> logs = <SessionLog>[];
  List<TodoItem> todos = <TodoItem>[];
  DateTime? lastResetDate;
  Timer? _ticker;
  Timer? _saveDebounce;
  int? _lastSessionNotificationBucket;

  /// Set by the host widget so state can request snackbars without a BuildContext.
  String? pendingSnackMessage;

  /// Optional callback the scaffold registers to receive snack messages.
  VoidCallback? onShowSnack;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  void init() {
    WidgetsBinding.instance.addObserver(this);
    taskDone = List<bool>.filled(3, false);
    energy = 65;
    focusMinutes = 45;
    remainingSeconds = focusMinutes * 60;
    newTodoEnergyRequirement = TaskEnergyRequirement.medium;
    newTodoEstimateMinutes = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    todoInputFocusNode.addListener(_handleTodoInputFocusChange);

    const defaults = <String>[
      'Ship the hardest task first',
      'Protect one no-meeting focus block',
      'Write a clean shutdown note',
    ];

    for (var i = 0; i < taskControllers.length; i++) {
      taskControllers[i].text = defaults[i];
      taskControllers[i].addListener(queueSave);
    }
    winController.addListener(queueSave);
    frictionController.addListener(queueSave);
    tomorrowController.addListener(queueSave);

    unawaited(FocusNotificationService.instance.initialize());
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _saveDebounce?.cancel();
    for (final controller in taskControllers) {
      controller.dispose();
    }
    winController.dispose();
    frictionController.dispose();
    tomorrowController.dispose();
    todoInputController.dispose();
    todoInputFocusNode.removeListener(_handleTodoInputFocusChange);
    todoInputFocusNode.dispose();
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
      queueSave();
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------
  Future<void> _loadState() async {
    final payload = await FlowForgeStorage.loadRaw();
    if (payload == null) {
      return;
    }

    var completedWhileAway = false;

    final rawEnergy = payload['energy'];
    if (rawEnergy is num) {
      energy = _snapEnergy(rawEnergy.toDouble());
    }

    final taskTexts = payload['task_texts'];
    if (taskTexts is List) {
      for (var i = 0; i < taskControllers.length && i < taskTexts.length; i++) {
        final value = taskTexts[i];
        if (value is String && value.trim().isNotEmpty) {
          taskControllers[i].text = value;
        }
      }
    }

    final rawDone = payload['task_done'];
    if (rawDone is List) {
      for (var i = 0; i < taskDone.length && i < rawDone.length; i++) {
        final value = rawDone[i];
        if (value is bool) {
          taskDone[i] = value;
        }
      }
    }

    final rawFocus = payload['focus_minutes'];
    if (rawFocus is int && minutePresets.contains(rawFocus)) {
      focusMinutes = rawFocus;
    }
    final fullSessionSeconds = focusMinutes * 60;

    final rawRemaining = payload['remaining_seconds'];
    if (rawRemaining is int &&
        rawRemaining > 0 &&
        rawRemaining <= fullSessionSeconds) {
      remainingSeconds = rawRemaining;
    } else {
      remainingSeconds = fullSessionSeconds;
    }

    final rawWin = payload['win'];
    if (rawWin is String) {
      winController.text = rawWin;
    }
    final rawFriction = payload['friction'];
    if (rawFriction is String) {
      frictionController.text = rawFriction;
    }
    final rawTomorrow = payload['tomorrow'];
    if (rawTomorrow is String) {
      tomorrowController.text = rawTomorrow;
    }
    final rawNote = payload['shutdown_note'];
    if (rawNote is String) {
      shutdownNote = rawNote;
    }

    logs = FlowForgeStorage.decodeLogs(payload['logs']);
    todos = FlowForgeStorage.decodeTodos(payload['todos']);
    showFinishedTodos = payload['show_finished_todos'] == true;

    final rawLastReset = payload['last_reset_date'];
    if (rawLastReset is String) {
      lastResetDate = DateTime.tryParse(rawLastReset);
    }
    // Reset today tasks if it's a new day
    _resetTodayTasksIfNewDay();

    final savedFocusTodoId = payload['focused_todo_id'];
    focusedTodoId = pickFocusedTodoId(
      todos,
      preferredId: savedFocusTodoId is String ? savedFocusTodoId : null,
    );

    isRunning = payload['is_running'] == true;
    final rawSessionEndEpochMs = payload['session_end_epoch_ms'];
    sessionEndEpochMs = rawSessionEndEpochMs is int
        ? rawSessionEndEpochMs
        : null;

    if (isRunning && sessionEndEpochMs != null) {
      final remainingFromDeadline =
          ((sessionEndEpochMs! - DateTime.now().millisecondsSinceEpoch) / 1000)
              .ceil();
      if (remainingFromDeadline > 0) {
        remainingSeconds = min(fullSessionSeconds, remainingFromDeadline);
      } else {
        isRunning = false;
        sessionEndEpochMs = null;
        remainingSeconds = fullSessionSeconds;
        logs = <SessionLog>[
          SessionLog(completedAt: DateTime.now(), minutes: focusMinutes),
          ...logs,
        ].take(FlowForgeStorage.maxSessionLogs).toList();
        completedWhileAway = true;
      }
    } else {
      isRunning = false;
      sessionEndEpochMs = null;
    }

    notifyListeners();

    _ensureTickerRunning();
    if (isRunning) {
      _syncFocusSessionNotification(force: true);
    } else {
      _clearFocusSessionNotification();
    }

    if (completedWhileAway) {
      queueSave();
      _emitSnack('Focus session finished while you were away. Session logged.');
    }
  }

  Future<void> _saveState() async {
    final payload = <String, dynamic>{
      'energy': energy,
      'task_texts': taskControllers
          .map((controller) => controller.text)
          .toList(),
      'task_done': taskDone,
      'focus_minutes': focusMinutes,
      'remaining_seconds': remainingSeconds,
      'is_running': isRunning,
      'session_end_epoch_ms': sessionEndEpochMs,
      'win': winController.text,
      'friction': frictionController.text,
      'tomorrow': tomorrowController.text,
      'shutdown_note': shutdownNote,
      'focused_todo_id': focusedTodoId,
      'show_finished_todos': showFinishedTodos,
      'logs': logs.map((log) => log.toJson()).toList(),
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'last_reset_date': lastResetDate?.toIso8601String(),
    };
    await FlowForgeStorage.saveRaw(payload);
  }

  void queueSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _saveState);
  }

  void _emitSnack(String message) {
    pendingSnackMessage = message;
    notifyListeners();
    onShowSnack?.call();
  }

  void consumeSnack() {
    pendingSnackMessage = null;
  }

  // ---------------------------------------------------------------------------
  // Notification helpers
  // ---------------------------------------------------------------------------
  int _sessionNotificationBucket(int remaining) {
    if (remaining <= 60) {
      return remaining ~/ 10;
    }
    return remaining ~/ 60;
  }

  void _syncFocusSessionNotification({bool force = false}) {
    if (!isRunning) {
      return;
    }

    final bucket = _sessionNotificationBucket(remainingSeconds);
    if (!force && _lastSessionNotificationBucket == bucket) {
      return;
    }

    _lastSessionNotificationBucket = bucket;
    unawaited(
      FocusNotificationService.instance.showActiveSession(
        remainingSeconds: remainingSeconds,
        focusMinutes: focusMinutes,
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
        focusMinutes: focusMinutes,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------
  void toggleTimer() {
    if (isRunning) {
      _pauseTimer();
      return;
    }
    _startTimer();
  }

  void _startTimer() {
    if (isRunning) {
      return;
    }

    if (remainingSeconds <= 0) {
      remainingSeconds = focusMinutes * 60;
    }

    isRunning = true;
    sessionEndEpochMs =
        DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000);
    notifyListeners();
    _ensureTickerRunning();
    _syncFocusSessionNotification(force: true);
    queueSave();
  }

  void _ensureTickerRunning() {
    _ticker?.cancel();
    if (!isRunning) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRunning) {
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
    if (!isRunning) {
      return false;
    }

    final endEpochMs = sessionEndEpochMs;
    if (endEpochMs == null) {
      isRunning = false;
      remainingSeconds = focusMinutes * 60;
      notifyListeners();
      _clearFocusSessionNotification();
      queueSave();
      return false;
    }

    final fullSessionSeconds = focusMinutes * 60;
    final remaining =
        ((endEpochMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remaining <= 0) {
      _handleSessionComplete(fromResume: isAppResume);
      return true;
    }

    final clamped = min(fullSessionSeconds, remaining);
    if (remainingSeconds != clamped) {
      remainingSeconds = clamped;
      notifyListeners();
    }
    _syncFocusSessionNotification();

    return false;
  }

  void _pauseTimer() {
    if (!isRunning) {
      return;
    }

    final endEpochMs = sessionEndEpochMs;
    var pausedRemaining = remainingSeconds;
    if (endEpochMs != null) {
      final fromDeadline =
          ((endEpochMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (fromDeadline <= 0) {
        _handleSessionComplete();
        return;
      }
      pausedRemaining = min(focusMinutes * 60, fromDeadline);
    }

    _ticker?.cancel();
    isRunning = false;
    sessionEndEpochMs = null;
    remainingSeconds = pausedRemaining;
    notifyListeners();
    _clearFocusSessionNotification();
    queueSave();
  }

  void resetTimer() {
    _ticker?.cancel();
    isRunning = false;
    sessionEndEpochMs = null;
    remainingSeconds = focusMinutes * 60;
    notifyListeners();
    _clearFocusSessionNotification();
    queueSave();
  }

  void _handleSessionComplete({bool fromResume = false}) {
    _ticker?.cancel();
    isRunning = false;
    sessionEndEpochMs = null;
    remainingSeconds = focusMinutes * 60;
    logs = <SessionLog>[
      SessionLog(completedAt: DateTime.now(), minutes: focusMinutes),
      ...logs,
    ].take(FlowForgeStorage.maxSessionLogs).toList();
    notifyListeners();
    _clearFocusSessionNotification();
    _showFocusSessionCompleteNotification();
    queueSave();

    _emitSnack(
      fromResume
          ? 'Session completed while you were away. Logged $focusMinutes minutes.'
          : 'Session complete. Logged $focusMinutes minutes.',
    );
  }

  // ---------------------------------------------------------------------------
  // Energy
  // ---------------------------------------------------------------------------
  void setFocusMinutes(int minutes) {
    if (isRunning || focusMinutes == minutes) {
      return;
    }

    focusMinutes = minutes;
    remainingSeconds = minutes * 60;
    focusedTodoId = pickFocusedTodoId(todos, preferredId: focusedTodoId);
    notifyListeners();
    queueSave();
  }

  void setEnergy(double value) {
    final snapped = _snapEnergy(value);
    final recommendedFocus = _recommendedFocusMinutesFor(snapped);
    final shouldAutoSyncFocus = !isRunning && focusMinutes != recommendedFocus;
    final energyChanged = energy != snapped;
    if (!energyChanged && !shouldAutoSyncFocus) {
      return;
    }

    energy = snapped;
    if (shouldAutoSyncFocus) {
      focusMinutes = recommendedFocus;
      remainingSeconds = recommendedFocus * 60;
    }
    if (!hasCustomTodoEstimate) {
      newTodoEstimateMinutes = estimatedTodoMinutesFor(
        newTodoEnergyRequirement,
      );
    }
    focusedTodoId = pickFocusedTodoId(todos, preferredId: focusedTodoId);
    notifyListeners();
    queueSave();
  }

  void setEnergyPreset(EnergyPreset preset) {
    setEnergy(preset.value.toDouble());
  }

  double _snapEnergy(double value) {
    return closestEnergyPreset(value).value.toDouble();
  }

  EnergyPreset closestEnergyPreset(double value) {
    var closest = energyPresets.first;
    var closestDistance = (closest.value - value).abs();
    for (final preset in energyPresets.skip(1)) {
      final distance = (preset.value - value).abs();
      if (distance < closestDistance) {
        closest = preset;
        closestDistance = distance;
      }
    }
    return closest;
  }

  EnergyPreset get activeEnergyPreset => closestEnergyPreset(energy);

  int _recommendedFocusMinutesFor(double e) {
    if (e >= 80) return 60;
    if (e >= 60) return 45;
    if (e >= 40) return 25;
    return 15;
  }

  int get recommendedFocusMinutes => _recommendedFocusMinutesFor(energy);

  int get currentEnergyScore => energy.round();

  // ---------------------------------------------------------------------------
  // Todo composer
  // ---------------------------------------------------------------------------
  void _handleTodoInputFocusChange() {
    if (todoInputFocusNode.hasFocus) {
      expandTodoComposer();
      return;
    }
    collapseTodoComposerIfIdle();
  }

  void expandTodoComposer() {
    final suggested = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    if (showTodoComposerDetails &&
        (hasCustomTodoEstimate || newTodoEstimateMinutes == suggested)) {
      return;
    }

    showTodoComposerDetails = true;
    if (!hasCustomTodoEstimate) {
      newTodoEstimateMinutes = suggested;
    }
    notifyListeners();
  }

  void collapseTodoComposerIfIdle() {
    if (todoInputFocusNode.hasFocus ||
        todoInputController.text.trim().isNotEmpty) {
      return;
    }
    if (!showTodoComposerDetails) {
      return;
    }
    showTodoComposerDetails = false;
    notifyListeners();
  }

  int estimatedTodoMinutesFor(TaskEnergyRequirement requirement) {
    final baseMinutes = switch (requirement) {
      TaskEnergyRequirement.low => 15,
      TaskEnergyRequirement.medium => 25,
      TaskEnergyRequirement.high => 45,
      TaskEnergyRequirement.deep => 60,
    };
    final energyGap = max(0, requirement.minEnergy - currentEnergyScore);
    final adjusted = baseMinutes + ((energyGap / 20).ceil() * 10);
    return _nearestTodoEstimatePreset(adjusted);
  }

  int _nearestTodoEstimatePreset(int targetMinutes) {
    var closest = todoEstimatePresets.first;
    var closestGap = (closest - targetMinutes).abs();
    for (final preset in todoEstimatePresets.skip(1)) {
      final gap = (preset - targetMinutes).abs();
      if (gap < closestGap) {
        closest = preset;
        closestGap = gap;
      }
    }
    return closest;
  }

  void setNewTodoEnergyRequirement(TaskEnergyRequirement requirement) {
    final suggested = estimatedTodoMinutesFor(requirement);
    newTodoEnergyRequirement = requirement;
    if (!hasCustomTodoEstimate) {
      newTodoEstimateMinutes = suggested;
    }
    notifyListeners();
  }

  void setNewTodoEstimateMinutes(int minutes) {
    final suggested = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    newTodoEstimateMinutes = minutes;
    hasCustomTodoEstimate = minutes != suggested;
    notifyListeners();
  }

  void useSuggestedTodoEstimate() {
    final suggested = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    newTodoEstimateMinutes = suggested;
    hasCustomTodoEstimate = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Todos
  // ---------------------------------------------------------------------------
  void addTodo() {
    final text = todoInputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final item = TodoItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      title: text,
      isDone: false,
      createdAt: DateTime.now(),
      energyRequirement: newTodoEnergyRequirement,
      estimateMinutes: newTodoEstimateMinutes,
      status: TaskStatus.backlog,
      deadline: newTodoDeadline,
    );

    final updatedTodos = <TodoItem>[...todos, item];
    todos = updatedTodos;
    focusedTodoId = pickFocusedTodoId(
      updatedTodos,
      preferredId: focusedTodoId ?? item.id,
    );
    todoInputController.clear();
    hasCustomTodoEstimate = false;
    newTodoEstimateMinutes = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    newTodoDeadline = null;
    showTodoComposerDetails = false;
    notifyListeners();
    todoInputFocusNode.unfocus();
    queueSave();
  }

  void setNewTodoDeadline(DateTime? deadline) {
    newTodoDeadline = deadline;
    notifyListeners();
  }

  void clearNewTodoDeadline() {
    newTodoDeadline = null;
    notifyListeners();
  }

  void setFocusedTodo(String id) {
    if (focusedTodoId == id) {
      return;
    }
    if (!todos.any((todo) => todo.id == id && !todo.isDone)) {
      return;
    }

    focusedTodoId = id;
    notifyListeners();
    queueSave();
  }

  void toggleTodo(String id, bool value) {
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index < 0) {
      return;
    }

    final existing = todos[index];
    if (existing.isDone == value) {
      return;
    }

    final updated = existing.copyWith(isDone: value);
    final updatedTodos = List<TodoItem>.from(todos)..[index] = updated;
    todos = updatedTodos;

    final preferredId = value
        ? (focusedTodoId == id ? null : focusedTodoId)
        : id;
    focusedTodoId = pickFocusedTodoId(updatedTodos, preferredId: preferredId);
    notifyListeners();
    queueSave();
  }

  void deleteTodo(String id) {
    final updatedTodos = todos.where((todo) => todo.id != id).toList();
    todos = updatedTodos;
    focusedTodoId = pickFocusedTodoId(
      updatedTodos,
      preferredId: focusedTodoId == id ? null : focusedTodoId,
    );
    notifyListeners();
    queueSave();
  }

  void clearCompletedTodos() {
    if (completedTodoCount == 0) {
      return;
    }
    final updatedTodos = todos.where((todo) => !todo.isDone).toList();
    todos = updatedTodos;
    focusedTodoId = pickFocusedTodoId(updatedTodos, preferredId: focusedTodoId);
    showFinishedTodos = false;
    notifyListeners();
    queueSave();
  }

  void toggleShowFinishedTodos() {
    showFinishedTodos = !showFinishedTodos;
    notifyListeners();
    queueSave();
  }

  // ---------------------------------------------------------------------------
  // Kanban task status management
  // ---------------------------------------------------------------------------
  void addTodoFromKanban({
    required String title,
    required TaskEnergyRequirement energyRequirement,
    required int estimateMinutes,
    DateTime? deadline,
  }) {
    final item = TodoItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      title: title,
      isDone: false,
      createdAt: DateTime.now(),
      energyRequirement: energyRequirement,
      estimateMinutes: estimateMinutes,
      status: TaskStatus.backlog,
      deadline: deadline,
    );

    todos = <TodoItem>[...todos, item];
    focusedTodoId = pickFocusedTodoId(
      todos,
      preferredId: focusedTodoId ?? item.id,
    );
    notifyListeners();
    queueSave();
  }

  void updateTodo({
    required String id,
    required String title,
    required TaskEnergyRequirement energyRequirement,
    required int estimateMinutes,
    required TaskStatus status,
    DateTime? deadline,
  }) {
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;

    final existing = todos[index];
    final updated = existing.copyWith(
      title: title,
      energyRequirement: energyRequirement,
      estimateMinutes: estimateMinutes,
      status: status,
      deadline: deadline,
      isDone: status == TaskStatus.done,
    );

    todos = List<TodoItem>.from(todos)..[index] = updated;
    focusedTodoId = pickFocusedTodoId(todos, preferredId: focusedTodoId);
    notifyListeners();
    queueSave();
  }

  void moveTaskToStatus(String taskId, TaskStatus newStatus) {
    final index = todos.indexWhere((todo) => todo.id == taskId);
    if (index < 0) return;

    final existing = todos[index];
    if (existing.status == newStatus) return;

    final updated = existing.copyWith(status: newStatus);
    final updatedTodos = List<TodoItem>.from(todos)..[index] = updated;
    todos = updatedTodos;

    // If moving to done, also mark isDone
    if (newStatus == TaskStatus.done && !existing.isDone) {
      todos = todos
          .map((t) => t.id == taskId ? t.copyWith(isDone: true) : t)
          .toList();
    }
    // If moving away from done, unmark isDone
    if (newStatus != TaskStatus.done && existing.isDone) {
      todos = todos
          .map((t) => t.id == taskId ? t.copyWith(isDone: false) : t)
          .toList();
    }

    focusedTodoId = pickFocusedTodoId(todos, preferredId: focusedTodoId);
    notifyListeners();
    queueSave();
  }

  List<TodoItem> get todayTodos => todos
      .where((todo) => todo.status == TaskStatus.today && !todo.isDone)
      .toList();

  List<TodoItem> get backlogTodos => todos
      .where((todo) => todo.status == TaskStatus.backlog && !todo.isDone)
      .toList();

  List<TodoItem> get doneTodos => todos
      .where((todo) => todo.isDone || todo.status == TaskStatus.done)
      .toList();

  int get todayTodoCount => todayTodos.length;

  void _resetTodayTasksIfNewDay() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    if (lastResetDate == null || !isSameDay(lastResetDate!, today)) {
      // Move all 'today' tasks back to 'backlog'
      todos = todos.map((todo) {
        if (todo.status == TaskStatus.today && !todo.isDone) {
          return todo.copyWith(status: TaskStatus.backlog);
        }
        return todo;
      }).toList();
      lastResetDate = todayStart;
      queueSave();
    }
  }

  // ---------------------------------------------------------------------------
  // Suitability scoring and focused-todo picking
  // ---------------------------------------------------------------------------
  String? pickFocusedTodoId(List<TodoItem> todoList, {String? preferredId}) {
    final openTodoList = todoList.where((todo) => !todo.isDone).toList();
    if (openTodoList.isEmpty) {
      return null;
    }

    if (preferredId != null &&
        openTodoList.any((todo) => todo.id == preferredId)) {
      return preferredId;
    }

    openTodoList.sort((a, b) {
      final scoreCompare = todoSuitabilityScore(
        a,
      ).compareTo(todoSuitabilityScore(b));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return openTodoList.first.id;
  }

  int todoSuitabilityScore(TodoItem todo) {
    final energyGap = max(
      0,
      todo.energyRequirement.minEnergy - currentEnergyScore,
    );
    final timeGap = max(0, todo.estimateMinutes - focusMinutes);
    return (energyGap * 2) + timeGap;
  }

  bool isEnergyFit(TodoItem todo) {
    return currentEnergyScore >= todo.energyRequirement.minEnergy;
  }

  bool isTimeFit(TodoItem todo) {
    return focusMinutes >= todo.estimateMinutes;
  }

  String todoConstraintHint(TodoItem todo) {
    final energyFit = isEnergyFit(todo);
    final timeFit = isTimeFit(todo);
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

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------
  List<TodoItem> get openTodos =>
      todos.where((todo) => !todo.isDone).toList(growable: false);

  List<TodoItem> get completedTodos {
    final completed = todos
        .where((todo) => todo.isDone)
        .toList(growable: false);
    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return completed;
  }

  TodoItem? get focusedTodo {
    final id = focusedTodoId;
    if (id == null) return null;
    for (final todo in openTodos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  List<TodoItem> get sortedOpenTodos {
    final sorted = List<TodoItem>.from(openTodos)
      ..sort((a, b) {
        final aFocused = a.id == focusedTodoId;
        final bFocused = b.id == focusedTodoId;
        if (aFocused && !bFocused) return -1;
        if (bFocused && !aFocused) return 1;

        final scoreCompare = todoSuitabilityScore(
          a,
        ).compareTo(todoSuitabilityScore(b));
        if (scoreCompare != 0) return scoreCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
    return sorted;
  }

  int get openTodoCount => todos.where((todo) => !todo.isDone).length;

  int get completedTodoCount => todos.where((todo) => todo.isDone).length;

  bool get hasFocusProgress =>
      isRunning || remainingSeconds != focusMinutes * 60;

  // ---------------------------------------------------------------------------
  // Momentum
  // ---------------------------------------------------------------------------
  int get momentumScore {
    final totalTodos = todos.length;
    final completionScore = totalTodos == 0
        ? 0
        : (completedTodoCount / totalTodos) * 40;
    final energyScore = energy * 0.25;
    final sessions = logs
        .where((log) => isSameDay(log.completedAt, DateTime.now()))
        .length;
    final sessionScore = min(4, sessions) * 5;
    final totalTodoEffort = todos.fold<int>(
      0,
      (sum, todo) => sum + todo.estimateMinutes,
    );
    final completedTodoEffort = todos
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

  // ---------------------------------------------------------------------------
  // Activity
  // ---------------------------------------------------------------------------
  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  List<DailySessionActivity> get activitySeries {
    final today = _startOfDay(DateTime.now());
    final oldestDay = today.subtract(const Duration(days: activityDays - 1));
    final byDay = <DateTime, DailySessionActivity>{};

    for (final log in logs) {
      final day = _startOfDay(log.completedAt);
      if (day.isBefore(oldestDay) || day.isAfter(today)) {
        continue;
      }
      final current = byDay[day];
      if (current == null) {
        byDay[day] = DailySessionActivity(
          day: day,
          sessions: 1,
          minutes: log.minutes,
        );
      } else {
        byDay[day] = DailySessionActivity(
          day: day,
          sessions: current.sessions + 1,
          minutes: current.minutes + log.minutes,
        );
      }
    }

    return List<DailySessionActivity>.generate(activityDays, (index) {
      final day = oldestDay.add(Duration(days: index));
      return byDay[day] ??
          DailySessionActivity(day: day, sessions: 0, minutes: 0);
    });
  }

  int get sessionsThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return logs.where((log) => !log.completedAt.isBefore(start)).length;
  }

  int get minutesThisWeek {
    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    return logs
        .where((log) => !log.completedAt.isBefore(start))
        .fold<int>(0, (sum, log) => sum + log.minutes);
  }

  // ---------------------------------------------------------------------------
  // Reflect / shutdown
  // ---------------------------------------------------------------------------
  void draftShutdownNote() {
    final sessionsToday = logs
        .where((log) => isSameDay(log.completedAt, DateTime.now()))
        .length;
    final todosClosed = completedTodoCount;
    final openCount = openTodoCount;
    final win = cleanSummary(
      winController.text,
      fallback: 'Made progress where it mattered.',
    );
    final friction = cleanSummary(
      frictionController.text,
      fallback: 'Context switching diluted focus at points.',
    );
    final tomorrow = cleanSummary(
      tomorrowController.text,
      fallback: 'Begin with the hardest open loop.',
    );

    shutdownNote =
        'Closed $todosClosed todo ${todosClosed == 1 ? 'item' : 'items'} and logged '
        '$sessionsToday focus ${sessionsToday == 1 ? 'session' : 'sessions'}, '
        'with $openCount ${openCount == 1 ? 'item' : 'items'} still open. '
        'Win: $win Friction: $friction Tomorrow first move: $tomorrow';
    notifyListeners();
    queueSave();
  }

  void resetDay() {
    _ticker?.cancel();
    _clearFocusSessionNotification();
    isRunning = false;
    sessionEndEpochMs = null;
    energy = 65;
    taskDone = List<bool>.filled(3, false);
    remainingSeconds = focusMinutes * 60;
    logs = <SessionLog>[];
    final openOnly = todos.where((todo) => !todo.isDone).toList();
    todos = openOnly;
    focusedTodoId = pickFocusedTodoId(openOnly, preferredId: focusedTodoId);
    showFinishedTodos = false;
    shutdownNote = '';
    winController.clear();
    frictionController.clear();
    tomorrowController.clear();
    todoInputController.clear();
    showTodoComposerDetails = false;
    newTodoEnergyRequirement = TaskEnergyRequirement.medium;
    hasCustomTodoEstimate = false;
    newTodoEstimateMinutes = estimatedTodoMinutesFor(newTodoEnergyRequirement);
    newTodoDeadline = null;
    notifyListeners();
    todoInputFocusNode.unfocus();
    queueSave();
  }
}
