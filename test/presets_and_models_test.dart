import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/constants/photo_presets.dart';
import 'package:fastprintstudio/core/models/app_settings.dart';
import 'package:fastprintstudio/core/models/border_config.dart';
import 'package:fastprintstudio/core/models/crop_rect_data.dart';
import 'package:fastprintstudio/core/models/enhancement_config.dart';
import 'package:fastprintstudio/core/models/print_history_item.dart';

void main() {
  group('Presets & Models Tests', () {
    test('StandardPaperPresets contains 4R and A4', () {
      expect(StandardPaperPresets.fourR.widthMm, equals(101.6));
      expect(StandardPaperPresets.fourR.heightMm, equals(152.4));
      expect(StandardPaperPresets.a4.widthMm, equals(210.0));
      expect(StandardPaperPresets.a4.heightMm, equals(297.0));

      final fourR = StandardPaperPresets.getById('4r');
      expect(fourR.id, equals('4r'));
    });

    test('StandardPhotoPresets contains Passport and Stamp', () {
      expect(StandardPhotoPresets.passport.widthMm, equals(30.0));
      expect(StandardPhotoPresets.passport.heightMm, equals(40.0));
      expect(StandardPhotoPresets.stamp.widthMm, equals(25.0));
      expect(StandardPhotoPresets.stamp.heightMm, equals(30.0));
    });

    test('StandardIDCardPresets contains Aadhaar and PAN Card', () {
      expect(StandardIDCardPresets.aadhaar.widthMm, equals(85.6));
      expect(StandardIDCardPresets.aadhaar.heightMm, equals(54.0));
      expect(StandardIDCardPresets.panCard.widthMm, equals(85.6));
      expect(StandardIDCardPresets.panCard.heightMm, equals(54.0));
    });

    test('CropRectData centeredWithAspectRatio produces valid bounds', () {
      final crop = CropRectData.centeredWithAspectRatio(35 / 45); // Passport ratio
      expect(crop.left, greaterThanOrEqualTo(0.0));
      expect(crop.top, greaterThanOrEqualTo(0.0));
      expect(crop.right, lessThanOrEqualTo(1.0));
      expect(crop.bottom, lessThanOrEqualTo(1.0));
      expect(crop.aspectRatio, closeTo(35 / 45, 0.01));
    });

    test('BorderConfig and EnhancementConfig JSON serialization', () {
      const border = BorderConfig(outerBorderMm: 1.2, innerBorderMm: 0.4);
      final borderJson = border.toJson();
      final borderRestored = BorderConfig.fromJson(borderJson);
      expect(borderRestored.outerBorderMm, equals(1.2));
      expect(borderRestored.innerBorderMm, equals(0.4));

      const enhancement = EnhancementConfig(brightness: 0.1, contrast: 1.1, sharpness: 0.5, rotationDegrees: 90);
      final enhJson = enhancement.toJson();
      final enhRestored = EnhancementConfig.fromJson(enhJson);
      expect(enhRestored.brightness, equals(0.1));
      expect(enhRestored.contrast, equals(1.1));
      expect(enhRestored.rotationDegrees, equals(90));
    });

    test('AppSettings JSON serialization', () {
      const settings = AppSettings(
        defaultDpi: 600,
        defaultPaperPresetId: 'a4',
        enableAutoCleanup: true,
      );
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.defaultDpi, equals(600));
      expect(restored.defaultPaperPresetId, equals('a4'));
      expect(restored.enableAutoCleanup, isTrue);
    });

    test('PrintHistoryItem JSON serialization', () {
      final history = PrintHistoryItem(
        id: '123',
        timestamp: DateTime(2026, 8, 30, 10, 0),
        serviceName: 'Aadhaar Card',
        paperName: '4R',
        copiesCount: 2,
        printerName: 'Epson L805',
        status: 'Printed',
        dimensionsSummary: '85.6 × 54 mm (2 cards)',
      );
      final json = history.toJson();
      final restored = PrintHistoryItem.fromJson(json);
      expect(restored.id, equals('123'));
      expect(restored.serviceName, equals('Aadhaar Card'));
      expect(restored.copiesCount, equals(2));
      expect(restored.status, equals('Printed'));
    });
  });
}
