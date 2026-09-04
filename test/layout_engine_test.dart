import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/constants/photo_presets.dart';
import 'package:fastprintstudio/core/models/border_config.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  group('LayoutEngine Tests', () {
    late Uint8List validImageBytes;

    setUp(() {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorUint8.rgb(200, 200, 200));
      validImageBytes = Uint8List.fromList(img.encodePng(image));
    });

    test('calculatePhotoLayout computes accurate 4R landscape passport 8 copies', () {
      final layout = LayoutEngine.calculatePhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        photoPreset: StandardPhotoPresets.passport, // 35x45 mm
        borderConfig: const BorderConfig(outerBorderMm: 0.8, innerBorderMm: 0.25),
        photoBytes: validImageBytes,
        requestedCopies: 8,
        orientation: PaperOrientation.landscape,
      );

      expect(layout.paperPreset, equals(StandardPaperPresets.fourR));
      expect(layout.items.length, equals(8));
      expect(layout.allItemsFit, isTrue);
      expect(layout.warningMessage, isNull);

      // Verify each item's physical coordinates
      for (final item in layout.items) {
        expect(item.xMm, greaterThanOrEqualTo(0));
        expect(item.yMm, greaterThanOrEqualTo(0));
        expect(item.rightMm, lessThanOrEqualTo(layout.paperWidthMm + 0.1));
        expect(item.bottomMm, lessThanOrEqualTo(layout.paperHeightMm + 0.1));
      }
    });

    test('calculatePhotoLayout computes 6 copies on 4R portrait', () {
      final layout = LayoutEngine.calculatePhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        photoPreset: StandardPhotoPresets.passport,
        borderConfig: const BorderConfig(outerBorderMm: 0.8, innerBorderMm: 0.25),
        photoBytes: validImageBytes,
        requestedCopies: 6,
        orientation: PaperOrientation.portrait,
      );

      expect(layout.items.length, equals(6));
      expect(layout.allItemsFit, isTrue);
    });

    test('calculatePhotoLayout warns if requested copies exceed maximum paper capacity', () {
      final layout = LayoutEngine.calculatePhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        photoPreset: StandardPhotoPresets.passport,
        borderConfig: const BorderConfig(),
        photoBytes: validImageBytes,
        requestedCopies: 50, // Far exceeds 4R capacity
        orientation: PaperOrientation.portrait,
      );

      expect(layout.items.length, equals(layout.maxCapacity));
      expect(layout.warningMessage, isNotNull);
      expect(layout.warningMessage, contains('Requested 50 copies'));
    });

    test('calculateIdCardLayout positions Front at top and Back at bottom on 4R with exact gap', () {
      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: StandardPaperPresets.fourR, // 101.6 x 152.4 mm
        idPreset: StandardIDCardPresets.aadhaar, // 85.6 x 54.0 mm
        frontImageBytes: validImageBytes,
        backImageBytes: validImageBytes,
        gapMm: 5.0,
        marginMm: 4.0,
        orientation: PaperOrientation.portrait,
      );

      expect(layout.items.length, equals(2));
      expect(layout.allItemsFit, isTrue);

      final front = layout.items[0];
      final back = layout.items[1];

      expect(front.label, equals('Front'));
      expect(back.label, equals('Back'));

      // Both cards must have exact physical dimensions
      expect(front.widthMm, equals(85.6));
      expect(front.heightMm, equals(54.0));
      expect(back.widthMm, equals(85.6));
      expect(back.heightMm, equals(54.0));

      // Front and back must be horizontally centered on 4R (101.6mm)
      // (101.6 - 85.6) / 2 = 8.0 mm
      expect(front.xMm, closeTo(8.0, 0.01));
      expect(back.xMm, closeTo(8.0, 0.01));

      // Back must be placed exactly (front.bottom + gapMm)
      expect(back.yMm, closeTo(front.bottomMm + 5.0, 0.01));
    });

    test('calculateIdCardLayout swap front and back works correctly', () {
      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: StandardPaperPresets.fourR,
        idPreset: StandardIDCardPresets.aadhaar,
        frontImageBytes: validImageBytes,
        backImageBytes: validImageBytes,
        swapFrontBack: true,
      );

      expect(layout.items[0].label, equals('Back'));
      expect(layout.items[1].label, equals('Front'));
    });

    test('calculateDragonSheetLayout computes 10 items for 5 Duplex Card pairs on 200x300mm sheet', () {
      final cardList = List.generate(10, (_) => validImageBytes);
      final layout = LayoutEngine.calculateDragonSheetLayout(
        cardImages: cardList,
        isDuplex: true,
      );

      expect(layout.paperPreset, equals(StandardPaperPresets.dragonSheet200x300));
      expect(layout.items.length, equals(10));
      expect(layout.allItemsFit, isTrue);

      // Verify Front / Back alternating labels
      expect(layout.items[0].label, equals('Card 1 Front'));
      expect(layout.items[1].label, equals('Card 1 Back'));
      expect(layout.items[2].label, equals('Card 2 Front'));
      expect(layout.items[3].label, equals('Card 2 Back'));

      // Check all items fit within 200 x 300 mm
      for (final item in layout.items) {
        expect(item.widthMm, equals(85.6));
        expect(item.heightMm, equals(54.0));
        expect(item.xMm, greaterThanOrEqualTo(0));
        expect(item.yMm, greaterThanOrEqualTo(0));
        expect(item.rightMm, lessThanOrEqualTo(200.0));
        expect(item.bottomMm, lessThanOrEqualTo(300.0));
      }
    });

    test('calculateDragonSheetLayout computes 10 Single-side cards on 200x300mm sheet', () {
      final cardList = List.generate(10, (_) => validImageBytes);
      final layout = LayoutEngine.calculateDragonSheetLayout(
        cardImages: cardList,
        isDuplex: false,
      );

      expect(layout.items.length, equals(10));
      expect(layout.items[0].label, equals('Card 1'));
      expect(layout.items[9].label, equals('Card 10'));
    });

    test('calculateL805TrayLayout places single card on Epson tray with exact dimensions', () {
      final layout = LayoutEngine.calculateL805TrayLayout(
        cardImageBytes: validImageBytes,
        isFront: true,
      );

      expect(layout.paperPreset, equals(StandardPaperPresets.a4));
      expect(layout.items.length, equals(1));
      expect(layout.items.first.widthMm, equals(85.6));
      expect(layout.items.first.heightMm, equals(54.0));
      expect(layout.items.first.label, contains('Front'));
    });
  });
}
