import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import '../data/repositories/progress_repository.dart';
import '../models/enums.dart';
import '../models/progress.dart';
import '../services/xp_event_service.dart';

class ProgressState extends ChangeNotifier {
  ProgressState({
    required ProgressRepository progressRepository,
    required XpEventService xpEventService,
  })  : _repo = progressRepository,
        _xpService = xpEventService {
    _load();
  }

  final ProgressRepository _repo;
  final XpEventService _xpService;

  List<StudySession> _sessions = [];
  List<TopicMastery> _masteries = [];
  bool _isLoading = false;

  // Active session tracking
  StudySession? _activeSession;
  int _activeAiInteractions = 0;
  int _activeInkStrokes = 0;

  List<StudySession> get sessions => _sessions;
  List<TopicMastery> get masteries => _masteries;
  bool get isLoading => _isLoading;
  StudySession? get activeSession => _activeSession;
  bool get hasActiveSession => _activeSession != null;

  int get totalStudyMinutes {
    return _sessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get totalXp => XpService.studySessionXp(minutes: totalStudyMinutes);

  int get level => XpService.levelFromXp(totalXp);

  double get levelProgress => XpService.levelProgress(totalXp);

  String get title => XpService.titleForLevel(level);

  int get todayStudyMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) => s.startedAt.isAfter(today))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get weekStudyMinutes {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions
        .where((s) => s.startedAt.isAfter(weekAgo))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    _sessions = await _repo.getAllSessions();
    _masteries = await _repo.getAllMasteries();

    _isLoading = false;
    notifyListeners();
  }

  /// Start tracking a study session.
  Future<void> startSession({
    required StudyTargetType targetType,
    required String targetId,
  }) async {
    _activeSession = await _repo.startSession(
      targetType: targetType,
      targetId: targetId,
    );
    _activeAiInteractions = 0;
    _activeInkStrokes = 0;
    notifyListeners();
  }

  /// Increment AI interaction count for active session.
  void recordAiInteraction() {
    _activeAiInteractions++;
  }

  /// Increment ink stroke count for active session.
  void recordInkStroke() {
    _activeInkStrokes++;
  }

  /// End the active study session.
  Future<void> endSession() async {
    if (_activeSession == null) return;

    await _repo.endSession(
      _activeSession!.id,
      inkStrokeCount: _activeInkStrokes,
      aiInteractionCount: _activeAiInteractions,
    );

    // Calculate XP and emit event
    final duration = DateTime.now().difference(_activeSession!.startedAt);
    final minutes = duration.inMinutes;
    if (minutes > 0) {
      final xp = XpService.studySessionXp(minutes: minutes);
      await _xpService.emitEvent(
        eventType: 'study_session',
        xpAmount: xp,
        durationMinutes: minutes,
        metadata: {
          'targetType': _activeSession!.targetType.name,
          'targetId': _activeSession!.targetId,
          'inkStrokes': _activeInkStrokes,
          'aiInteractions': _activeAiInteractions,
        },
      );
    }

    _activeSession = null;
    await _load();
  }

  /// Update topic mastery (e.g., from quiz results).
  Future<void> updateMastery({
    required String topic,
    required double confidenceScore,
    required int evidenceCount,
  }) async {
    await _repo.upsertMastery(
      topic: topic,
      confidenceScore: confidenceScore,
      evidenceCount: evidenceCount,
    );
    _masteries = await _repo.getAllMasteries();
    notifyListeners();
  }

  /// Refresh data.
  Future<void> refresh() => _load();
}
