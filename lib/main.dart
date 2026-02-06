import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FlowForgeApp());
}

class FlowForgeApp extends StatelessWidget {
  const FlowForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlowForge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F7A6A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3E8),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF1F1D19),
          displayColor: const Color(0xFF1F1D19),
        ),
      ),
      home: const FlowForgeHome(),
    );
  }
}

class SessionLog {
  const SessionLog({required this.completedAt, required this.minutes});

  final DateTime completedAt;
  final int minutes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'completed_at': completedAt.toIso8601String(),
      'minutes': minutes,
    };
  }

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final rawTime = json['completed_at'];
    final rawMinutes = json['minutes'];
    if (rawTime is! String || rawMinutes is! int) {
      throw const FormatException('Invalid log payload');
    }

    final parsed = DateTime.tryParse(rawTime);
    if (parsed == null) {
      throw const FormatException('Invalid timestamp');
    }

    return SessionLog(completedAt: parsed, minutes: rawMinutes.clamp(1, 180));
  }
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'is_done': isDone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawTitle = json['title'];
    final rawDone = json['is_done'];
    final rawCreatedAt = json['created_at'];

    if (rawId is! String ||
        rawTitle is! String ||
        rawDone is! bool ||
        rawCreatedAt is! String) {
      throw const FormatException('Invalid todo payload');
    }

    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    if (parsedCreatedAt == null) {
      throw const FormatException('Invalid todo timestamp');
    }

    return TodoItem(
      id: rawId,
      title: rawTitle,
      isDone: rawDone,
      createdAt: parsedCreatedAt,
    );
  }
}

class FlowForgeHome extends StatefulWidget {
  const FlowForgeHome({super.key});

  @override
  State<FlowForgeHome> createState() => _FlowForgeHomeState();
}

class _FlowForgeHomeState extends State<FlowForgeHome> {
  static const String _stateKey = 'flowforge_state_v1';
  static const List<int> _minutePresets = <int>[15, 25, 45, 60];

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

  int _tabIndex = 0;
  bool _isRunning = false;
  String _shutdownNote = '';
  List<SessionLog> _logs = <SessionLog>[];
  List<TodoItem> _todos = <TodoItem>[];
  Timer? _ticker;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _taskDone = List<bool>.filled(3, false);
    _energy = 68;
    _focusMinutes = 45;
    _remainingSeconds = _focusMinutes * 60;

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

    setState(() {
      final rawEnergy = payload['energy'];
      if (rawEnergy is num) {
        _energy = rawEnergy.toDouble().clamp(0, 100);
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

      final rawRemaining = payload['remaining_seconds'];
      if (rawRemaining is int &&
          rawRemaining > 0 &&
          rawRemaining <= _focusMinutes * 60) {
        _remainingSeconds = rawRemaining;
      } else {
        _remainingSeconds = _focusMinutes * 60;
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
    });
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
    return parsed.take(16).toList();
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
      'win': _winController.text,
      'friction': _frictionController.text,
      'tomorrow': _tomorrowController.text,
      'shutdown_note': _shutdownNote,
      'logs': _logs.map((log) => log.toJson()).toList(),
      'todos': _todos.map((todo) => todo.toJson()).toList(),
    };
    await prefs.setString(_stateKey, jsonEncode(payload));
  }

  void _queueSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), _saveState);
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
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleSessionComplete();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
    });
    _queueSave();
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _focusMinutes * 60;
    });
    _queueSave();
  }

  void _handleSessionComplete() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _focusMinutes * 60;
      _logs = <SessionLog>[
        SessionLog(completedAt: DateTime.now(), minutes: _focusMinutes),
        ..._logs,
      ].take(16).toList();
    });
    _queueSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session complete. Logged $_focusMinutes minutes.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setFocusMinutes(int minutes) {
    if (_isRunning || _focusMinutes == minutes) {
      return;
    }

    setState(() {
      _focusMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
    _queueSave();
  }

  void _setEnergy(double value) {
    setState(() {
      _energy = value;
    });
    _queueSave();
  }

  void _setTaskDone(int index, bool value) {
    setState(() {
      _taskDone[index] = value;
    });
    _queueSave();
  }

  void _applyEnergyRecommendation() {
    _setFocusMinutes(_recommendedFocusMinutes);
    if (!mounted || _isRunning) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Focus timer synced to $_recommendedFocusMinutes minutes.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    );

    setState(() {
      _todos = <TodoItem>[..._todos, item];
      _todoInputController.clear();
    });
    _queueSave();
  }

  void _toggleTodo(String id, bool value) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) {
      return;
    }

    setState(() {
      final updated = _todos[index].copyWith(isDone: value);
      _todos = List<TodoItem>.from(_todos)..[index] = updated;
    });
    _queueSave();
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos = _todos.where((todo) => todo.id != id).toList();
    });
    _queueSave();
  }

  void _clearCompletedTodos() {
    if (_completedTodoCount == 0) {
      return;
    }
    setState(() {
      _todos = _todos.where((todo) => !todo.isDone).toList();
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
      _energy = 68;
      _taskDone = List<bool>.filled(3, false);
      _remainingSeconds = _focusMinutes * 60;
      _logs = <SessionLog>[];
      _todos = _todos.where((todo) => !todo.isDone).toList();
      _shutdownNote = '';
      _winController.clear();
      _frictionController.clear();
      _tomorrowController.clear();
      _todoInputController.clear();
    });
    _queueSave();
  }

  int get _momentumScore {
    final completed = _taskDone.where((item) => item).length;
    final completionScore = (completed / _taskDone.length) * 40;
    final energyScore = _energy * 0.25;
    final sessions = _logs
        .where((log) => _isSameDay(log.completedAt, DateTime.now()))
        .length;
    final sessionScore = min(4, sessions) * 5;
    final todoScore = _todos.isEmpty
        ? 0
        : (_completedTodoCount / _todos.length.toDouble()) * 15;
    return max(
      0,
      min(
        100,
        (completionScore + energyScore + sessionScore + todoScore).round(),
      ),
    );
  }

  int get _recommendedFocusMinutes {
    if (_energy >= 80) {
      return 60;
    }
    if (_energy >= 60) {
      return 45;
    }
    if (_energy >= 40) {
      return 25;
    }
    return 15;
  }

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

  int get _openTodoCount => _todos.where((todo) => !todo.isDone).length;

  int get _completedTodoCount => _todos.where((todo) => todo.isDone).length;

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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 130),
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
          const SizedBox(height: 14),
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
                Slider(
                  min: 0,
                  max: 100,
                  value: _energy,
                  activeColor: const Color(0xFF1F7A6A),
                  inactiveColor: const Color(0xFFCDCECA),
                  label: _energy.round().toString(),
                  onChanged: _setEnergy,
                ),
                const SizedBox(height: 2),
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
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        key: const ValueKey<String>('energy-sync-focus'),
                        icon: const Icon(Icons.sync),
                        onPressed: _isRunning
                            ? null
                            : _applyEnergyRecommendation,
                        label: const Text('Sync Focus Timer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
                '$_openTodoCount open · ${_todos.length} total',
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
                  decoration: InputDecoration(
                    hintText: 'Add a quick todo...',
                    filled: true,
                    fillColor: const Color(0xFFF6F5F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
          if (_todos.isEmpty)
            Text(
              'Nothing captured yet. Add small tasks here so your Top Three stay clean.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5E5A54)),
            ),
          ..._todos.map(_todoRow),
          if (_completedTodoCount > 0) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearCompletedTodos,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text('Clear completed ($_completedTodoCount)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _todoRow(TodoItem todo) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: todo.isDone ? const Color(0xFFE4F3EB) : const Color(0xFFF3F1EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: todo.isDone,
            activeColor: const Color(0xFF1F7A6A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) => _toggleTodo(todo.id, value ?? false),
          ),
          Expanded(
            child: Text(
              todo.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                decoration: todo.isDone ? TextDecoration.lineThrough : null,
                color: todo.isDone ? const Color(0xFF50785F) : null,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete todo',
            onPressed: () => _deleteTodo(todo.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _focusTab() {
    final totalSeconds = _focusMinutes * 60;
    final completion = (1 - (_remainingSeconds / totalSeconds)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 130),
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
                      onPressed: _resetTimer,
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
              ],
            ),
          ),
          const SizedBox(height: 14),
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

  Widget _reflectTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 130),
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
            const SizedBox(height: 14),
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
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0DCCE)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2B2A28).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
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
