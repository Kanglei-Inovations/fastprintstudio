import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/models/border_config.dart';
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/enhancement_config.dart';
import 'package:fastprintstudio/services/image/image_processor.dart';

void main() {
  group('ImageProcessor Tests', () {
    late img.Image testImage;

    setUp(() {
      testImage = img.Image(width: 200, height: 200);
      img.fill(testImage, color: img.ColorUint8.rgb(100, 150, 200));
    });

    test('cropNormalized accurately crops pixel region', () {
      const cropData = CropRectData(left: 0.25, top: 0.25, width: 0.5, height: 0.5);
      final cropped = ImageProcessor.cropNormalized(testImage, cropData);

      expect(cropped.width, equals(100));
      expect(cropped.height, equals(100));
    });

    test('rotate rotates by 90 degrees', () {
      final nonSquare = img.Image(width: 100, height: 200);
      final rotated = ImageProcessor.rotate(nonSquare, 90);

      expect(rotated.width, equals(200));
      expect(rotated.height, equals(100));
    });

    test('adjustEnhancements applies brightness and contrast', () {
      const enhancement = EnhancementConfig(brightness: 0.2, contrast: 1.2);
      final enhanced = ImageProcessor.adjustEnhancements(testImage, enhancement);

      expect(enhanced.width, equals(testImage.width));
      expect(enhanced.height, equals(testImage.height));
    });

    test('resizeToPhysical resizes to exact DPI pixel dimensions', () {
      // 35mm x 45mm at 300 DPI -> 413 x 531 px
      final resized = ImageProcessor.resizeToPhysical(
        testImage,
        targetWidthMm: 35.0,
        targetHeightMm: 45.0,
        dpi: 300,
      );

      expect(resized.width, equals(413));
      expect(resized.height, equals(531));
    });

    test('applyBorders adds Stroke after Outer White Margin on the outermost perimeter', () {
      const borderConfig = BorderConfig(
        enabled: true,
        outerBorderMm: 1.0, // 1mm white margin
        innerBorderMm: 0.5, // 0.5mm stroke on outer edge
      );

      final withBorders = ImageProcessor.applyBorders(
        testImage,
        borderConfig: borderConfig,
        dpi: 300,
      );

      final outerPx = borderConfig.outerBorderPx(300);
      final strokePx = borderConfig.innerBorderPx(300);
      final expectedExtra = (outerPx + strokePx) * 2;

      expect(withBorders.width, equals(testImage.width + expectedExtra));
      expect(withBorders.height, equals(testImage.height + expectedExtra));

      // Outermost pixel (0, 0) is the cutting stroke (black)
      final cornerPixel = withBorders.getPixel(0, 0);
      expect(cornerPixel.r, equals(0));
      expect(cornerPixel.g, equals(0));
      expect(cornerPixel.b, equals(0));

      // Pixel inside the white margin is pure white (255, 255, 255)
      final whiteMarginPixel = withBorders.getPixel(strokePx + 1, strokePx + 1);
      expect(whiteMarginPixel.r, equals(255));
      expect(whiteMarginPixel.g, equals(255));
      expect(whiteMarginPixel.b, equals(255));
    });
  });
}
