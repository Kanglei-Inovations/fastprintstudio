import 'dart:math' as math;
import 'dart:ui';

/// Represents 4 arbitrary corner points for perspective cropping and document quad unskewing
class QuadPoints {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;

  const QuadPoints({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Creates QuadPoints from a standard Rect
  factory QuadPoints.fromRect(Rect rect) {
    return QuadPoints(
      topLeft: rect.topLeft,
      topRight: rect.topRight,
      bottomRight: rect.bottomRight,
      bottomLeft: rect.bottomLeft,
    );
  }

  /// Calculates the bounding rectangle enclosing all 4 points
  Rect get boundingBox {
    final minX = math.min(math.min(topLeft.dx, topRight.dx), math.min(bottomRight.dx, bottomLeft.dx));
    final maxX = math.max(math.max(topLeft.dx, topRight.dx), math.max(bottomRight.dx, bottomLeft.dx));
    final minY = math.min(math.min(topLeft.dy, topRight.dy), math.min(bottomRight.dy, bottomLeft.dy));
    final maxY = math.max(math.max(topLeft.dy, topRight.dy), math.max(bottomRight.dy, bottomLeft.dy));
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Estimated width of the quad
  double get estimatedWidth {
    final topW = (topRight - topLeft).distance;
    final botW = (bottomRight - bottomLeft).distance;
    return math.max(topW, botW);
  }

  /// Estimated height of the quad
  double get estimatedHeight {
    final leftH = (bottomLeft - topLeft).distance;
    final rightH = (bottomRight - topRight).distance;
    return math.max(leftH, rightH);
  }

  QuadPoints copyWith({
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomRight,
    Offset? bottomLeft,
  }) {
    return QuadPoints(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
    );
  }

  /// Clamps all 4 points within the given bounds
  QuadPoints clamp(Rect bounds) {
    return QuadPoints(
      topLeft: Offset(topLeft.dx.clamp(bounds.left, bounds.right), topLeft.dy.clamp(bounds.top, bounds.bottom)),
      topRight: Offset(topRight.dx.clamp(bounds.left, bounds.right), topRight.dy.clamp(bounds.top, bounds.bottom)),
      bottomRight: Offset(bottomRight.dx.clamp(bounds.left, bounds.right), bottomRight.dy.clamp(bounds.top, bounds.bottom)),
      bottomLeft: Offset(bottomLeft.dx.clamp(bounds.left, bounds.right), bottomLeft.dy.clamp(bounds.top, bounds.bottom)),
    );
  }

  /// Scales all 4 points by a factor
  QuadPoints scale(double factorX, double factorY) {
    return QuadPoints(
      topLeft: Offset(topLeft.dx * factorX, topLeft.dy * factorY),
      topRight: Offset(topRight.dx * factorX, topRight.dy * factorY),
      bottomRight: Offset(bottomRight.dx * factorX, bottomRight.dy * factorY),
      bottomLeft: Offset(bottomLeft.dx * factorX, bottomLeft.dy * factorY),
    );
  }

  /// Translates all 4 points by an offset
  QuadPoints translate(Offset delta) {
    return QuadPoints(
      topLeft: topLeft + delta,
      topRight: topRight + delta,
      bottomRight: bottomRight + delta,
      bottomLeft: bottomLeft + delta,
    );
  }
}
