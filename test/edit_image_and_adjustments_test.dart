import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/crop_result.dart';
import 'package:fastprintstudio/core/models/enhancement_config.dart';
import 'package:fastprintstudio/services/image/image_processor.dart';
import 'package:fastprintstudio/shared/widgets/crop_editor_modal.dart';

void main() {
  group('Edit Image Modal & Adjustments Integration Tests', () {
    late List<int> testImagePngBytes;

    setUp(() {
      final image = img.Image(width: 400, height: 400);
      img.fill(image, color: img.ColorUint8.rgb(120, 140, 180));
      testImagePngBytes = img.encodePng(image);
    });

    test('CropResult model holds optional EnhancementConfig', () {
      const enhancement = EnhancementConfig(
        brightness: 0.15,
        contrast: 1.1,
        sharpness: 0.25,
        smoothSkin: 0.3,
      );

      final cropResult = CropResult(
        sourceRect: const Rect.fromLTWH(50, 50, 200, 200),
        croppedBytes: Uint8List.fromList(testImagePngBytes),
        sourceWidth: 400,
        sourceHeight: 400,
        rotationDegrees: 90,
        fineAngleDegrees: 1.5,
        targetAspectRatio: 35.0 / 45.0,
        enhancement: enhancement,
      );

      expect(cropResult.enhancement, isNotNull);
      expect(cropResult.enhancement!.brightness, equals(0.15));
      expect(cropResult.enhancement!.contrast, equals(1.1));
      expect(cropResult.enhancement!.sharpness, equals(0.25));
      expect(cropResult.enhancement!.smoothSkin, equals(0.3));
    });

    test('ImageProcessor.extractCropResult applies crop and enhancements seamlessly', () {
      const enhancement = EnhancementConfig(
        brightness: 0.2,
        contrast: 1.2,
        sharpness: 0.1,
      );

      final result = ImageProcessor.extractCropResult(
        sourceBytes: Uint8List.fromList(testImagePngBytes),
        sourcePixelRect: const Rect.fromLTWH(0, 0, 200, 200),
        rotationDegrees: 0,
        fineAngleDegrees: 0.0,
        enhancement: enhancement,
      );

      expect(result.croppedBytes, isNotEmpty);
      expect(result.enhancement, equals(enhancement));
      final decoded = img.decodePng(result.croppedBytes);
      expect(decoded, isNotNull);
      if (decoded != null) {
        expect(decoded.width, equals(200));
        expect(decoded.height, equals(200));
      }
    });

    test('CropEditorModal defaults to title "Edit Image" and accepts initialEnhancement', () {
      final modal = CropEditorModal(
        imageBytes: Uint8List.fromList(testImagePngBytes),
        initialCrop: const CropRectData(left: 0.1, top: 0.1, width: 0.8, height: 0.8),
        initialEnhancement: const EnhancementConfig(brightness: 0.1, contrast: 1.05),
      );

      expect(modal.title, equals('Edit Image'));
      expect(modal.initialEnhancement, isNotNull);
      expect(modal.initialEnhancement!.brightness, equals(0.1));
      expect(modal.initialEnhancement!.contrast, equals(1.05));
    });
  });
}
