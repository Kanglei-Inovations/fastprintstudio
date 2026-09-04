import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/services/image/background_remover_service.dart';

void main() {
  group('BackgroundRemoverService Tests', () {
    late Uint8List testImageBytes;

    setUp(() {
      // Create a 100x100 synthetic portrait test image:
      // Outer background: Gray (RGB: 210, 210, 210)
      // Inner subject: Blue circle/square in the center (RGB: 20, 40, 200)
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorUint8.rgb(210, 210, 210));

      // Draw subject in center (x: 25..75, y: 25..85)
      for (int y = 25; y < 85; y++) {
        for (int x = 25; x < 75; x++) {
          image.setPixelRgb(x, y, 20, 40, 200);
        }
      }

      testImageBytes = Uint8List.fromList(img.encodePng(image));
    });

    test('BackgroundRemoverConfig has sensible defaults and copyWith', () {
      const config = BackgroundRemoverConfig();
      expect(config.tolerance, equals(0.22));
      expect(config.featherRadius, equals(2));
      expect(config.replacementColorValue, isNull);

      final updated = config.copyWith(
        tolerance: 0.35,
        featherRadius: 4,
        replacementColorValue: 0xFFFFFFFF,
      );
      expect(updated.tolerance, equals(0.35));
      expect(updated.featherRadius, equals(4));
      expect(updated.replacementColorValue, equals(0xFFFFFFFF));
    });

    test('removeBackground removes background to transparent PNG', () {
      final cutoutBytes = BackgroundRemoverService.removeBackground(
        sourceBytes: testImageBytes,
        config: const BackgroundRemoverConfig(
          tolerance: 0.15,
          featherRadius: 1,
        ),
      );

      final result = img.decodePng(cutoutBytes);
      expect(result, isNotNull);
      if (result != null) {
        expect(result.width, equals(100));
        expect(result.height, equals(100));

        // Corner background should be transparent
        final cornerPixel = result.getPixel(2, 2);
        expect(cornerPixel.a, equals(0));

        // Center subject should remain opaque blue
        final centerPixel = result.getPixel(50, 50);
        expect(centerPixel.a, equals(255));
        expect(centerPixel.r, equals(20));
        expect(centerPixel.b, equals(200));
      }
    });

    test('removeBackground replaces background with custom color (pure white)', () {
      final cutoutBytes = BackgroundRemoverService.removeBackground(
        sourceBytes: testImageBytes,
        config: const BackgroundRemoverConfig(
          tolerance: 0.15,
          featherRadius: 0,
          replacementColorValue: 0xFFFFFFFF, // Pure white
        ),
      );

      final result = img.decodePng(cutoutBytes);
      expect(result, isNotNull);
      if (result != null) {
        // Corner background should now be white (255, 255, 255)
        final cornerPixel = result.getPixel(2, 2);
        expect(cornerPixel.r, equals(255));
        expect(cornerPixel.g, equals(255));
        expect(cornerPixel.b, equals(255));

        // Center subject should remain original blue
        final centerPixel = result.getPixel(50, 50);
        expect(centerPixel.r, equals(20));
        expect(centerPixel.g, equals(40));
        expect(centerPixel.b, equals(200));
      }
    });

    test('removeBackground replaces background with passport light blue', () {
      final cutoutBytes = BackgroundRemoverService.removeBackground(
        sourceBytes: testImageBytes,
        config: const BackgroundRemoverConfig(
          tolerance: 0.15,
          featherRadius: 0,
          replacementColorValue: 0xFFBAE6FD, // Light blue
        ),
      );

      final result = img.decodePng(cutoutBytes);
      expect(result, isNotNull);
      if (result != null) {
        // Corner background should now be light blue (0xBA = 186, 0xE6 = 230, 0xFD = 253)
        final cornerPixel = result.getPixel(2, 2);
        expect(cornerPixel.r, equals(0xBA));
        expect(cornerPixel.g, equals(0xE6));
        expect(cornerPixel.b, equals(0xFD));
      }
    });
  });
}
