import 'enums.dart';

class Stroke {
  const Stroke({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.colorArgb,
    required this.width,
    required this.points,
    required this.createdAt,
  });

  final String id;
  final String pageId;
  final InkTool tool;
  final int colorArgb;
  final double width;
  final List<StrokePoint> points;
  final DateTime createdAt;

  Stroke copyWith({
    String? id,
    String? pageId,
    InkTool? tool,
    int? colorArgb,
    double? width,
    List<StrokePoint>? points,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      tool: tool ?? this.tool,
      colorArgb: colorArgb ?? this.colorArgb,
      width: width ?? this.width,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class StrokePoint {
  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure,
    this.tilt,
    required this.timeOffsetMs,
  });

  final double x;
  final double y;
  final double? pressure;
  final double? tilt;
  final int timeOffsetMs;
}
