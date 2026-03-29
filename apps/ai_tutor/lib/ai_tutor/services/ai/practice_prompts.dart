import 'dart:convert';
import '../../models/enums.dart';
import 'ai_provider.dart';

/// Structured response from the AI for a task generation request.
class GeneratedTask {
  const GeneratedTask({
    required this.task,
    required this.difficulty,
    required this.expectedConcepts,
  });

  final String task;
  final String difficulty;
  final List<String> expectedConcepts;
}

/// Structured response from the AI for a work evaluation request.
class EvaluationResult {
  const EvaluationResult({
    required this.action,
    required this.feedback,
    this.issue,
    this.score,
    this.progress,
    this.subtaskTopic,
    this.subtaskReason,
  });

  final PracticeAction action;
  final String feedback;
  final String? issue;
  final double? score;
  final double? progress;
  final String? subtaskTopic;
  final String? subtaskReason;

  Map<String, dynamic> toMetadata() => {
        'action': action.name,
        if (issue != null) 'issue': issue,
        if (score != null) 'score': score,
        if (progress != null) 'progress': progress,
        if (subtaskTopic != null) 'subtask_topic': subtaskTopic,
        if (subtaskReason != null) 'subtask_reason': subtaskReason,
      };
}

/// Structured response when returning from a sub-task.
class BridgeMessage {
  const BridgeMessage({
    required this.bridgeMessage,
    this.updatedHint,
  });

  final String bridgeMessage;
  final String? updatedHint;
}

class PracticePrompts {
  PracticePrompts._();

  // ── Task generation ──

  static AiChatRequest taskGenerationRequest({
    required String topic,
    String? parentTopic,
    String? contextContent,
    int depth = 0,
  }) {
    final buffer = StringBuffer();

    if (depth > 0 && parentTopic != null) {
      buffer.writeln(
        'This is a prerequisite sub-task (depth $depth). '
        'The student was working on "$parentTopic" but needs to practice "$topic" first. '
        'Create a focused, simpler problem that specifically targets this prerequisite.',
      );
    } else {
      buffer.writeln('The student wants to practice: "$topic".');
    }

    if (contextContent != null && contextContent.isNotEmpty) {
      buffer.writeln('\nRelevant study material:\n$contextContent');
    }

    buffer.writeln(
      '\nGenerate ONE practice problem appropriate for the student\'s level. '
      'Respond ONLY with valid JSON, no markdown. '
      'Format: {"task": "the problem statement", "difficulty": "beginner|intermediate|advanced", "expected_concepts": ["concept1"]}',
    );

    return AiChatRequest(
      messages: [AiChatMessage(role: 'user', content: buffer.toString())],
      systemPrompt: 'You are an AI tutor creating a focused, clear practice problem. '
          'Return ONLY valid JSON with no markdown formatting.',
    );
  }

  static GeneratedTask parseTaskResponse(String raw) {
    final cleaned = _stripMarkdown(raw);
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final concepts = (json['expected_concepts'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      return GeneratedTask(
        task: json['task'] as String? ?? cleaned,
        difficulty: json['difficulty'] as String? ?? 'intermediate',
        expectedConcepts: concepts,
      );
    } catch (_) {
      // Fallback: treat entire response as the task
      return GeneratedTask(
        task: raw.trim(),
        difficulty: 'intermediate',
        expectedConcepts: [],
      );
    }
  }

  // ── Work evaluation ──

  static AiChatRequest evaluationRequest({
    required String taskPrompt,
    required List<String> expectedConcepts,
    required String userWork,
    required List<AiChatMessage> conversationHistory,
    int depth = 0,
  }) {
    final maxDepth = depth >= 3;
    final buffer = StringBuffer();
    buffer.writeln('Task: $taskPrompt');
    if (expectedConcepts.isNotEmpty) {
      buffer.writeln('Expected concepts: ${expectedConcepts.join(", ")}');
    }
    buffer.writeln('\nStudent\'s current work:\n$userWork');

    if (maxDepth) {
      buffer.writeln(
        '\nIMPORTANT: Do NOT suggest sub-tasks (max nesting depth reached). '
        'Only give hints or mark as correct.',
      );
    }

    buffer.writeln('''
Evaluate the student's work and respond ONLY with valid JSON (no markdown):

If correct: {"action": "correct", "feedback": "...", "score": 0.0-1.0}
If needs a hint: {"action": "hint", "feedback": "a helpful hint without the answer", "issue": "what's wrong"}
If prerequisite gap (and not max depth): {"action": "suggest_subtask", "feedback": "...", "subtask_topic": "topic to practice", "subtask_reason": "why needed"}
If partially right: {"action": "partial", "feedback": "encouragement + what's right", "progress": 0.0-1.0}''');

    return AiChatRequest(
      messages: [
        ...conversationHistory,
        AiChatMessage(role: 'user', content: buffer.toString()),
      ],
      systemPrompt: 'You are an AI tutor evaluating a student\'s work. '
          'Be encouraging but honest. Return ONLY valid JSON with no markdown.',
    );
  }

  static EvaluationResult parseEvaluationResponse(String raw) {
    final cleaned = _stripMarkdown(raw);
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final actionStr = json['action'] as String? ?? 'hint';
      final action = PracticeAction.values.firstWhere(
        (a) => a.name == actionStr || a.name == _snakeToCamel(actionStr),
        orElse: () => PracticeAction.hint,
      );
      return EvaluationResult(
        action: action,
        feedback: json['feedback'] as String? ?? cleaned,
        issue: json['issue'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        progress: (json['progress'] as num?)?.toDouble(),
        subtaskTopic: json['subtask_topic'] as String?,
        subtaskReason: json['subtask_reason'] as String?,
      );
    } catch (_) {
      return EvaluationResult(
        action: PracticeAction.hint,
        feedback: raw.trim(),
      );
    }
  }

  // ── Sub-task bridge ──

  static AiChatRequest bridgeRequest({
    required String parentTask,
    required String subtaskTopic,
  }) {
    return AiChatRequest(
      messages: [
        AiChatMessage(
          role: 'user',
          content: 'The student just completed a prerequisite sub-task on "$subtaskTopic". '
              'Their original task was: "$parentTask". '
              'Generate a bridge message connecting what they just practiced back to the original problem. '
              'Respond ONLY with valid JSON: '
              '{"bridge_message": "...", "updated_hint": "optional hint for the parent task"}',
        ),
      ],
      systemPrompt: 'You are an AI tutor reconnecting a student to their main task after a detour. '
          'Be encouraging. Return ONLY valid JSON with no markdown.',
    );
  }

  static BridgeMessage parseBridgeResponse(String raw) {
    final cleaned = _stripMarkdown(raw);
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return BridgeMessage(
        bridgeMessage: json['bridge_message'] as String? ?? raw.trim(),
        updatedHint: json['updated_hint'] as String?,
      );
    } catch (_) {
      return BridgeMessage(bridgeMessage: raw.trim());
    }
  }

  // ── Helpers ──

  static String _stripMarkdown(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```\w*\n?'), '');
      s = s.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return s.trim();
  }

  static String _snakeToCamel(String s) {
    final parts = s.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
