import 'enums.dart';

class Quiz {
  const Quiz({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final QuizSourceType sourceType;
  final String sourceId;
  final String title;
  final DateTime createdAt;

  Quiz copyWith({
    String? id,
    QuizSourceType? sourceType,
    String? sourceId,
    String? title,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.type,
    required this.prompt,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
  });

  final String id;
  final String quizId;
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;

  QuizQuestion copyWith({
    String? id,
    String? quizId,
    QuestionType? type,
    String? prompt,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
    );
  }
}

class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.startedAt,
    this.completedAt,
    this.scorePercent,
  });

  final String id;
  final String quizId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? scorePercent;

  QuizAttempt copyWith({
    String? id,
    String? quizId,
    DateTime? startedAt,
    DateTime? completedAt,
    double? scorePercent,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      scorePercent: scorePercent ?? this.scorePercent,
    );
  }
}
