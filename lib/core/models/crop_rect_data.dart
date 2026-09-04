import 'dart:ui';
import 'quad_points.dart';

class CropRectData {
  /// Normalized coordinates (0.0 to 1.0 relative to original image)
  final double left;
  final double top;
  final double width;
  final double height;
  final double rotationDegrees;
  final double fineAngleDegrees;
  final QuadPoints? quadPoints;

  const CropRectData({
    this.left = 0.0,
    this.top = 0.0,
    this.width = 1.0,
    this.height = 1.0,
    this.rotationDegrees = 0.0,
    this.fineAngleDegrees = 0.0,
    this.quadPoints,
  });

  /// Full uncropped default
  static const CropRectData full = CropRectData();

  double get right => left + width;
  double get bottom => top + height;
  double get aspectRatio => height > 0 ? width / height : 1.0;
  bool get isQuad => quadPoints != null;

  /// Clamps normalized coordinates inside [0.0, 1.0]
  CropRectData clamp() {
    final cLeft = left.clamp(0.0, 1.0);
    final cTop = top.clamp(0.0, 1.0);
    final cWidth = width.clamp(0.01, 1.0 - cLeft);
    final cHeight = height.clamp(0.01, 1.0 - cTop);
    return CropRectData(
      left: cLeft,
      top: cTop,
      width: cWidth,
      height: cHeight,
      rotationDegrees: rotationDegrees,
      fineAngleDegrees: fineAngleDegrees,
      quadPoints: quadPoints,
    );
  }

  /// Converts normalized rect to pixel coordinates on image of size (imageWidth, imageHeight)
  Rect toPixelRect(int imageWidth, int imageHeight) {
    final clamped = clamp();
    return Rect.fromLTWH(
      clamped.left * imageWidth,
      clamped.top * imageHeight,
      clamped.width * imageWidth,
      clamped.height * imageHeight,
    );
  }

  /// Creates a CropRectData from pixel coordinates
  factory CropRectData.fromPixelRect(Rect pixelRect, int imageWidth, int imageHeight) {
    if (imageWidth <= 0 || imageHeight <= 0) return const CropRectData();
    return CropRectData(
      left: (pixelRect.left / imageWidth).clamp(0.0, 1.0),
      top: (pixelRect.top / imageHeight).clamp(0.0, 1.0),
      width: (pixelRect.width / imageWidth).clamp(0.01, 1.0),
      height: (pixelRect.height / imageHeight).clamp(0.01, 1.0),
    ).clamp();
  }

  /// Creates a centered crop box with target aspect ratio (targetWidth / targetHeight)
  factory CropRectData.centeredWithAspectRatio(double targetAspectRatio, {double scaleFactor = 0.85}) {
    double w, h;
    if (targetAspectRatio >= 1.0) {
      // Wide box
      w = scaleFactor.clamp(0.1, 0.95);
      h = w / targetAspectRatio;
      if (h > 0.95) {
        h = 0.95;
        w = h * targetAspectRatio;
      }
    } else {
      // Tall box
      h = scaleFactor.clamp(0.1, 0.95);
      w = h * targetAspectRatio;
      if (w > 0.95) {
        w = 0.95;
        h = w / targetAspectRatio;
      }
    }
    final left = (1.0 - w) / 2.0;
    final top = (1.0 - h) / 2.0;
    return CropRectData(
      left: left.clamp(0.0, 1.0),
      top: top.clamp(0.0, 1.0),
      width: w.clamp(0.01, 1.0),
      height: h.clamp(0.01, 1.0),
    );
  }

  CropRectData copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    double? rotationDegrees,
    double? fineAngleDegrees,
    QuadPoints? quadPoints,
    bool clearQuad = false,
  }) {
    return CropRectData(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      fineAngleDegrees: fineAngleDegrees ?? this.fineAngleDegrees,
      quadPoints: clearQuad ? null : (quadPoints ?? this.quadPoints),
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'rotationDegrees': rotationDegrees,
        'fineAngleDegrees': fineAngleDegrees,
      };

  factory CropRectData.fromJson(Map<String, dynamic> json) => CropRectData(
        left: (json['left'] as num?)?.toDouble() ?? 0.0,
        top: (json['top'] as num?)?.toDouble() ?? 0.0,
        width: (json['width'] as num?)?.toDouble() ?? 1.0,
        height: (json['height'] as num?)?.toDouble() ?? 1.0,
        rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
        fineAngleDegrees: (json['fineAngleDegrees'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropRectData &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height &&
          rotationDegrees == other.rotationDegrees &&
          fineAngleDegrees == other.fineAngleDegrees &&
          quadPoints == other.quadPoints;

  @override
  int get hashCode =>
      left.hashCode ^
      top.hashCode ^
      width.hashCode ^
      height.hashCode ^
      rotationDegrees.hashCode ^
      fineAngleDegrees.hashCode ^
      quadPoints.hashCode;
}
