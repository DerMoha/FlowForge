import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/notebook_repository.dart';
import '../data/repositories/document_repository.dart';
import '../models/notebook.dart';
import '../models/document.dart';

class LibraryState extends ChangeNotifier {
  LibraryState({
    required NotebookRepository notebookRepository,
    required DocumentRepository documentRepository,
  })  : _notebookRepo = notebookRepository,
        _documentRepo = documentRepository {
    _init();
  }

  final NotebookRepository _notebookRepo;
  final DocumentRepository _documentRepo;

  List<Notebook> _notebooks = [];
  List<ImportedDocument> _documents = [];
  bool _isLoading = true;

  StreamSubscription<List<Notebook>>? _notebookSub;
  StreamSubscription<List<ImportedDocument>>? _documentSub;

  List<Notebook> get notebooks => _notebooks;
  List<ImportedDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  int get notebookCount => _notebooks.length;
  int get documentCount => _documents.length;

  void _init() {
    _notebookSub = _notebookRepo.watchAll().listen((notebooks) {
      _notebooks = notebooks;
      _isLoading = false;
      notifyListeners();
    });
    _documentSub = _documentRepo.watchAll().listen((documents) {
      _documents = documents;
      notifyListeners();
    });
  }

  Future<Notebook> createNotebook({
    required String title,
    String? subject,
  }) async {
    return _notebookRepo.create(title: title, subject: subject);
  }

  Future<void> deleteNotebook(String id) async {
    await _notebookRepo.deleteNotebook(id);
  }

  Future<ImportedDocument> importDocument({
    required String title,
    required String sourceUri,
    required String mimeType,
    required int pageCount,
  }) async {
    return _documentRepo.create(
      title: title,
      sourceUri: sourceUri,
      mimeType: mimeType,
      pageCount: pageCount,
    );
  }

  Future<void> deleteDocument(String id) async {
    await _documentRepo.deleteDocument(id);
  }

  @override
  void dispose() {
    _notebookSub?.cancel();
    _documentSub?.cancel();
    super.dispose();
  }
}
