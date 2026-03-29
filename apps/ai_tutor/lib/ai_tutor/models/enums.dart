enum InkTool { pen, highlighter, eraser, lasso }

enum PageBackgroundStyle { blank, ruled, grid, dotGrid }

enum AnnotationTargetType { notebook, document }

enum AnnotationKind { highlight, underline, note, drawing }

enum ConversationTargetType { notebook, document, practice }

enum MessageRole { user, assistant, system }

enum QuizSourceType { notebook, document }

enum QuestionType { multipleChoice, trueFalse, fillInBlank, shortAnswer }

enum StudyTargetType { notebook, document, practice }

// ── Practice domain enums ──

enum PracticeSourceType { notebook, document, freeform }

enum PracticeSessionStatus {
  notStarted,
  awaitingTask,
  inProgress,
  evaluating,
  subtaskActive,
  completed,
  abandoned,
}

enum PracticeCellType { task, work, feedback }

enum CellStatus { active, completed, superseded }

enum PracticeAction { correct, hint, suggestSubtask, partial }

enum ExtractedTextStatus {
  notExtracted,
  extracting,
  extracted,
  ocrNeeded,
  ocrComplete,
  failed,
}
