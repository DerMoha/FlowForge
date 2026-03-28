import 'package:drift/drift.dart';
import '../ai_tutor_database.dart';
import '../tables.dart';

part 'quiz_dao.g.dart';

@DriftAccessor(tables: [Quizzes, QuizQuestions, QuizAttempts])
class QuizDao extends DatabaseAccessor<AiTutorDatabase>
    with _$QuizDaoMixin {
  QuizDao(super.db);

  Future<List<Quizze>> getAllQuizzes() =>
      (select(quizzes)..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();

  Future<Quizze> getQuiz(String id) =>
      (select(quizzes)..where((q) => q.id.equals(id))).getSingle();

  Future<int> insertQuiz(QuizzesCompanion entry) =>
      into(quizzes).insert(entry);

  Future<int> deleteQuiz(String id) =>
      (delete(quizzes)..where((q) => q.id.equals(id))).go();

  // ── Questions ──

  Future<List<QuizQuestion>> getQuestionsForQuiz(String quizId) =>
      (select(quizQuestions)..where((q) => q.quizId.equals(quizId))).get();

  Future<int> insertQuestion(QuizQuestionsCompanion entry) =>
      into(quizQuestions).insert(entry);

  // ── Attempts ──

  Future<List<QuizAttempt>> getAttemptsForQuiz(String quizId) =>
      (select(quizAttempts)
            ..where((a) => a.quizId.equals(quizId))
            ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]))
          .get();

  Future<int> insertAttempt(QuizAttemptsCompanion entry) =>
      into(quizAttempts).insert(entry);

  Future<bool> updateAttempt(QuizAttemptsCompanion entry) =>
      update(quizAttempts).replace(entry);
}
