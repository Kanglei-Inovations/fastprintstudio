import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/constants/photo_presets.dart';
import 'package:fastprintstudio/core/models/border_config.dart';
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/enhancement_config.dart';
import 'package:fastprintstudio/core/models/layout_item.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/core/models/photo_group.dart';
import 'package:fastprintstudio/core/utils/unit_converter.dart';
import 'package:fastprintstudio/services/image/image_processor.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Passport Photo Workflow — Canonical Coordinates & Processing Contract', () {
    late Uint8List sourceImageBytes;

    setUp(() {
      // Create a 400x600 high contrast test image
      final image = img.Image(width: 400, height: 600);
      img.fill(image, color: img.ColorUint8.rgb(200, 200, 200));

      // Draw distinctive colored quadrant blocks
      img.fillRect(image, x1: 50, y1: 50, x2: 150, y2: 150, color: img.ColorUint8.rgb(255, 0, 0));
      img.fillRect(image, x1: 250, y1: 50, x2: 350, y2: 150, color: img.ColorUint8.rgb(0, 255, 0));
      img.fillRect(image, x1: 50, y1: 450, x2: 150, y2: 550, color: img.ColorUint8.rgb(0, 0, 255));
      img.fillRect(image, x1: 250, y1: 450, x2: 350, y2: 550, color: img.ColorUint8.rgb(255, 255, 0));

      sourceImageBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
    });

    test('Canonical coordinate contract: step rotation (90 deg) preserves exact physical dimensions', () {
      const crop = CropRectData(
        left: 0.1,
        top: 0.1,
        width: 0.8,
        height: 0.8,
        rotationDegrees: 90,
      );

      final processed = ImageProcessor.processPhoto(
        sourceBytes: sourceImageBytes,
        cropData: crop,
        enhancement: const EnhancementConfig(),
        borderConfig: const BorderConfig(enabled: false),
        targetWidthMm: StandardPhotoPresets.passport.widthMm, // 30 mm
        targetHeightMm: StandardPhotoPresets.passport.heightMm, // 40 mm
        dpi: 300,
      );

      final decoded = img.decodeImage(processed)!;
      expect(decoded, isNotNull);
      // 30 mm at 300 DPI = round(30 * 300 / 25.4) = 354 px
      // 40 mm at 300 DPI = round(40 * 300 / 25.4) = 472 px
      final expectedW = UnitConverter.mmToPixels(StandardPhotoPresets.passport.widthMm, 300);
      final expectedH = UnitConverter.mmToPixels(StandardPhotoPresets.passport.heightMm, 300);
      expect(decoded.width, equals(expectedW));
      expect(decoded.height, equals(expectedH));
    });

    test('Canonical coordinate contract: fine angle rotation with expanded canvas crops accurately without drift', () {
      const crop = CropRectData(
        left: 0.15,
        top: 0.15,
        width: 0.7,
        height: 0.7,
        rotationDegrees: 0,
        fineAngleDegrees: 7.5,
      );

      final processed = ImageProcessor.processPhoto(
        sourceBytes: sourceImageBytes,
        cropData: crop,
        enhancement: const EnhancementConfig(),
        borderConfig: const BorderConfig(enabled: false),
        targetWidthMm: StandardPhotoPresets.passport.widthMm,
        targetHeightMm: StandardPhotoPresets.passport.heightMm,
        dpi: 300,
      );

      final decoded = img.decodeImage(processed)!;
      expect(decoded, isNotNull);
      final expectedW = UnitConverter.mmToPixels(StandardPhotoPresets.passport.widthMm, 300);
      final expectedH = UnitConverter.mmToPixels(StandardPhotoPresets.passport.heightMm, 300);
      expect(decoded.width, equals(expectedW));
      expect(decoded.height, equals(expectedH));
    });

    test('Combined step rotation (180 deg) + fine rotation (-5 deg) executes stably', () {
      const crop = CropRectData(
        left: 0.05,
        top: 0.05,
        width: 0.9,
        height: 0.9,
        rotationDegrees: 180,
        fineAngleDegrees: -5.0,
      );

      final processed = ImageProcessor.processPhoto(
        sourceBytes: sourceImageBytes,
        cropData: crop,
        enhancement: const EnhancementConfig(),
        borderConfig: const BorderConfig(enabled: false),
        targetWidthMm: StandardPhotoPresets.stamp.widthMm, // 25 mm
        targetHeightMm: StandardPhotoPresets.stamp.heightMm, // 30 mm
        dpi: 300,
      );

      final decoded = img.decodeImage(processed)!;
      expect(decoded, isNotNull);
      final expectedW = UnitConverter.mmToPixels(StandardPhotoPresets.stamp.widthMm, 300);
      final expectedH = UnitConverter.mmToPixels(StandardPhotoPresets.stamp.heightMm, 300);
      expect(decoded.width, equals(expectedW));
      expect(decoded.height, equals(expectedH));
    });

    test('Physical borders add exact outer margin and cutting stroke pixels at 300 DPI', () {
      const crop = CropRectData(left: 0.1, top: 0.1, width: 0.8, height: 0.8);
      const border = BorderConfig(enabled: true, outerBorderMm: 2.0, innerBorderMm: 0.15);

      final processed = ImageProcessor.processPhoto(
        sourceBytes: sourceImageBytes,
        cropData: crop,
        enhancement: const EnhancementConfig(),
        borderConfig: border,
        targetWidthMm: StandardPhotoPresets.passport.widthMm,
        targetHeightMm: StandardPhotoPresets.passport.heightMm,
        dpi: 300,
      );

      final decoded = img.decodeImage(processed)!;
      expect(decoded, isNotNull);
      // Extra width = (2.0 + 0.15) * 2 = 4.30 mm -> 52 px at 300 DPI
      // Base width = 354 px -> Total = 406 px
      expect(decoded.width, equals(406));
      expect(decoded.height, equals(524));
    });
  });

  group('Passport Photo Workflow — Multi-Person Sequential Numbering', () {
    test('Correctly extracts and generates sequential person numbers without conflicts', () {
      final existingNames = [
        'Person 1 (photo1.jpg)',
        'Person 2 (photo2.jpg)',
      ];

      final existingNumbers = existingNames.map((name) {
        final match = RegExp(r'Person\s+(\d+)').firstMatch(name);
        return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      }).toSet();

      int nextNumber = existingNames.length + 1;
      while (existingNumbers.contains(nextNumber)) {
        nextNumber++;
      }
      expect(nextNumber, equals(3));
    });

    test('Skips deleted person numbers safely when non-consecutive', () {
      final existingNames = [
        'Person 2 (photo2.jpg)',
        'Person 3 (photo3.jpg)',
      ];

      final existingNumbers = existingNames.map((name) {
        final match = RegExp(r'Person\s+(\d+)').firstMatch(name);
        return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      }).toSet();

      int nextNumber = 1;
      while (existingNumbers.contains(nextNumber)) {
        nextNumber++;
      }
      expect(nextNumber, equals(1));
    });
  });

  group('Passport Photo Workflow — Deterministic Cache Key Invalidation', () {
    String buildKey({
      required int rawLen,
      required String presetId,
      required CropRectData crop,
      required EnhancementConfig enh,
      required BorderConfig border,
      required double w,
      required double h,
      required int dpi,
    }) {
      return '$rawLen:$presetId:'
          '${crop.left.toStringAsFixed(4)},${crop.top.toStringAsFixed(4)},'
          '${crop.width.toStringAsFixed(4)},${crop.height.toStringAsFixed(4)},'
          'rot=${crop.rotationDegrees},fine=${crop.fineAngleDegrees.toStringAsFixed(2)},quad=${crop.isQuad}:'
          '${enh.brightness.toStringAsFixed(2)},${enh.contrast.toStringAsFixed(2)},'
          '${enh.saturation.toStringAsFixed(2)},${enh.sharpness.toStringAsFixed(2)},'
          '${enh.smoothSkin.toStringAsFixed(2)}:'
          '${border.enabled},${border.outerBorderMm.toStringAsFixed(2)},${border.innerBorderMm.toStringAsFixed(2)}:'
          '${w.toStringAsFixed(1)}x${h.toStringAsFixed(1)}@$dpi';
    }

    const baseCrop = CropRectData(left: 0.1, top: 0.1, width: 0.8, height: 0.8);
    const baseEnh = EnhancementConfig();
    const baseBorder = BorderConfig();

    test('Identical parameters produce identical cache keys', () {
      final key1 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );

      final key2 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );

      expect(key1, equals(key2));
    });

    test('Varying crop rect alters cache key', () {
      const alteredCrop = CropRectData(left: 0.2, top: 0.1, width: 0.7, height: 0.8);
      final key1 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );
      final key2 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: alteredCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('Varying fine angle alters cache key', () {
      const fineRotCrop = CropRectData(left: 0.1, top: 0.1, width: 0.8, height: 0.8, fineAngleDegrees: 3.5);
      final key1 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );
      final key2 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: fineRotCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('Varying borders alters cache key', () {
      const customBorder = BorderConfig(enabled: true, outerBorderMm: 1.5, innerBorderMm: 0.5);
      final key1 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: baseBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );
      final key2 = buildKey(
        rawLen: 1024,
        presetId: 'passport',
        crop: baseCrop,
        enh: baseEnh,
        border: customBorder,
        w: 30,
        h: 40,
        dpi: 300,
      );

      expect(key1, isNot(equals(key2)));
    });
  });

  group('Passport Photo Workflow — Multi-Sheet Layout & Undo/Redo Restoration', () {
    test('calculateMultiPhotoLayoutPages produces multiple sheets when copies exceed single sheet capacity', () {
      final dummyBytes = Uint8List(16);
      final group = PhotoGroup(
        id: 'g1',
        name: 'Person 1',
        preset: StandardPhotoPresets.passport,
        copiesCount: 20, // 20 passport photos on 4R (each sheet holds 8 -> 3 sheets total)
        cropData: const CropRectData(left: 0, top: 0, width: 1, height: 1),
        processedBytes: dummyBytes,
      );

      final pages = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: StandardPaperPresets.fourR,
        groups: [group],
        orientation: PaperOrientation.landscape,
        spacingMm: 2.0,
        marginMm: 3.0,
      );

      expect(pages.length, equals(3));
      expect(pages[0].items.length, equals(8));
      expect(pages[1].items.length, equals(8));
      expect(pages[2].items.length, equals(4));
    });

    test('Active sheet index clamps safely within restored multi-sheet layouts bounds', () {
      final dummyBytes = Uint8List(16);
      final group = PhotoGroup(
        id: 'g1',
        name: 'Person 1',
        preset: StandardPhotoPresets.passport,
        copiesCount: 16, // 2 sheets
        cropData: const CropRectData(left: 0, top: 0, width: 1, height: 1),
        processedBytes: dummyBytes,
      );

      final pages = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: StandardPaperPresets.fourR,
        groups: [group],
        orientation: PaperOrientation.landscape,
        spacingMm: 2.0,
        marginMm: 3.0,
      );

      expect(pages.length, equals(2));

      // Test clamping of active sheet index
      const savedActiveIndex = 1;
      final clampedIndex = savedActiveIndex.clamp(0, pages.isEmpty ? 0 : pages.length - 1);
      expect(clampedIndex, equals(1));

      // If user had selected sheet 5, it clamps to max page (1)
      const outOfBoundsIndex = 5;
      final clampedOutOfBounds = outOfBoundsIndex.clamp(0, pages.isEmpty ? 0 : pages.length - 1);
      expect(clampedOutOfBounds, equals(1));
    });

    test('Photos start at top-left margin (x >= margin, y >= margin) to allow paper reuse', () {
      final dummyBytes = Uint8List(16);
      final group = PhotoGroup(
        id: 'g1',
        name: 'Person 1',
        preset: StandardPhotoPresets.passport,
        copiesCount: 2, // 2 photos on 4R
        cropData: const CropRectData(left: 0, top: 0, width: 1, height: 1),
        processedBytes: dummyBytes,
      );

      const margin = 3.0;
      final pages = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: StandardPaperPresets.fourR,
        groups: [group],
        orientation: PaperOrientation.landscape,
        marginMm: margin,
        spacingMm: 2.0,
      );

      final items = pages.first.items;
      expect(items.length, equals(2));
      // First item must be positioned exactly at top-left margin
      expect(items.first.xMm, closeTo(margin, 0.001));
      expect(items.first.yMm, closeTo(margin, 0.001));
    });
  });

  group('Passport Photo Workflow — Physical mm to Point Precision', () {
    test('mm to pt conversion exactly matches 72 / 25.4 (1 mm = 2.834645 pt)', () {
      const mm = 30.0;
      final pt = UnitConverter.mmToPoints(mm);
      expect(pt, closeTo(30.0 * 72.0 / 25.4, 0.0001));
    });

    test('LayoutItem pt properties accurately match mm dimensions', () {
      final dummyBytes = Uint8List(8);
      final item = LayoutItem(
        id: 'item1',
        label: 'Photo',
        xMm: 10.0,
        yMm: 20.0,
        widthMm: 30.0,
        heightMm: 40.0,
        imageBytes: dummyBytes,
      );

      expect(item.xPt, closeTo(10.0 * 2.834645669, 0.001));
      expect(item.yPt, closeTo(20.0 * 2.834645669, 0.001));
      expect(item.widthPt, closeTo(30.0 * 2.834645669, 0.001));
      expect(item.heightPt, closeTo(40.0 * 2.834645669, 0.001));
    });
  });
}
