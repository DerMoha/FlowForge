import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_item.dart';
import '../models/task_energy_requirement.dart';

/// Manages tasks/todos CRUD, filtering, and sorting
class TaskState extends ChangeNotifier {
  static const List<int> estimatePresets = [10, 15, 25, 45, 60, 90];

  final TextEditingController todoInputController = TextEditingController();
  final FocusNode todoInputFocusNode = FocusNode();

  List<TodoItem> _todos = [];
  String? _focusedTodoId;
  bool _showFinishedTodos = false;
  bool _showTodoComposerDetails = false;

  TaskEnergyRequirement _newTodoEnergyRequirement = TaskEnergyRequirement.medium;
  int _newTodoEstimateMinutes = 25;
  bool _hasCustomTodoEstimate = false;

  List<TodoItem> get todos => List.unmodifiable(_todos);
  String? get focusedTodoId => _focusedTodoId;
  bool get showFinishedTodos => _showFinishedTodos;
  bool get showTodoComposerDetails => _showTodoComposerDetails;
  TaskEnergyRequirement get newTodoEnergyRequirement => _newTodoEnergyRequirement;
  int get newTodoEstimateMinutes => _newTodoEstimateMinutes;
  bool get hasCustomTodoEstimate => _hasCustomTodoEstimate;

  List<TodoItem> get openTodos =>
      _todos.where((todo) => !todo.isDone).toList(growable: false);

  List<TodoItem> get completedTodos {
    final completed = _todos.where((todo) => todo.isDone).toList(growable: false);
    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return completed;
  }

  TodoItem? get focusedTodo {
    final id = _focusedTodoId;
    if (id == null) return null;
    for (final todo in openTodos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  int get openTodoCount => _todos.where((todo) => !todo.isDone).length;
  int get completedTodoCount => _todos.where((todo) => todo.isDone).length;

  /// Initialize state
  Future<void> init() async {
    todoInputFocusNode.addListener(_handleTodoInputFocusChange);
    await _loadState();
  }

  @override
  void dispose() {
    todoInputController.dispose();
    todoInputFocusNode.removeListener(_handleTodoInputFocusChange);
    todoInputFocusNode.dispose();
    super.dispose();
  }

  /// Get sorted open todos (focused first, then by suitability)
  List<TodoItem> getSortedOpenTodos(int currentEnergy, int focusMinutes) {
    final sorted = List<TodoItem>.from(openTodos)
      ..sort((a, b) {
        final aFocused = a.id == _focusedTodoId;
        final bFocused = b.id == _focusedTodoId;
        if (aFocused && !bFocused) return -1;
        if (bFocused && !aFocused) return 1;

        final scoreCompare = _todoSuitabilityScore(a, currentEnergy, focusMinutes)
            .compareTo(_todoSuitabilityScore(b, currentEnergy, focusMinutes));
        if (scoreCompare != 0) return scoreCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
    return sorted;
  }

  /// Calculate suitability score for a task
  int _todoSuitabilityScore(TodoItem todo, int currentEnergy, int focusMinutes) {
    final energyGap = max(0, todo.energyRequirement.minEnergy - currentEnergy);
    final timeGap = max(0, todo.estimateMinutes - focusMinutes);
    return (energyGap * 2) + timeGap;
  }

  /// Check if task fits current energy
  bool isEnergyFit(TodoItem todo, int currentEnergy) {
    return currentEnergy >= todo.energyRequirement.minEnergy;
  }

  /// Check if task fits current focus block
  bool isTimeFit(TodoItem todo, int focusMinutes) {
    return focusMinutes >= todo.estimateMinutes;
  }

  /// Get constraint hint for a task
  String todoConstraintHint(TodoItem todo, int currentEnergy, int focusMinutes) {
    final energyFit = isEnergyFit(todo, currentEnergy);
    final timeFit = isTimeFit(todo, focusMinutes);

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

  /// Add a new todo
  void addTodo() {
    final text = todoInputController.text.trim();
    if (text.isEmpty) return;

    const uuid = Uuid();
    final item = TodoItem(
      id: uuid.v4(),
      title: text,
      isDone: false,
      createdAt: DateTime.now(),
      energyRequirement: _newTodoEnergyRequirement,
      estimateMinutes: _newTodoEstimateMinutes,
    );

    _todos = [..._todos, item];
    _focusedTodoId = _pickFocusedTodoId(preferredId: _focusedTodoId ?? item.id);

    todoInputController.clear();
    _hasCustomTodoEstimate = false;
    _newTodoEstimateMinutes = _estimatedTodoMinutesFor(_newTodoEnergyRequirement, 65);
    _showTodoComposerDetails = false;

    notifyListeners();
    todoInputFocusNode.unfocus();
    _saveState();
  }

  /// Toggle todo completion
  void toggleTodo(String id, bool value) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;

    final existing = _todos[index];
    if (existing.isDone == value) return;

    final updated = existing.copyWith(
      isDone: value,
      completedAt: value ? DateTime.now() : null,
      clearCompletedAt: !value,
    );

    _todos = List<TodoItem>.from(_todos)..[index] = updated;

    final preferredId = value ? (_focusedTodoId == id ? null : _focusedTodoId) : id;
    _focusedTodoId = _pickFocusedTodoId(preferredId: preferredId);

    notifyListeners();
    _saveState();
  }

  /// Delete a todo
  void deleteTodo(String id) {
    _todos = _todos.where((todo) => todo.id != id).toList();
    _focusedTodoId = _pickFocusedTodoId(
      preferredId: _focusedTodoId == id ? null : _focusedTodoId,
    );
    notifyListeners();
    _saveState();
  }

  /// Clear completed todos
  void clearCompletedTodos() {
    if (completedTodoCount == 0) return;

    _todos = _todos.where((todo) => !todo.isDone).toList();
    _focusedTodoId = _pickFocusedTodoId(preferredId: _focusedTodoId);
    _showFinishedTodos = false;

    notifyListeners();
    _saveState();
  }

  /// Set focused todo
  void setFocusedTodo(String id) {
    if (_focusedTodoId == id) return;
    if (!_todos.any((todo) => todo.id == id && !todo.isDone)) return;

    _focusedTodoId = id;
    notifyListeners();
    _saveState();
  }

  /// Toggle show finished todos
  void toggleShowFinishedTodos() {
    _showFinishedTodos = !_showFinishedTodos;
    notifyListeners();
    _saveState();
  }

  /// Todo composer methods
  void _handleTodoInputFocusChange() {
    if (todoInputFocusNode.hasFocus) {
      expandTodoComposer();
    } else {
      collapseTodoComposerIfIdle();
    }
  }

  void expandTodoComposer() {
    final suggested = _estimatedTodoMinutesFor(_newTodoEnergyRequirement, 65);
    if (_showTodoComposerDetails &&
        (_hasCustomTodoEstimate || _newTodoEstimateMinutes == suggested)) {
      return;
    }

    _showTodoComposerDetails = true;
    if (!_hasCustomTodoEstimate) {
      _newTodoEstimateMinutes = suggested;
    }
    notifyListeners();
  }

  void collapseTodoComposerIfIdle() {
    if (todoInputFocusNode.hasFocus || todoInputController.text.trim().isNotEmpty) {
      return;
    }
    if (!_showTodoComposerDetails) return;

    _showTodoComposerDetails = false;
    notifyListeners();
  }

  void setNewTodoEnergyRequirement(TaskEnergyRequirement requirement) {
    final suggested = _estimatedTodoMinutesFor(requirement, 65);
    _newTodoEnergyRequirement = requirement;
    if (!_hasCustomTodoEstimate) {
      _newTodoEstimateMinutes = suggested;
    }
    notifyListeners();
  }

  void setNewTodoEstimateMinutes(int minutes) {
    final suggested = _estimatedTodoMinutesFor(_newTodoEnergyRequirement, 65);
    _newTodoEstimateMinutes = minutes;
    _hasCustomTodoEstimate = minutes != suggested;
    notifyListeners();
  }

  void useSuggestedTodoEstimate() {
    final suggested = _estimatedTodoMinutesFor(_newTodoEnergyRequirement, 65);
    _newTodoEstimateMinutes = suggested;
    _hasCustomTodoEstimate = false;
    notifyListeners();
  }

  /// Estimate todo minutes based on requirement and current energy
  int _estimatedTodoMinutesFor(TaskEnergyRequirement requirement, int currentEnergy) {
    final baseMinutes = switch (requirement) {
      TaskEnergyRequirement.low => 15,
      TaskEnergyRequirement.medium => 25,
      TaskEnergyRequirement.high => 45,
      TaskEnergyRequirement.deep => 60,
    };

    final energyGap = max(0, requirement.minEnergy - currentEnergy);
    final adjusted = baseMinutes + ((energyGap / 20).ceil() * 10);
    return _nearestEstimatePreset(adjusted);
  }

  int _nearestEstimatePreset(int targetMinutes) {
    var closest = estimatePresets.first;
    var closestGap = (closest - targetMinutes).abs();

    for (final preset in estimatePresets.skip(1)) {
      final gap = (preset - targetMinutes).abs();
      if (gap < closestGap) {
        closest = preset;
        closestGap = gap;
      }
    }

    return closest;
  }

  /// Pick focused todo ID
  String? _pickFocusedTodoId({String? preferredId}) {
    final openList = openTodos;
    if (openList.isEmpty) return null;

    if (preferredId != null && openList.any((todo) => todo.id == preferredId)) {
      return preferredId;
    }

    // Default to first open todo
    return openList.first.id;
  }

  /// Update focused todo based on energy/timer changes
  void updateFocusedTodoIfNeeded(int currentEnergy, int focusMinutes) {
    _focusedTodoId = _pickFocusedTodoId(preferredId: _focusedTodoId);
    notifyListeners();
  }

  /// Load state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final todosJson = prefs.getStringList('task_todos') ?? [];
      _todos = todosJson.map((json) {
        try {
          // In real implementation, properly parse JSON
          return null;
        } catch (_) {
          return null;
        }
      }).whereType<TodoItem>().toList();

      _focusedTodoId = prefs.getString('task_focused_todo_id');
      _showFinishedTodos = prefs.getBool('task_show_finished_todos') ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading task state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final todosJson = _todos.map((todo) => todo.toJson().toString()).toList();
      await prefs.setStringList('task_todos', todosJson);

      if (_focusedTodoId != null) {
        await prefs.setString('task_focused_todo_id', _focusedTodoId!);
      } else {
        await prefs.remove('task_focused_todo_id');
      }

      await prefs.setBool('task_show_finished_todos', _showFinishedTodos);
    } catch (e) {
      debugPrint('Error saving task state: $e');
    }
  }
}
