import 'package:flutter/material.dart';
import '../../models/enums.dart';

class PageBackgroundPainter extends CustomPainter {
  PageBackgroundPainter({
    required this.style,
    required this.isDark,
  });

  final PageBackgroundStyle style;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.blueGrey.withAlpha(30);

    switch (style) {
      case PageBackgroundStyle.blank:
        break;
      case PageBackgroundStyle.ruled:
        _drawRuled(canvas, size, lineColor);
      case PageBackgroundStyle.grid:
        _drawGrid(canvas, size, lineColor);
      case PageBackgroundStyle.dotGrid:
        _drawDotGrid(canvas, size, lineColor);
    }
  }

  void _drawRuled(Canvas canvas, Size size, Color color) {
    const spacing = 32.0;
    const marginTop = 80.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Red margin line
    final marginPaint = Paint()
      ..color = Colors.red.withAlpha(40)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      const Offset(72, 0),
      Offset(72, size.height),
      marginPaint,
    );

    for (double y = marginTop; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Color color) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDotGrid(Canvas canvas, Size size, Color color) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = color.withAlpha(60)
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(PageBackgroundPainter oldDelegate) {
    return style != oldDelegate.style || isDark != oldDelegate.isDark;
  }
}
