import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../models/enums.dart';
import '../../models/stroke.dart';
import '../../state/ink_state.dart';
import '../../state/notebook_state.dart';
import 'page_background_painter.dart';

const _uuid = Uuid();

class InkCanvas extends StatelessWidget {
  const InkCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final notebookState = context.watch<NotebookState>();
    final inkState = context.watch<InkState>();
    final page = notebookState.currentPage;

    if (page == null) {
      return const Center(child: Text('No page'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: Stack(
        children: [
          // Page background
          Positioned.fill(
            child: CustomPaint(
              painter: PageBackgroundPainter(
                style: page.backgroundStyle,
                isDark: isDark,
              ),
            ),
          ),
          // Ink layer
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) =>
                  _onPointerDown(context, event, inkState),
              onPointerMove: (event) =>
                  _onPointerMove(context, event, inkState),
              onPointerUp: (event) =>
                  _onPointerUp(context, event, inkState, notebookState),
              child: CustomPaint(
                painter: _InkCanvasPainter(
                  strokes: inkState.strokes,
                  currentPoints: inkState.currentPoints,
                  currentColor: inkState.effectiveColor,
                  currentWidth: inkState.effectiveWidth,
                  currentTool: inkState.tool,
                  isDrawing: inkState.isDrawing,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPointerDown(
      BuildContext context, PointerDownEvent event, InkState inkState) {
    // Eraser tool: check hit on existing strokes
    if (inkState.tool == InkTool.eraser) {
      _tryErase(context, event.localPosition, inkState);
      return;
    }
    if (inkState.tool == InkTool.lasso) return; // Not implemented yet

    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure,
      tilt: event.tilt,
      timeOffsetMs: 0,
    );
    inkState.beginStroke(point);
  }

  void _onPointerMove(
      BuildContext context, PointerMoveEvent event, InkState inkState) {
    if (inkState.tool == InkTool.eraser) {
      _tryErase(context, event.localPosition, inkState);
      return;
    }
    if (!inkState.isDrawing) return;

    final startTime = inkState.currentPoints.isNotEmpty
        ? inkState.currentPoints.first.timeOffsetMs
        : 0;

    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure,
      tilt: event.tilt,
      timeOffsetMs: DateTime.now().millisecondsSinceEpoch - startTime,
    );
    inkState.addPoint(point);
  }

  void _onPointerUp(BuildContext context, PointerUpEvent event,
      InkState inkState, NotebookState notebookState) {
    if (inkState.tool == InkTool.eraser || inkState.tool == InkTool.lasso) {
      return;
    }

    final page = notebookState.currentPage;
    if (page == null) return;

    final stroke = inkState.endStroke(_uuid.v4(), page.id);
    if (stroke != null) {
      // Persist async
      context.read<NotebookRepository>().addStroke(stroke);
    }
  }

  void _tryErase(BuildContext context, Offset position, InkState inkState) {
    const hitRadius = 15.0;
    // Check strokes in reverse order (top-most first)
    for (int i = inkState.strokes.length - 1; i >= 0; i--) {
      final stroke = inkState.strokes[i];
      for (final point in stroke.points) {
        final dx = point.x - position.dx;
        final dy = point.y - position.dy;
        if (dx * dx + dy * dy < hitRadius * hitRadius) {
          final removed = inkState.removeStroke(stroke.id);
          if (removed != null) {
            context.read<NotebookRepository>().deleteStroke(removed.id);
          }
          return;
        }
      }
    }
  }
}

class _InkCanvasPainter extends CustomPainter {
  _InkCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
    required this.isDrawing,
  });

  final List<Stroke> strokes;
  final List<StrokePoint> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final InkTool currentTool;
  final bool isDrawing;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.tool,
          Color(stroke.colorArgb), stroke.width);
    }

    // Draw current in-progress stroke
    if (isDrawing && currentPoints.length >= 2) {
      _drawStroke(canvas, currentPoints, currentTool, currentColor,
          currentWidth);
    }
  }

  void _drawStroke(Canvas canvas, List<StrokePoint> points, InkTool tool,
      Color color, double width) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == InkTool.highlighter) {
      paint.blendMode = ui.BlendMode.multiply;
    }

    final path = Path();
    path.moveTo(points[0].x, points[0].y);

    if (points.length == 2) {
      path.lineTo(points[1].x, points[1].y);
    } else {
      // Smooth curve through points using quadratic bezier
      for (int i = 1; i < points.length - 1; i++) {
        final midX = (points[i].x + points[i + 1].x) / 2;
        final midY = (points[i].y + points[i + 1].y) / 2;
        path.quadraticBezierTo(points[i].x, points[i].y, midX, midY);
      }
      // Connect to the last point
      final last = points.last;
      path.lineTo(last.x, last.y);
    }

    // Pressure-sensitive width: modulate along the path
    if (_hasPressureData(points)) {
      // Draw with variable width using multiple segments
      _drawPressureSensitiveStroke(canvas, points, paint, width);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  bool _hasPressureData(List<StrokePoint> points) {
    return points.any((p) => p.pressure != null && p.pressure != 0.0);
  }

  void _drawPressureSensitiveStroke(
      Canvas canvas, List<StrokePoint> points, Paint basePaint, double baseWidth) {
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final pressure = (p1.pressure ?? 0.5).clamp(0.1, 1.0);
      final segmentPaint = Paint()
        ..color = basePaint.color
        ..strokeWidth = baseWidth * pressure
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = basePaint.blendMode;

      canvas.drawLine(
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_InkCanvasPainter oldDelegate) => true;
}
