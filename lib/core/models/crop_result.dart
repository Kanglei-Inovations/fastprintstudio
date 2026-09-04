import 'dart:typed_data';
import 'dart:ui';
import 'enhancement_config.dart';
import 'quad_points.dart';

class CropResult {
  /// Crop rectangle in source image pixel coordinates
  final Rect sourceRect;

  /// Optional 4-corner perspective quad points (in source image pixel space)
  final QuadPoints? quadPoints;

  /// High quality PNG/JPEG bytes of the cropped/unskewed image region
  final Uint8List croppedBytes;

  /// Dimensions of the source (or rotated source) image in pixels
  final int sourceWidth;
  final int sourceHeight;

  /// 90-degree step rotation (0, 90, 180, 270)
  final int rotationDegrees;

  /// Fine manual angle rotation in degrees (e.g. -45.0 to +45.0)
  final double fineAngleDegrees;

  /// Target aspect ratio (width / height)
  final double? targetAspectRatio;

  /// Optional Image Enhancements (Brightness, Contrast, Sharpness, Smooth Skin)
  final EnhancementConfig? enhancement;

  const CropResult({
    required this.sourceRect,
    this.quadPoints,
    required this.croppedBytes,
    required this.sourceWidth,
    required this.sourceHeight,
    this.rotationDegrees = 0,
    this.fineAngleDegrees = 0.0,
    this.targetAspectRatio,
    this.enhancement,
  });

  /// Crop rectangle normalized to [0.0, 1.0] relative to source dimensions
  Rect get normalizedRect => Rect.fromLTWH(
        sourceWidth > 0 ? sourceRect.left / sourceWidth : 0.0,
        sourceHeight > 0 ? sourceRect.top / sourceHeight : 0.0,
        sourceWidth > 0 ? sourceRect.width / sourceWidth : 1.0,
        sourceHeight > 0 ? sourceRect.height / sourceHeight : 1.0,
      );

  CropResult copyWith({
    Rect? sourceRect,
    QuadPoints? quadPoints,
    Uint8List? croppedBytes,
    int? sourceWidth,
    int? sourceHeight,
    int? rotationDegrees,
    double? fineAngleDegrees,
    double? targetAspectRatio,
    EnhancementConfig? enhancement,
  }) {
    return CropResult(
      sourceRect: sourceRect ?? this.sourceRect,
      quadPoints: quadPoints ?? this.quadPoints,
      croppedBytes: croppedBytes ?? this.croppedBytes,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      fineAngleDegrees: fineAngleDegrees ?? this.fineAngleDegrees,
      targetAspectRatio: targetAspectRatio ?? this.targetAspectRatio,
      enhancement: enhancement ?? this.enhancement,
    );
  }

  @override
  String toString() =>
      'CropResult(sourceRect: $sourceRect, quad: $quadPoints, source: ${sourceWidth}x$sourceHeight, rot: $rotationDegrees°, fine: $fineAngleDegrees°)';
}
