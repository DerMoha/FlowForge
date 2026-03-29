import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/ai_repository.dart';
import '../data/repositories/practice_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../models/conversation.dart';
import '../models/enums.dart';
import '../models/practice.dart';
import '../services/ai/ai_provider.dart';
import '../services/ai/api_key_store.dart';
import '../services/ai/openai_provider.dart';
import '../services/ai/practice_prompts.dart';

class PracticeState extends ChangeNotifier {
  PracticeState({
    required PracticeRepository practiceRepository,
    required AiRepository aiRepository,
    required ProgressRepository progressRepository,
    required ApiKeyStore apiKeyStore,
  })  : _practiceRepo = practiceRepository,
        _aiRepo = aiRepository,
        _progressRepo = progressRepository,
        _keyStore = apiKeyStore {
    loadAllSessions();
  }

  final PracticeRepository _practiceRepo;
  final AiRepository _aiRepo;
  final ProgressRepository _progressRepo;
  final ApiKeyStore _keyStore;

  final Map<String, AiProvider> _providers = {
    'openai': OpenAiProvider(),
    'openrouter': OpenAiProvider(providerId: 'openrouter'),
  };

  // Session stack: index 0 = root, last = currently active
  List<PracticeSession> _sessionStack = [];

  // Cells for the currently active session
  List<PracticeCell> _cells = [];

  // Conversation messages for AI context
  List<AiMessage> _conversationMessages = [];

  // Task metadata for the active session
  GeneratedTask? _activeTask;

  // Live text in the work cell (not yet saved)
  String _currentWork = '';
  String? _workCellId;

  // All root sessions (for list view)
  List<PracticeSession> _allSessions = [];

  // Debounce
  Timer? _debounceTimer;
  DateTime? _lastEvaluationTime;
  static const _debounceDuration = Duration(seconds: 3);
  static const _minEvalInterval = Duration(seconds: 5);
  static const _minWorkLength = 10;

  // AI state
  bool _isGeneratingTask = false;
  bool _isEvaluating = false;
  String? _error;

  // Getters
  PracticeSession? get activeSession =>
      _sessionStack.isNotEmpty ? _sessionStack.last : null;
  PracticeSession? get rootSession =>
      _sessionStack.isNotEmpty ? _sessionStack.first : null;
  List<PracticeSession> get breadcrumbs => List.unmodifiable(_sessionStack);
  int get nestingDepth => _sessionStack.length - 1;
  bool get hasActiveSession => _sessionStack.isNotEmpty;

  List<PracticeCell> get cells => List.unmodifiable(_cells);
  List<PracticeSession> get allSessions => List.unmodifiable(_allSessions);
  GeneratedTask? get activeTask => _activeTask;
  String get currentWork => _currentWork;

  bool get isGeneratingTask => _isGeneratingTask;
  bool get isEvaluating => _isEvaluating;
  bool get isBusy => _isGeneratingTask || _isEvaluating;
  String? get error => _error;

  // ── Public API ──

  Future<void> loadAllSessions() async {
    _allSessions = await _practiceRepo.getRootSessions();
    notifyListeners();
  }

  /// Start a fresh practice session on the given topic.
  Future<void> startSession({
    required String topic,
    PracticeSourceType? sourceType,
    String? sourceId,
    String? contextContent,
  }) async {
    _error = null;
    _sessionStack = [];
    _cells = [];
    _conversationMessages = [];
    _activeTask = null;
    _currentWork = '';
    _workCellId = null;
    notifyListeners();

    // Create conversation
    final conversation = await _aiRepo.getOrCreateConversation(
      targetType: ConversationTargetType.practice,
      targetId: 'pending', // will update after session created
    );

    // Create session
    final session = await _practiceRepo.createSession(
      topic: topic,
      sourceType: sourceType,
      sourceId: sourceId,
      conversationId: conversation.id,
      depth: 0,
    );

    _sessionStack = [session];
    notifyListeners();

    await _generateTask(contextContent: contextContent);
    await loadAllSessions();
  }

  /// Resume a previously started session (and its ancestor stack).
  Future<void> loadSession(String sessionId) async {
    _error = null;
    _sessionStack = await _practiceRepo.getAncestors(sessionId);
    if (_sessionStack.isEmpty) return;

    await _loadActiveCells();
    notifyListeners();
  }

  /// Called every time the user types in the work cell.
  void onWorkChanged(String text) {
    _currentWork = text;
    _debounceTimer?.cancel();
    if (text.length >= _minWorkLength) {
      _debounceTimer = Timer(_debounceDuration, _evaluateWork);
    }
    notifyListeners();
  }

  /// Explicit "Check My Work" button.
  Future<void> checkWork() async {
    _debounceTimer?.cancel();
    await _evaluateWork();
  }

  /// Accept a sub-task suggestion from the AI.
  Future<void> acceptSubtask(String subtaskTopic) async {
    final current = activeSession;
    if (current == null) return;
    if (nestingDepth >= 3) return; // max depth guard

    _error = null;

    // Mark current session as subtask active
    await _practiceRepo.updateSessionStatus(
        current.id, PracticeSessionStatus.subtaskActive);
    _sessionStack[_sessionStack.length - 1] =
        current.copyWith(status: PracticeSessionStatus.subtaskActive);

    // Create new conversation for sub-session
    final conversation = await _aiRepo.getOrCreateConversation(
      targetType: ConversationTargetType.practice,
      targetId: '${current.id}_sub_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Create sub-session
    final subSession = await _practiceRepo.createSession(
      topic: subtaskTopic,
      parentSessionId: current.id,
      conversationId: conversation.id,
      depth: nestingDepth + 1,
    );

    _sessionStack.add(subSession);
    _cells = [];
    _conversationMessages = [];
    _activeTask = null;
    _currentWork = '';
    _workCellId = null;
    notifyListeners();

    await _generateTask(parentTopic: current.topic);
  }

  /// Complete the current session and pop to the parent (if nested).
  Future<void> completeSession() async {
    final current = activeSession;
    if (current == null) return;

    final now = DateTime.now();
    await _practiceRepo.updateSessionStatus(
      current.id,
      PracticeSessionStatus.completed,
      completedAt: now,
    );

    // Update topic mastery
    try {
      await _progressRepo.upsertMastery(
        topic: current.topic,
        confidenceScore: 1.0,
        evidenceCount: 1,
      );
    } catch (_) {
      // Progress update is best-effort
    }

    if (_sessionStack.length > 1) {
      // Pop sub-session, return to parent
      _sessionStack.removeLast();
      final parent = _sessionStack.last;

      // Update parent status back to inProgress
      await _practiceRepo.updateSessionStatus(
          parent.id, PracticeSessionStatus.inProgress);
      _sessionStack[_sessionStack.length - 1] =
          parent.copyWith(status: PracticeSessionStatus.inProgress);

      // Load parent cells
      await _loadActiveCells();

      // Generate bridge message
      if (_activeTask != null) {
        await _generateBridgeMessage(
          parentTask: _activeTask!.task,
          subtaskTopic: current.topic,
        );
      }
    } else {
      // Root session complete
      _sessionStack[0] =
          current.copyWith(status: PracticeSessionStatus.completed);
      await loadAllSessions();
    }

    notifyListeners();
  }

  /// Abandon the entire session stack.
  Future<void> abandonSession() async {
    for (final session in _sessionStack) {
      await _practiceRepo.updateSessionStatus(
          session.id, PracticeSessionStatus.abandoned);
    }
    _sessionStack = [];
    _cells = [];
    _conversationMessages = [];
    _activeTask = null;
    _currentWork = '';
    _workCellId = null;
    await loadAllSessions();
    notifyListeners();
  }

  /// Close the workspace without abandoning (session stays in-progress).
  void closeWorkspace() {
    _debounceTimer?.cancel();
    _sessionStack = [];
    _cells = [];
    _conversationMessages = [];
    _activeTask = null;
    _currentWork = '';
    _workCellId = null;
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ──

  Future<void> _generateTask({
    String? contextContent,
    String? parentTopic,
  }) async {
    final session = activeSession;
    if (session == null) return;

    _isGeneratingTask = true;
    _error = null;
    await _practiceRepo.updateSessionStatus(
        session.id, PracticeSessionStatus.awaitingTask);
    notifyListeners();

    try {
      final provider = await _getActiveProvider();
      final config = await _getRuntimeConfig();

      final request = PracticePrompts.taskGenerationRequest(
        topic: session.topic,
        parentTopic: parentTopic,
        contextContent: contextContent,
        depth: session.depth,
      );

      final raw = await provider.complete(config, request);
      final generated = PracticePrompts.parseTaskResponse(raw);
      _activeTask = generated;

      // Persist conversation messages for AI context
      if (session.conversationId != null) {
        if (request.systemPrompt != null) {
          await _aiRepo.addMessage(
            conversationId: session.conversationId!,
            role: MessageRole.system,
            content: request.systemPrompt!,
          );
        }
        await _aiRepo.addMessage(
          conversationId: session.conversationId!,
          role: MessageRole.assistant,
          content: raw,
        );
      }

      // Save task cell
      final taskCellIndex = _cells.length;
      final taskCell = await _practiceRepo.addCell(
        sessionId: session.id,
        cellIndex: taskCellIndex,
        cellType: PracticeCellType.task,
        content: generated.task,
        metadata: {
          'difficulty': generated.difficulty,
          'expected_concepts': generated.expectedConcepts,
        },
      );

      // Save empty work cell
      final workCellIndex = taskCellIndex + 1;
      final workCell = await _practiceRepo.addCell(
        sessionId: session.id,
        cellIndex: workCellIndex,
        cellType: PracticeCellType.work,
        content: '',
      );
      _workCellId = workCell.id;

      _cells = [..._cells, taskCell, workCell];

      await _practiceRepo.updateSessionStatus(
          session.id, PracticeSessionStatus.inProgress);
      _sessionStack[_sessionStack.length - 1] =
          session.copyWith(status: PracticeSessionStatus.inProgress);
    } catch (e) {
      _error = e.toString();
      await _practiceRepo.updateSessionStatus(
          session.id, PracticeSessionStatus.inProgress);
    } finally {
      _isGeneratingTask = false;
      notifyListeners();
    }
  }

  Future<void> _evaluateWork() async {
    final session = activeSession;
    if (session == null || _currentWork.trim().isEmpty) return;
    if (_isEvaluating) return;

    // Rate limit
    final now = DateTime.now();
    if (_lastEvaluationTime != null &&
        now.difference(_lastEvaluationTime!) < _minEvalInterval) {
      return;
    }

    _isEvaluating = true;
    _lastEvaluationTime = now;

    await _practiceRepo.updateSessionStatus(
        session.id, PracticeSessionStatus.evaluating);
    notifyListeners();

    try {
      // Save current work to work cell
      if (_workCellId != null) {
        await _practiceRepo.updateCellContent(_workCellId!, _currentWork);
        final idx = _cells.indexWhere((c) => c.id == _workCellId);
        if (idx >= 0) {
          _cells[idx] = _cells[idx].copyWith(content: _currentWork);
        }
      }

      final provider = await _getActiveProvider();
      final config = await _getRuntimeConfig();

      final task = _activeTask;
      final request = PracticePrompts.evaluationRequest(
        taskPrompt: task?.task ?? session.topic,
        expectedConcepts: task?.expectedConcepts ?? [],
        userWork: _currentWork,
        conversationHistory: _conversationMessages
            .map((m) => AiChatMessage(role: m.role.name, content: m.content))
            .toList(),
        depth: session.depth,
      );

      final raw = await provider.complete(config, request);
      final result = PracticePrompts.parseEvaluationResponse(raw);

      // Save feedback cell
      final feedbackIndex = _cells.length;
      final feedbackCell = await _practiceRepo.addCell(
        sessionId: session.id,
        cellIndex: feedbackIndex,
        cellType: PracticeCellType.feedback,
        content: result.feedback,
        metadata: result.toMetadata(),
      );
      _cells = [..._cells, feedbackCell];

      // Update session status
      final newStatus = result.action == PracticeAction.correct
          ? PracticeSessionStatus.completed
          : PracticeSessionStatus.inProgress;
      await _practiceRepo.updateSessionStatus(session.id, newStatus);
      _sessionStack[_sessionStack.length - 1] =
          session.copyWith(status: newStatus);

      // Auto-complete if correct
      if (result.action == PracticeAction.correct) {
        await completeSession();
        return;
      }
    } catch (e) {
      _error = e.toString();
      await _practiceRepo.updateSessionStatus(
          session.id, PracticeSessionStatus.inProgress);
      _sessionStack[_sessionStack.length - 1] =
          session.copyWith(status: PracticeSessionStatus.inProgress);
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  Future<void> _generateBridgeMessage({
    required String parentTask,
    required String subtaskTopic,
  }) async {
    final session = activeSession;
    if (session == null) return;

    try {
      final provider = await _getActiveProvider();
      final config = await _getRuntimeConfig();

      final request = PracticePrompts.bridgeRequest(
        parentTask: parentTask,
        subtaskTopic: subtaskTopic,
      );

      final raw = await provider.complete(config, request);
      final bridge = PracticePrompts.parseBridgeResponse(raw);

      final feedbackIndex = _cells.length;
      final bridgeCell = await _practiceRepo.addCell(
        sessionId: session.id,
        cellIndex: feedbackIndex,
        cellType: PracticeCellType.feedback,
        content: bridge.bridgeMessage,
        metadata: {
          'action': 'bridge',
          if (bridge.updatedHint != null) 'updated_hint': bridge.updatedHint,
        },
      );
      _cells = [..._cells, bridgeCell];
    } catch (_) {
      // Bridge message is best-effort
    }
  }

  Future<void> _loadActiveCells() async {
    final session = activeSession;
    if (session == null) return;

    _cells = await _practiceRepo.getCells(session.id);

    // Find work cell
    final workCell = _cells
        .where((c) =>
            c.cellType == PracticeCellType.work &&
            c.cellStatus == CellStatus.active)
        .lastOrNull;
    _workCellId = workCell?.id;
    _currentWork = workCell?.content ?? '';

    // Re-hydrate task metadata
    final taskCell = _cells
        .where((c) => c.cellType == PracticeCellType.task)
        .lastOrNull;
    if (taskCell != null) {
      _activeTask = GeneratedTask(
        task: taskCell.content,
        difficulty: taskCell.metadata['difficulty'] as String? ?? 'intermediate',
        expectedConcepts: (taskCell.metadata['expected_concepts'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    }

    // Load conversation messages for AI context
    if (session.conversationId != null) {
      try {
        _conversationMessages = await _aiRepo
            .watchMessages(session.conversationId!)
            .first;
      } catch (_) {
        _conversationMessages = [];
      }
    }
  }

  Future<AiProvider> _getActiveProvider() async {
    final activeId = await _keyStore.getActiveProviderId();
    if (activeId == null) throw Exception('No AI provider configured. Go to Settings to add one.');
    final provider = _providers[activeId];
    if (provider == null) throw Exception('Unknown provider: $activeId');
    return provider;
  }

  Future<ProviderRuntimeConfig> _getRuntimeConfig() async {
    final activeId = await _keyStore.getActiveProviderId();
    if (activeId == null) throw Exception('No AI provider configured.');
    final configs = await _keyStore.getConfigs();
    final config = configs.firstWhere((c) => c.providerId == activeId);
    final apiKey = await _keyStore.getApiKey(activeId);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key found for ${config.label}.');
    }
    return ProviderRuntimeConfig(
      apiKey: apiKey,
      model: config.model,
      baseUrl: config.baseUrl,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
