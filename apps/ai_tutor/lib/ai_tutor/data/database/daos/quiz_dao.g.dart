// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_dao.dart';

// ignore_for_file: type=lint
mixin _$QuizDaoMixin on DatabaseAccessor<AiTutorDatabase> {
  $QuizzesTable get quizzes => attachedDatabase.quizzes;
  $QuizQuestionsTable get quizQuestions => attachedDatabase.quizQuestions;
  $QuizAttemptsTable get quizAttempts => attachedDatabase.quizAttempts;
  QuizDaoManager get managers => QuizDaoManager(this);
}

class QuizDaoManager {
  final _$QuizDaoMixin _db;
  QuizDaoManager(this._db);
  $$QuizzesTableTableManager get quizzes =>
      $$QuizzesTableTableManager(_db.attachedDatabase, _db.quizzes);
  $$QuizQuestionsTableTableManager get quizQuestions =>
      $$QuizQuestionsTableTableManager(_db.attachedDatabase, _db.quizQuestions);
  $$QuizAttemptsTableTableManager get quizAttempts =>
      $$QuizAttemptsTableTableManager(_db.attachedDatabase, _db.quizAttempts);
}
