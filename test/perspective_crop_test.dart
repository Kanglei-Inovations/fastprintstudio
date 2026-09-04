import 'dart:typed_data';
import 'dart:ui';
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/quad_points.dart';
import 'package:fastprintstudio/services/image/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Perspective Quad Warping & Manual Crop Tests', () {
    late Uint8List testImageBytes;

    setUp(() {
      // Create a test 800x600 image with distinct colored quadrants
      final image = img.Image(width: 800, height: 600);
      img.fill(image, color: img.ColorUint8.rgb(240, 240, 240));

      // Draw a colored trapezoid (skewed card)
      img.fillRect(image, x1: 150, y1: 100, x2: 650, y2: 450, color: img.ColorUint8.rgb(37, 99, 235));
      testImageBytes = ImageProcessor.encodePng(image);
    });

    test('WarpPerspective unskews 4 arbitrary corners into a clean rectangular image', () {
      final decoded = ImageProcessor.decode(testImageBytes)!;

      // 4 skewed corners representing a card photographed at an angle
      const quad = QuadPoints(
        topLeft: Offset(150, 120),
        topRight: Offset(640, 90),
        bottomRight: Offset(660, 480),
        bottomLeft: Offset(130, 440),
      );

      final unskewed = ImageProcessor.warpPerspective(
        decoded,
        quad,
        targetAspectRatio: 85.6 / 54.0, // Aadhaar standard aspect ratio
      );

      expect(unskewed.width, greaterThan(0));
      expect(unskewed.height, greaterThan(0));

      final ratio = unskewed.width / unskewed.height;
      expect((ratio - (85.6 / 54.0)).abs(), lessThan(0.02));
    });

    test('extractCropResult handles QuadPoints and returns valid CropResult', () {
      const quad = QuadPoints(
        topLeft: Offset(100, 100),
        topRight: Offset(500, 120),
        bottomRight: Offset(480, 400),
        bottomLeft: Offset(120, 380),
      );

      final result = ImageProcessor.extractCropResult(
        sourceBytes: testImageBytes,
        sourcePixelRect: const Rect.fromLTWH(100, 100, 400, 300),
        quadPoints: quad,
        rotationDegrees: 0,
        fineAngleDegrees: 2.5,
        targetAspectRatio: 35.0 / 45.0,
      );

      expect(result.croppedBytes, isNotEmpty);
      expect(result.quadPoints, isNotNull);
      expect(result.fineAngleDegrees, 2.5);
      expect(result.sourceWidth, greaterThanOrEqualTo(800));
      expect(result.sourceHeight, greaterThanOrEqualTo(600));
    });

    test('rotateArbitrary rotates image with fine angle precision', () {
      final decoded = ImageProcessor.decode(testImageBytes)!;
      final rotated = ImageProcessor.rotateArbitrary(decoded, 15.0);

      expect(rotated.width, greaterThan(0));
      expect(rotated.height, greaterThan(0));
    });

    test('CropRectData supports quad points and serialization', () {
      const quad = QuadPoints(
        topLeft: Offset(0.1, 0.1),
        topRight: Offset(0.9, 0.15),
        bottomRight: Offset(0.85, 0.85),
        bottomLeft: Offset(0.12, 0.8),
      );

      const crop = CropRectData(
        left: 0.1,
        top: 0.1,
        width: 0.8,
        height: 0.7,
        rotationDegrees: 90.0,
        fineAngleDegrees: -3.5,
        quadPoints: quad,
      );

      expect(crop.isQuad, isTrue);
      expect(crop.fineAngleDegrees, -3.5);
      expect(crop.rotationDegrees, 90.0);

      final json = crop.toJson();
      final fromJson = CropRectData.fromJson(json);
      expect(fromJson.fineAngleDegrees, -3.5);
      expect(fromJson.rotationDegrees, 90.0);
    });
  });
}
