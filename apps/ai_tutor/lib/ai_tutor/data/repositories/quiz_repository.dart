import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/quiz.dart' as model;
import '../database/ai_tutor_database.dart';

class QuizRepository {
  QuizRepository(this._db);

  final AiTutorDatabase _db;
  static const _uuid = Uuid();

  Future<List<model.Quiz>> getAll() async {
    final rows = await (_db.select(_db.quizzes)
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();
    return rows.map(_mapQuiz).toList();
  }

  Future<model.Quiz> createQuiz({
    required QuizSourceType sourceType,
    required String sourceId,
    required String title,
    required List<model.QuizQuestion> questions,
  }) async {
    final now = DateTime.now();
    final quizId = _uuid.v4();

    await _db.batch((batch) {
      batch.insert(
        _db.quizzes,
        QuizzesCompanion.insert(
          id: quizId,
          sourceType: sourceType.name,
          sourceId: sourceId,
          title: title,
          createdAt: now,
        ),
      );
      for (final q in questions) {
        batch.insert(
          _db.quizQuestions,
          QuizQuestionsCompanion.insert(
            id: q.id,
            quizId: quizId,
            type: q.type.name,
            prompt: q.prompt,
            options: Value(jsonEncode(q.options)),
            correctAnswer: q.correctAnswer,
            explanation: Value(q.explanation),
          ),
        );
      }
    });

    return model.Quiz(
      id: quizId,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      createdAt: now,
    );
  }

  Future<List<model.QuizQuestion>> getQuestions(String quizId) async {
    final rows = await (_db.select(_db.quizQuestions)
          ..where((q) => q.quizId.equals(quizId)))
        .get();
    return rows.map(_mapQuestion).toList();
  }

  Future<model.QuizAttempt> startAttempt(String quizId) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.quizAttempts).insert(
      QuizAttemptsCompanion.insert(
        id: id,
        quizId: quizId,
        startedAt: now,
      ),
    );
    return model.QuizAttempt(id: id, quizId: quizId, startedAt: now);
  }

  Future<void> completeAttempt(String attemptId, double scorePercent) async {
    await (_db.update(_db.quizAttempts)
          ..where((a) => a.id.equals(attemptId)))
        .write(QuizAttemptsCompanion(
      completedAt: Value(DateTime.now()),
      scorePercent: Value(scorePercent),
    ));
  }

  Future<void> deleteQuiz(String id) async {
    await (_db.delete(_db.quizzes)..where((q) => q.id.equals(id))).go();
  }

  model.Quiz _mapQuiz(Quizze row) {
    return model.Quiz(
      id: row.id,
      sourceType: QuizSourceType.values.firstWhere(
        (e) => e.name == row.sourceType,
      ),
      sourceId: row.sourceId,
      title: row.title,
      createdAt: row.createdAt,
    );
  }

  model.QuizQuestion _mapQuestion(QuizQuestion row) {
    List<String> options = [];
    if (row.options.isNotEmpty) {
      try {
        options = (jsonDecode(row.options) as List).cast<String>();
      } catch (_) {
        options = row.options.split(',');
      }
    }
    return model.QuizQuestion(
      id: row.id,
      quizId: row.quizId,
      type: QuestionType.values.firstWhere((e) => e.name == row.type),
      prompt: row.prompt,
      options: options,
      correctAnswer: row.correctAnswer,
      explanation: row.explanation,
    );
  }
}
