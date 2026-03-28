import 'enums.dart';

class Notebook {
  const Notebook({
    required this.id,
    required this.title,
    this.subject,
    this.tags = const [],
    this.coverStyle,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String title;
  final String? subject;
  final List<String> tags;
  final String? coverStyle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  Notebook copyWith({
    String? id,
    String? title,
    String? subject,
    List<String>? tags,
    String? coverStyle,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchive = false,
  }) {
    return Notebook(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      coverStyle: coverStyle ?? this.coverStyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchive ? null : (archivedAt ?? this.archivedAt),
    );
  }
}

class NotebookPage {
  const NotebookPage({
    required this.id,
    required this.notebookId,
    required this.index,
    this.backgroundStyle = PageBackgroundStyle.ruled,
    this.derivedText,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String notebookId;
  final int index;
  final PageBackgroundStyle backgroundStyle;
  final String? derivedText;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotebookPage copyWith({
    String? id,
    String? notebookId,
    int? index,
    PageBackgroundStyle? backgroundStyle,
    String? derivedText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotebookPage(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      index: index ?? this.index,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      derivedText: derivedText ?? this.derivedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
