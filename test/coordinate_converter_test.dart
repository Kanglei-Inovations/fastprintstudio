import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/core/utils/coordinate_converter.dart';

void main() {
  group('CoordinateConverter Tests', () {
    test('Converts exact 4000x3000 source to 800x600 viewport display coordinates', () {
      const sourceSize = Size(4000, 3000);
      const viewportSize = Size(800, 600);

      final fitting = CoordinateConverter.calculateDisplayFitting(
        viewportSize: viewportSize,
        imageSize: sourceSize,
      );

      expect(fitting.scale, closeTo(0.2, 0.001));
      expect(fitting.offsetX, closeTo(0.0, 0.001));
      expect(fitting.offsetY, closeTo(0.0, 0.001));
      expect(fitting.displayedWidth, closeTo(800.0, 0.001));
      expect(fitting.displayedHeight, closeTo(600.0, 0.001));

      // User selects on display: left=100, top=50, width=400, height=300
      const screenCrop = Rect.fromLTWH(100, 50, 400, 300);

      final sourceRect = CoordinateConverter.screenToSourceRect(
        screenCropRect: screenCrop,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: sourceSize,
      );

      // Expected: left=500, top=250, width=2000, height=1500
      expect(sourceRect.left, closeTo(500.0, 0.01));
      expect(sourceRect.top, closeTo(250.0, 0.01));
      expect(sourceRect.width, closeTo(2000.0, 0.01));
      expect(sourceRect.height, closeTo(1500.0, 0.01));

      // Round-trip conversion back to screen
      final backToScreen = CoordinateConverter.sourceToScreenRect(
        sourceCropRect: sourceRect,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: sourceSize,
      );

      expect(backToScreen.left, closeTo(100.0, 0.01));
      expect(backToScreen.top, closeTo(50.0, 0.01));
      expect(backToScreen.width, closeTo(400.0, 0.01));
      expect(backToScreen.height, closeTo(300.0, 0.01));
    });

    test('Handles letterboxed portrait document inside landscape viewport correctly', () {
      // Standard A4 PDF rendered at 300 DPI: 2480 x 3508
      const sourceSize = Size(2480, 3508);
      const viewportSize = Size(800, 600);

      final fitting = CoordinateConverter.calculateDisplayFitting(
        viewportSize: viewportSize,
        imageSize: sourceSize,
      );

      // Scale is limited by height: 600 / 3508 ≈ 0.1710376
      expect(fitting.scale, closeTo(600.0 / 3508.0, 0.0001));
      expect(fitting.offsetY, closeTo(0.0, 0.001));
      // Displayed width = 2480 * (600 / 3508) ≈ 424.173
      expect(fitting.displayedWidth, closeTo(2480.0 * (600.0 / 3508.0), 0.01));
      // Left/Right letterbox margins: (800 - 424.173) / 2 ≈ 187.913
      expect(fitting.offsetX, greaterThan(180.0));

      // Screen crop positioned inside the displayed image:
      // left = offsetX + 50, top = 100, width = 200, height = 150
      final screenCrop = Rect.fromLTWH(fitting.offsetX + 50, 100, 200, 150);

      final sourceRect = CoordinateConverter.screenToSourceRect(
        screenCropRect: screenCrop,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: sourceSize,
      );

      // Verify that sourceX is accurately measured from the image boundary, not viewport boundary!
      final expectedSourceX = 50.0 / fitting.scale;
      final expectedSourceY = 100.0 / fitting.scale;
      final expectedSourceW = 200.0 / fitting.scale;
      final expectedSourceH = 150.0 / fitting.scale;

      expect(sourceRect.left, closeTo(expectedSourceX, 0.1));
      expect(sourceRect.top, closeTo(expectedSourceY, 0.1));
      expect(sourceRect.width, closeTo(expectedSourceW, 0.1));
      expect(sourceRect.height, closeTo(expectedSourceH, 0.1));
    });

    test('Clamps crop rectangle within source image boundaries', () {
      const sourceSize = Size(1000, 800);
      const viewportSize = Size(500, 400);

      final fitting = CoordinateConverter.calculateDisplayFitting(
        viewportSize: viewportSize,
        imageSize: sourceSize,
      );

      // Oversized screen crop exceeding bounds
      const screenCrop = Rect.fromLTWH(-50, -50, 600, 500);

      final sourceRect = CoordinateConverter.screenToSourceRect(
        screenCropRect: screenCrop,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: sourceSize,
      );

      expect(sourceRect.left, greaterThanOrEqualTo(0.0));
      expect(sourceRect.top, greaterThanOrEqualTo(0.0));
      expect(sourceRect.right, lessThanOrEqualTo(sourceSize.width));
      expect(sourceRect.bottom, lessThanOrEqualTo(sourceSize.height));
    });

    test('Maintains Aadhaar 85.6 / 54.0 aspect ratio correctly', () {
      const targetRatio = 85.6 / 54.0; // ~ 1.585185
      const bounds = Rect.fromLTWH(0, 0, 500, 400);
      const initialRect = Rect.fromLTWH(50, 50, 200, 200);

      final adjusted = CoordinateConverter.enforceAspectRatio(
        rect: initialRect,
        targetAspectRatio: targetRatio,
        bounds: bounds,
      );

      expect(adjusted.width / adjusted.height, closeTo(targetRatio, 0.001));
      expect(adjusted.left, greaterThanOrEqualTo(bounds.left));
      expect(adjusted.right, lessThanOrEqualTo(bounds.right));
      expect(adjusted.top, greaterThanOrEqualTo(bounds.top));
      expect(adjusted.bottom, lessThanOrEqualTo(bounds.bottom));
    });
  });
}
