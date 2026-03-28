import 'package:drift/drift.dart';

// ── Notebook domain ──

class Notebooks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated
  TextColumn get coverStyle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NotebookPages extends Table {
  TextColumn get id => text()();
  TextColumn get notebookId => text().references(Notebooks, #id)();
  IntColumn get pageIndex => integer()();
  TextColumn get backgroundStyle => text().withDefault(const Constant('ruled'))();
  TextColumn get derivedText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Strokes extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(NotebookPages, #id)();
  TextColumn get tool => text()(); // InkTool name
  IntColumn get colorArgb => integer()();
  RealColumn get width => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StrokePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get strokeId => text().references(Strokes, #id)();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get pressure => real().nullable()();
  RealColumn get tilt => real().nullable()();
  IntColumn get timeOffsetMs => integer()();
}

// ── Document domain ──

class ImportedDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get sourceUri => text()();
  TextColumn get mimeType => text()();
  IntColumn get pageCount => integer()();
  TextColumn get extractedTextStatus =>
      text().withDefault(const Constant('notExtracted'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DocumentPages extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(ImportedDocuments, #id)();
  IntColumn get pageIndex => integer()();
  TextColumn get extractedText => text().nullable()();
  RealColumn get ocrConfidence => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Annotation domain ──

class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()(); // AnnotationTargetType name
  TextColumn get targetId => text()();
  IntColumn get pageIndex => integer().nullable()();
  RealColumn get boundsLeft => real().nullable()();
  RealColumn get boundsTop => real().nullable()();
  RealColumn get boundsRight => real().nullable()();
  RealColumn get boundsBottom => real().nullable()();
  TextColumn get kind => text()(); // AnnotationKind name
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── AI domain ──

class AiConversations extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()(); // ConversationTargetType name
  TextColumn get targetId => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AiMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(AiConversations, #id)();
  TextColumn get role => text()(); // MessageRole name
  TextColumn get content => text()();
  TextColumn get citations =>
      text().withDefault(const Constant(''))(); // comma-separated
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Quiz domain ──

class Quizzes extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => text()(); // QuizSourceType name
  TextColumn get sourceId => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuizQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get quizId => text().references(Quizzes, #id)();
  TextColumn get type => text()(); // QuestionType name
  TextColumn get prompt => text()();
  TextColumn get options =>
      text().withDefault(const Constant(''))(); // JSON array
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuizAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get quizId => text().references(Quizzes, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  RealColumn get scorePercent => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Progress domain ──

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()(); // StudyTargetType name
  TextColumn get targetId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get inkStrokeCount => integer().withDefault(const Constant(0))();
  IntColumn get aiInteractionCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TopicMasteries extends Table {
  TextColumn get id => text()();
  TextColumn get topic => text()();
  RealColumn get confidenceScore => real()();
  IntColumn get evidenceCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
