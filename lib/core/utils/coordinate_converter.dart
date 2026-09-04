import 'dart:math' as math;
import 'dart:ui';

class DisplayFittingInfo {
  final Rect displayRect;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double displayedWidth;
  final double displayedHeight;

  const DisplayFittingInfo({
    required this.displayRect,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.displayedWidth,
    required this.displayedHeight,
  });

  @override
  String toString() =>
      'DisplayFittingInfo(scale: ${scale.toStringAsFixed(4)}, displayRect: $displayRect)';
}

class CoordinateConverter {
  /// Calculates the exact displayed rectangle and scaling factor of an image inside a viewport container using BoxFit.contain.
  static DisplayFittingInfo calculateDisplayFitting({
    required Size viewportSize,
    required Size imageSize,
  }) {
    if (viewportSize.width <= 0 ||
        viewportSize.height <= 0 ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return DisplayFittingInfo(
        displayRect: Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height),
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        displayedWidth: viewportSize.width,
        displayedHeight: viewportSize.height,
      );
    }

    final scaleX = viewportSize.width / imageSize.width;
    final scaleY = viewportSize.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final displayedWidth = imageSize.width * scale;
    final displayedHeight = imageSize.height * scale;

    final offsetX = (viewportSize.width - displayedWidth) / 2.0;
    final offsetY = (viewportSize.height - displayedHeight) / 2.0;

    final displayRect = Rect.fromLTWH(offsetX, offsetY, displayedWidth, displayedHeight);

    return DisplayFittingInfo(
      displayRect: displayRect,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
      displayedWidth: displayedWidth,
      displayedHeight: displayedHeight,
    );
  }

  /// Converts a single source point in image pixel coordinates to screen coordinates
  static Offset sourceToScreen({
    required double sourceX,
    required double sourceY,
    required Rect imageDisplayRect,
    required Size sourceImageSize,
  }) {
    if (sourceImageSize.width <= 0 || sourceImageSize.height <= 0) {
      return imageDisplayRect.topLeft;
    }
    final scaleX = imageDisplayRect.width / sourceImageSize.width;
    final scaleY = imageDisplayRect.height / sourceImageSize.height;
    return Offset(
      imageDisplayRect.left + (sourceX * scaleX),
      imageDisplayRect.top + (sourceY * scaleY),
    );
  }

  /// Converts a single screen point to source image pixel coordinates
  static Offset screenToSource({
    required double screenX,
    required double screenY,
    required Rect imageDisplayRect,
    required Size sourceImageSize,
  }) {
    if (imageDisplayRect.width <= 0 || imageDisplayRect.height <= 0) {
      return Offset.zero;
    }
    final scaleX = imageDisplayRect.width / sourceImageSize.width;
    final scaleY = imageDisplayRect.height / sourceImageSize.height;
    return Offset(
      ((screenX - imageDisplayRect.left) / scaleX).clamp(0.0, sourceImageSize.width),
      ((screenY - imageDisplayRect.top) / scaleY).clamp(0.0, sourceImageSize.height),
    );
  }

  /// Converts a screen crop rectangle (within imageDisplayRect) to pixel coordinates on the source image.
  static Rect screenToSourceRect({
    required Rect screenCropRect,
    required Rect imageDisplayRect,
    required Size sourceImageSize,
  }) {
    if (imageDisplayRect.width <= 0 ||
        imageDisplayRect.height <= 0 ||
        sourceImageSize.width <= 0 ||
        sourceImageSize.height <= 0) {
      return Rect.fromLTWH(0, 0, sourceImageSize.width, sourceImageSize.height);
    }

    final scaleX = imageDisplayRect.width / sourceImageSize.width;
    final scaleY = imageDisplayRect.height / sourceImageSize.height;

    // Relative to the imageDisplayRect origin
    final relLeft = screenCropRect.left - imageDisplayRect.left;
    final relTop = screenCropRect.top - imageDisplayRect.top;

    double sourceX = (relLeft / scaleX).clamp(0.0, sourceImageSize.width - 1.0);
    double sourceY = (relTop / scaleY).clamp(0.0, sourceImageSize.height - 1.0);
    double sourceW = (screenCropRect.width / scaleX).clamp(1.0, sourceImageSize.width - sourceX);
    double sourceH = (screenCropRect.height / scaleY).clamp(1.0, sourceImageSize.height - sourceY);

    return Rect.fromLTWH(sourceX, sourceY, sourceW, sourceH);
  }

  /// Converts source image pixel coordinates to screen coordinates inside imageDisplayRect.
  static Rect sourceToScreenRect({
    required Rect sourceCropRect,
    required Rect imageDisplayRect,
    required Size sourceImageSize,
  }) {
    if (sourceImageSize.width <= 0 ||
        sourceImageSize.height <= 0 ||
        imageDisplayRect.width <= 0 ||
        imageDisplayRect.height <= 0) {
      return imageDisplayRect;
    }

    final scaleX = imageDisplayRect.width / sourceImageSize.width;
    final scaleY = imageDisplayRect.height / sourceImageSize.height;

    double screenX = imageDisplayRect.left + (sourceCropRect.left * scaleX);
    double screenY = imageDisplayRect.top + (sourceCropRect.top * scaleY);
    double screenW = sourceCropRect.width * scaleX;
    double screenH = sourceCropRect.height * scaleY;

    // Clamp within imageDisplayRect
    screenX = screenX.clamp(imageDisplayRect.left, imageDisplayRect.right - 1.0);
    screenY = screenY.clamp(imageDisplayRect.top, imageDisplayRect.bottom - 1.0);
    screenW = screenW.clamp(10.0, imageDisplayRect.right - screenX);
    screenH = screenH.clamp(10.0, imageDisplayRect.bottom - screenY);

    return Rect.fromLTWH(screenX, screenY, screenW, screenH);
  }

  /// Adjusts a rectangle to strictly maintain targetAspectRatio (width / height) within bounds.
  static Rect enforceAspectRatio({
    required Rect rect,
    required double targetAspectRatio,
    required Rect bounds,
  }) {
    double w = rect.width;
    double h = rect.height;

    // Try keeping width and adjusting height
    h = w / targetAspectRatio;
    if (rect.top + h > bounds.bottom) {
      h = bounds.bottom - rect.top;
      w = h * targetAspectRatio;
    }
    if (rect.left + w > bounds.right) {
      w = bounds.right - rect.left;
      h = w / targetAspectRatio;
    }

    final left = rect.left.clamp(bounds.left, bounds.right - w);
    final top = rect.top.clamp(bounds.top, bounds.bottom - h);

    return Rect.fromLTWH(left, top, w, h);
  }
}
