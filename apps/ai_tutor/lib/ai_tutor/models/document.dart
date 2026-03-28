import 'enums.dart';

class ImportedDocument {
  const ImportedDocument({
    required this.id,
    required this.title,
    required this.sourceUri,
    required this.mimeType,
    required this.pageCount,
    this.extractedTextStatus = ExtractedTextStatus.notExtracted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String sourceUri;
  final String mimeType;
  final int pageCount;
  final ExtractedTextStatus extractedTextStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImportedDocument copyWith({
    String? id,
    String? title,
    String? sourceUri,
    String? mimeType,
    int? pageCount,
    ExtractedTextStatus? extractedTextStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceUri: sourceUri ?? this.sourceUri,
      mimeType: mimeType ?? this.mimeType,
      pageCount: pageCount ?? this.pageCount,
      extractedTextStatus: extractedTextStatus ?? this.extractedTextStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentPage {
  const DocumentPage({
    required this.id,
    required this.documentId,
    required this.pageIndex,
    this.extractedText,
    this.ocrConfidence,
  });

  final String id;
  final String documentId;
  final int pageIndex;
  final String? extractedText;
  final double? ocrConfidence;

  DocumentPage copyWith({
    String? id,
    String? documentId,
    int? pageIndex,
    String? extractedText,
    double? ocrConfidence,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      extractedText: extractedText ?? this.extractedText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
    );
  }
}
