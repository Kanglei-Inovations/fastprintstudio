import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/core/models/photo_group.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  group('Mixed Photo 4R Layout Packing Tests', () {
    late Uint8List dummyPassportBytes;
    late Uint8List dummyStampBytes;

    setUp(() {
      final passportImg = img.Image(width: 413, height: 531); // 35x45mm at 300 DPI
      img.fill(passportImg, color: img.ColorUint8.rgb(200, 50, 50));
      dummyPassportBytes = Uint8List.fromList(img.encodePng(passportImg));

      final stampImg = img.Image(width: 295, height: 354); // 25x30mm at 300 DPI
      img.fill(stampImg, color: img.ColorUint8.rgb(50, 150, 50));
      dummyStampBytes = Uint8List.fromList(img.encodePng(stampImg));
    });

    test('Arranges 8 Passport photos cleanly on 4R Sheet (Passport Only mode)', () {
      final passportGroup = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 8,
      ).copyWith(processedBytes: dummyPassportBytes);

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        groups: [passportGroup],
        orientation: PaperOrientation.landscape,
      );

      expect(layout.items.length, equals(8));
      expect(layout.allItemsFit, isTrue);
      expect(layout.warningMessage, isNull);

      // Verify physical sizing on landscape
      for (final item in layout.items) {
        expect(item.widthMm, closeTo(30.0 + 4.3, 0.5));
        expect(item.heightMm, closeTo(40.0 + 4.3, 0.5));
      }
    });

    test('Passport + Stamp mode packs 6 Passport and auto-fills remaining area with Stamp photos', () {
      final passportGroup = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 6,
      ).copyWith(processedBytes: dummyPassportBytes);

      final stampGroup = PhotoGroup.stamp(
        rawImageBytes: dummyStampBytes,
        copies: 4,
      ).copyWith(processedBytes: dummyStampBytes);

      final optimalStamps = LayoutEngine.calculateMaxStampCopies(
        paperPreset: StandardPaperPresets.fourR,
        passportGroup: passportGroup,
        stampGroup: stampGroup,
        orientation: PaperOrientation.landscape,
      );

      expect(optimalStamps, greaterThanOrEqualTo(3));

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        groups: [
          passportGroup,
          stampGroup.copyWith(copiesCount: optimalStamps),
        ],
        orientation: PaperOrientation.landscape,
      );

      expect(layout.items.length, equals(6 + optimalStamps));
      expect(layout.allItemsFit, isTrue);

      // Check no overlaps between any 2 photos
      for (int i = 0; i < layout.items.length; i++) {
        for (int j = i + 1; j < layout.items.length; j++) {
          final a = layout.items[i];
          final b = layout.items[j];

          final overlapsX = (a.xMm < b.rightMm - 0.1) && (a.rightMm > b.xMm + 0.1);
          final overlapsY = (a.yMm < b.bottomMm - 0.1) && (a.bottomMm > b.yMm + 0.1);

          expect(overlapsX && overlapsY, isFalse, reason: 'Items ${a.label} and ${b.label} overlap!');
        }
      }
    });

    test('Arranges Mixed 4R Sheet with 4 Passport (35x45mm) + 4 Stamp (25x30mm) photos', () {
      final passportGroup = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 4,
      ).copyWith(processedBytes: dummyPassportBytes);

      final stampGroup = PhotoGroup.stamp(
        rawImageBytes: dummyStampBytes,
        copies: 4,
      ).copyWith(processedBytes: dummyStampBytes);

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        groups: [passportGroup, stampGroup],
        orientation: PaperOrientation.portrait,
      );

      // Total 4 + 4 = 8 photos on the same 4R sheet
      expect(layout.items.length, equals(8));
      expect(layout.allItemsFit, isTrue);

      final passportItems = layout.items.where((i) => i.label.contains('Passport')).toList();
      final stampItems = layout.items.where((i) => i.label.contains('Stamp')).toList();

      expect(passportItems.length, equals(4));
      expect(stampItems.length, equals(4));

      // Verify no overlaps between any 2 items
      for (int i = 0; i < layout.items.length; i++) {
        for (int j = i + 1; j < layout.items.length; j++) {
          final a = layout.items[i];
          final b = layout.items[j];

          final overlapsX = (a.xMm < b.rightMm - 0.1) && (a.rightMm > b.xMm + 0.1);
          final overlapsY = (a.yMm < b.bottomMm - 0.1) && (a.bottomMm > b.yMm + 0.1);

          expect(overlapsX && overlapsY, isFalse, reason: 'Items ${a.label} and ${b.label} overlap!');
        }
      }
    });

    test('Detects and warns when photo combination exceeds 4R paper capacity', () {
      final excessivePassport = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 25, // 25 passport photos will not fit on 1 4R sheet
      ).copyWith(processedBytes: dummyPassportBytes);

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        groups: [excessivePassport],
        orientation: PaperOrientation.portrait,
      );

      expect(layout.allItemsFit, isFalse);
      expect(layout.warningMessage, isNotNull);
      expect(layout.warningMessage, contains('exceed'));
    });

    test('Paginates excessive photos across multiple sheets (16 Passport photos generate 2 full 4R sheets)', () {
      final excessivePassport = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 16, // 16 passport photos need 2 sheets of 8
      ).copyWith(processedBytes: dummyPassportBytes);

      final pages = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: StandardPaperPresets.fourR,
        groups: [excessivePassport],
        orientation: PaperOrientation.landscape,
      );

      expect(pages.length, equals(2));
      expect(pages[0].items.length, equals(8));
      expect(pages[1].items.length, equals(8));
      expect(pages[0].allItemsFit, isTrue);
      expect(pages[1].allItemsFit, isTrue);
    });

    test('Paginates multiple different persons across sheets when total exceeds 4R capacity', () {
      final person1 = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 6,
      ).copyWith(name: 'Person 1', processedBytes: dummyPassportBytes);

      final person2 = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 6,
      ).copyWith(name: 'Person 2', processedBytes: dummyPassportBytes);

      // Total 12 photos: Sheet 1 gets 8, Sheet 2 gets 4
      final pages = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: StandardPaperPresets.fourR,
        groups: [person1, person2],
        orientation: PaperOrientation.landscape,
      );

      expect(pages.length, equals(2));
      final totalPlaced = pages.fold<int>(0, (sum, p) => sum + p.items.length);
      expect(totalPlaced, equals(12));
      expect(pages[0].items.length, equals(8));
      expect(pages[1].items.length, equals(4));
    });

    test('Starts photos at Top and Left margin (not in middle) so remaining paper can be reused', () {
      final fewPassports = PhotoGroup.passport(
        rawImageBytes: dummyPassportBytes,
        copies: 2, // Only 2 photos on 4R paper
      ).copyWith(processedBytes: dummyPassportBytes);

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: StandardPaperPresets.fourR,
        groups: [fewPassports],
        orientation: PaperOrientation.landscape,
        marginMm: 3.0,
      );

      expect(layout.items.length, equals(2));
      // First item must start at margin (3mm), NOT centered in the middle of sheet
      final firstItem = layout.items.first;
      expect(firstItem.xMm, closeTo(3.0, 0.5));
      expect(firstItem.yMm, closeTo(3.0, 0.5));

      // Sheet height is 102mm; remaining paper below 55mm is completely blank!
      final maxBottom = layout.items.map((i) => i.bottomMm).reduce((a, b) => a > b ? a : b);
      expect(maxBottom, lessThan(55.0)); // Leaves >45mm clean uncut paper at bottom
    });
  });
}
