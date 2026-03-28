import 'enums.dart';

class NormalizedBounds {
  const NormalizedBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}

class Annotation {
  const Annotation({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.pageIndex,
    this.bounds,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final AnnotationTargetType targetType;
  final String targetId;
  final int? pageIndex;
  final NormalizedBounds? bounds;
  final AnnotationKind kind;
  final String payload;
  final DateTime createdAt;

  Annotation copyWith({
    String? id,
    AnnotationTargetType? targetType,
    String? targetId,
    int? pageIndex,
    NormalizedBounds? bounds,
    AnnotationKind? kind,
    String? payload,
    DateTime? createdAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      pageIndex: pageIndex ?? this.pageIndex,
      bounds: bounds ?? this.bounds,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
