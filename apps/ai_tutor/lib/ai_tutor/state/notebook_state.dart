import 'package:flutter/foundation.dart';
import '../data/repositories/notebook_repository.dart';
import '../models/notebook.dart';

class NotebookState extends ChangeNotifier {
  NotebookState({required NotebookRepository notebookRepository})
      : _repo = notebookRepository;

  final NotebookRepository _repo;

  Notebook? _notebook;
  List<NotebookPage> _pages = [];
  int _currentPageIndex = 0;
  bool _isLoading = false;

  Notebook? get notebook => _notebook;
  List<NotebookPage> get pages => _pages;
  int get currentPageIndex => _currentPageIndex;
  bool get isLoading => _isLoading;

  NotebookPage? get currentPage {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) return null;
    return _pages[_currentPageIndex];
  }

  int get pageCount => _pages.length;
  bool get hasPreviousPage => _currentPageIndex > 0;
  bool get hasNextPage => _currentPageIndex < _pages.length - 1;

  Future<void> loadNotebook(Notebook notebook) async {
    _isLoading = true;
    _notebook = notebook;
    notifyListeners();

    _pages = await _repo.getPages(notebook.id);
    _currentPageIndex = 0;
    _isLoading = false;
    notifyListeners();
  }

  void goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _currentPageIndex = index;
    notifyListeners();
  }

  void previousPage() => goToPage(_currentPageIndex - 1);
  void nextPage() => goToPage(_currentPageIndex + 1);

  Future<NotebookPage> addPage() async {
    if (_notebook == null) throw StateError('No notebook loaded');
    final page = await _repo.addPage(_notebook!.id);
    _pages = await _repo.getPages(_notebook!.id);
    _currentPageIndex = _pages.length - 1;
    notifyListeners();
    return page;
  }

  void close() {
    _notebook = null;
    _pages = [];
    _currentPageIndex = 0;
    notifyListeners();
  }
}
