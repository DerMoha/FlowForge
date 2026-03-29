import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'ai_tutor_database.g.dart';

@DriftDatabase(tables: [
  Notebooks,
  NotebookPages,
  Strokes,
  StrokePoints,
  ImportedDocuments,
  DocumentPages,
  Annotations,
  AiConversations,
  AiMessages,
  Quizzes,
  QuizQuestions,
  QuizAttempts,
  StudySessions,
  TopicMasteries,
  PracticeSessions,
  PracticeCells,
])
class AiTutorDatabase extends _$AiTutorDatabase {
  AiTutorDatabase() : super(_openConnection());

  AiTutorDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(practiceSessions);
          await m.createTable(practiceCells);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ai_tutor.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
