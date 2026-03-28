import 'package:flutter/foundation.dart';
import '../data/repositories/document_repository.dart';
import '../models/document.dart';
import '../services/pdf_service.dart';

class DocumentState extends ChangeNotifier {
  DocumentState({
    required DocumentRepository documentRepository,
    required PdfService pdfService,
  })  : _repo = documentRepository,
        _pdfService = pdfService;

  final DocumentRepository _repo;
  final PdfService _pdfService;

  ImportedDocument? _document;
  List<DocumentPage> _pages = [];
  int _currentPageIndex = 0;
  bool _isLoading = false;

  ImportedDocument? get document => _document;
  List<DocumentPage> get pages => _pages;
  int get currentPageIndex => _currentPageIndex;
  bool get isLoading => _isLoading;
  int get pageCount => _document?.pageCount ?? 0;
  bool get hasPreviousPage => _currentPageIndex > 0;
  bool get hasNextPage => _currentPageIndex < pageCount - 1;

  Future<void> loadDocument(ImportedDocument document) async {
    _isLoading = true;
    _document = document;
    _currentPageIndex = 0;
    notifyListeners();

    _pages = await _repo.getPages(document.id);
    _isLoading = false;
    notifyListeners();
  }

  void goToPage(int index) {
    if (index < 0 || index >= pageCount) return;
    _currentPageIndex = index;
    notifyListeners();
  }

  void previousPage() => goToPage(_currentPageIndex - 1);
  void nextPage() => goToPage(_currentPageIndex + 1);

  /// Import a new PDF via file picker.
  Future<ImportedDocument?> importPdf() async {
    final result = await _pdfService.pickAndImportPdf();
    if (result == null) return null;

    // We'll set pageCount to 0 initially — it gets updated when the PDF is opened
    final doc = await _repo.create(
      title: result.originalName.replaceAll('.pdf', ''),
      sourceUri: result.localPath,
      mimeType: 'application/pdf',
      pageCount: 0, // Updated when opened
    );
    return doc;
  }

  /// Update page count after PDF is rendered.
  Future<void> updatePageCount(int count) async {
    if (_document == null) return;
    final updated = _document!.copyWith(pageCount: count);
    _document = updated;
    notifyListeners();
  }

  void close() {
    _document = null;
    _pages = [];
    _currentPageIndex = 0;
    notifyListeners();
  }
}
