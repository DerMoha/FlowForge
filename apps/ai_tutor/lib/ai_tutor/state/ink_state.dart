import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/stroke.dart';

class InkState extends ChangeNotifier {
  InkTool _tool = InkTool.pen;
  Color _color = Colors.black;
  double _strokeWidth = 2.0;
  final List<Stroke> _strokes = [];
  final List<Stroke> _undoStack = [];
  List<StrokePoint> _currentPoints = [];
  bool _isDrawing = false;

  InkTool get tool => _tool;
  Color get color => _color;
  double get strokeWidth => _strokeWidth;
  List<Stroke> get strokes => List.unmodifiable(_strokes);
  bool get isDrawing => _isDrawing;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;

  void setTool(InkTool tool) {
    _tool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width.clamp(0.5, 20.0);
    notifyListeners();
  }

  /// Load strokes from persistence (called when switching pages).
  void loadStrokes(List<Stroke> strokes) {
    _strokes.clear();
    _strokes.addAll(strokes);
    _undoStack.clear();
    _currentPoints.clear();
    _isDrawing = false;
    notifyListeners();
  }

  /// Begin a new stroke at the given point.
  void beginStroke(StrokePoint point) {
    _isDrawing = true;
    _currentPoints = [point];
    notifyListeners();
  }

  /// Continue the current stroke with a new point.
  void addPoint(StrokePoint point) {
    if (!_isDrawing) return;
    _currentPoints.add(point);
    notifyListeners();
  }

  /// Finish the current stroke and return it for persistence.
  Stroke? endStroke(String strokeId, String pageId) {
    if (!_isDrawing || _currentPoints.length < 2) {
      _isDrawing = false;
      _currentPoints = [];
      notifyListeners();
      return null;
    }

    final stroke = Stroke(
      id: strokeId,
      pageId: pageId,
      tool: _tool,
      colorArgb: _color.toARGB32(),
      width: _strokeWidth,
      points: List.unmodifiable(_currentPoints),
      createdAt: DateTime.now(),
    );

    _strokes.add(stroke);
    _undoStack.clear(); // New stroke clears redo history
    _isDrawing = false;
    _currentPoints = [];
    notifyListeners();
    return stroke;
  }

  /// Get current in-progress points for live rendering.
  List<StrokePoint> get currentPoints => _currentPoints;

  void undo() {
    if (_strokes.isEmpty) return;
    _undoStack.add(_strokes.removeLast());
    notifyListeners();
  }

  Stroke? redo() {
    if (_undoStack.isEmpty) return null;
    final stroke = _undoStack.removeLast();
    _strokes.add(stroke);
    notifyListeners();
    return stroke;
  }

  /// Remove a specific stroke (for eraser tool).
  Stroke? removeStroke(String strokeId) {
    final index = _strokes.indexWhere((s) => s.id == strokeId);
    if (index == -1) return null;
    final removed = _strokes.removeAt(index);
    notifyListeners();
    return removed;
  }

  /// Get effective color for current tool.
  Color get effectiveColor {
    switch (_tool) {
      case InkTool.pen:
        return _color;
      case InkTool.highlighter:
        return _color.withAlpha(80);
      case InkTool.eraser:
      case InkTool.lasso:
        return Colors.transparent;
    }
  }

  /// Get effective width for current tool.
  double get effectiveWidth {
    switch (_tool) {
      case InkTool.pen:
        return _strokeWidth;
      case InkTool.highlighter:
        return _strokeWidth * 4;
      case InkTool.eraser:
        return _strokeWidth * 3;
      case InkTool.lasso:
        return 1.0;
    }
  }
}
