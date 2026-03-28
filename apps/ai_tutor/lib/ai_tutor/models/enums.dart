enum InkTool { pen, highlighter, eraser, lasso }

enum PageBackgroundStyle { blank, ruled, grid, dotGrid }

enum AnnotationTargetType { notebook, document }

enum AnnotationKind { highlight, underline, note, drawing }

enum ConversationTargetType { notebook, document }

enum MessageRole { user, assistant, system }

enum QuizSourceType { notebook, document }

enum QuestionType { multipleChoice, trueFalse, fillInBlank, shortAnswer }

enum StudyTargetType { notebook, document }

enum ExtractedTextStatus {
  notExtracted,
  extracting,
  extracted,
  ocrNeeded,
  ocrComplete,
  failed,
}
