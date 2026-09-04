import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/enhancement_config.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/core/utils/coordinate_converter.dart';
import 'package:fastprintstudio/core/utils/unit_converter.dart';
import 'package:fastprintstudio/services/image/image_processor.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  group('Aadhaar Crop & 4R Preview Pipeline Tests', () {
    late Uint8List a4PageBytes;
    const pageWidth = 2480.0;
    const pageHeight = 3508.0;

    // Simulated Aadhaar card located on the A4 page
    // Left: 150 px, Top: 2200 px, Width: 1011 px, Height: 638 px (Ratio ~ 1.585)
    const cardRect = Rect.fromLTWH(150, 2200, 1011, 638);

    setUp(() {
      final a4 = img.Image(width: pageWidth.toInt(), height: pageHeight.toInt());
      img.fill(a4, color: img.ColorUint8.rgb(240, 240, 240));

      // Draw distinctive pattern on the card area to verify extraction
      final cardColor = img.ColorUint8.rgb(50, 100, 200);
      img.fillRect(
        a4,
        x1: cardRect.left.toInt(),
        y1: cardRect.top.toInt(),
        x2: cardRect.right.toInt(),
        y2: cardRect.bottom.toInt(),
        color: cardColor,
      );

      // Draw top-left marker on card
      img.fillRect(
        a4,
        x1: cardRect.left.toInt(),
        y1: cardRect.top.toInt(),
        x2: (cardRect.left + 50).toInt(),
        y2: (cardRect.top + 50).toInt(),
        color: img.ColorUint8.rgb(255, 0, 0),
      );

      a4PageBytes = Uint8List.fromList(img.encodePng(a4));
    });

    test('Crop editor viewport mapping correctly maps displayed card to original pixel coordinates', () {
      // Crop editor viewport container size
      const viewportSize = Size(900, 650);
      const imageSize = Size(pageWidth, pageHeight);

      // 1. Calculate display fitting
      final fitting = CoordinateConverter.calculateDisplayFitting(
        viewportSize: viewportSize,
        imageSize: imageSize,
      );

      // Verify that portrait A4 is fitted by height and centered horizontally
      expect(fitting.displayedHeight, equals(viewportSize.height));
      expect(fitting.scale, closeTo(650.0 / 3508.0, 0.0001));
      expect(fitting.offsetX, greaterThan(0)); // Letterbox margins on left and right

      // 2. User sees card on screen and selects it:
      final screenCropRect = CoordinateConverter.sourceToScreenRect(
        sourceCropRect: cardRect,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: imageSize,
      );

      // 3. CoordinateConverter converts screen selection back to source coordinates:
      final extractedSourceRect = CoordinateConverter.screenToSourceRect(
        screenCropRect: screenCropRect,
        imageDisplayRect: fitting.displayRect,
        sourceImageSize: imageSize,
      );

      // Must be EXACTLY identical to the card rect in original image pixels!
      expect(extractedSourceRect.left, closeTo(cardRect.left, 0.5));
      expect(extractedSourceRect.top, closeTo(cardRect.top, 0.5));
      expect(extractedSourceRect.width, closeTo(cardRect.width, 0.5));
      expect(extractedSourceRect.height, closeTo(cardRect.height, 0.5));
    });

    test('Extracted CropResult contains exact card pixels with zero shift or cut off', () {
      final cropResult = ImageProcessor.extractCropResult(
        sourceBytes: a4PageBytes,
        sourcePixelRect: cardRect,
        targetAspectRatio: StandardIDCardPresets.aadhaar.aspectRatio,
      );

      expect(cropResult.sourceWidth, equals(pageWidth.toInt()));
      expect(cropResult.sourceHeight, equals(pageHeight.toInt()));
      expect(cropResult.sourceRect, equals(cardRect));

      final croppedImage = img.decodeImage(cropResult.croppedBytes);
      expect(croppedImage, isNotNull);
      expect(croppedImage!.width, equals(cardRect.width.toInt()));
      expect(croppedImage.height, equals(cardRect.height.toInt()));

      // Verify top-left marker (red) is preserved at (0, 0) of cropped card
      final p0 = croppedImage.getPixel(10, 10);
      expect(p0.r.toInt(), equals(255)); // Red marker present
      expect(p0.g.toInt(), equals(0));
      expect(p0.b.toInt(), equals(0));

      // Verify body pixel (blue) is present at center of card
      final pCenter = croppedImage.getPixel(500, 300);
      expect(pCenter.r.toInt(), equals(50));
      expect(pCenter.g.toInt(), equals(100));
      expect(pCenter.b.toInt(), equals(200));
    });

    test('4R layout engine places Aadhaar card using exact physical 85.6x54mm dimensions', () {
      // Resize to physical dimensions at 300 DPI
      final resizedFront = ImageProcessor.processCard(
        sourceBytes: a4PageBytes,
        cropData: CropRectData(
          left: cardRect.left / pageWidth,
          top: cardRect.top / pageHeight,
          width: cardRect.width / pageWidth,
          height: cardRect.height / pageHeight,
        ),
        enhancement: const EnhancementConfig(),
        targetWidthMm: StandardIDCardPresets.aadhaar.widthMm,
        targetHeightMm: StandardIDCardPresets.aadhaar.heightMm,
        dpi: 300,
      );

      final frontDecoded = img.decodeImage(resizedFront);
      expect(frontDecoded, isNotNull);

      // Verify 300 DPI pixel dimensions
      // 85.6 mm -> 1011 px, 54.0 mm -> 638 px
      final expectedW = UnitConverter.mmToPixels(85.6, 300);
      final expectedH = UnitConverter.mmToPixels(54.0, 300);
      expect(frontDecoded!.width, equals(expectedW));
      expect(frontDecoded.height, equals(expectedH));

      // Layout on 4R Paper (101.6 x 152.4 mm)
      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: StandardPaperPresets.fourR,
        idPreset: StandardIDCardPresets.aadhaar,
        frontImageBytes: resizedFront,
        backImageBytes: resizedFront,
        gapMm: 5.0,
        marginMm: 4.0,
        orientation: PaperOrientation.portrait,
      );

      expect(layout.items.length, equals(2));
      expect(layout.allItemsFit, isTrue);

      final front = layout.items[0];
      final back = layout.items[1];

      // Physical millimeter sizing verification
      expect(front.widthMm, equals(85.6));
      expect(front.heightMm, equals(54.0));
      expect(back.widthMm, equals(85.6));
      expect(back.heightMm, equals(54.0));

      // Centering verification: (101.6 - 85.6) / 2 = 8.0 mm
      expect(front.xMm, closeTo(8.0, 0.01));
      expect(back.xMm, closeTo(8.0, 0.01));

      // Gap verification: back.y = front.y + 54 + 5.0
      expect(back.yMm, closeTo(front.bottomMm + 5.0, 0.01));
    });
  });
}
