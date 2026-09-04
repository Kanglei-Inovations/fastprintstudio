import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/models/id_card_workflow_type.dart';
import 'package:fastprintstudio/core/models/l805_calibration.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  group('Epson L805 PVC Tray Workflow & Layout Tests', () {
    final dummyBytes1 = Uint8List.fromList([1, 2, 3, 4]);
    final dummyBytes2 = Uint8List.fromList([5, 6, 7, 8]);

    test('1 Card Quantity on A4 carrier generates exactly 1 Slot item at standard coordinates', () {
      final layout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: dummyBytes1,
        slot2ImageBytes: null,
        isFrontPage: true,
      );

      expect(layout.items.length, 1);
      expect(layout.paperPreset.widthMm, 210.0);
      expect(layout.paperPreset.heightMm, 297.0);

      final item1 = layout.items[0];
      expect(item1.widthMm, closeTo(85.6, 0.01));
      expect(item1.heightMm, closeTo(54.0, 0.01));
      expect(item1.xMm, closeTo(62.2, 0.01));
      expect(item1.yMm, closeTo(42.0, 0.01));
    });

    test('2 Cards Quantity generates Slot 1 and Slot 2 with exact spacing', () {
      final layout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: dummyBytes1,
        slot2ImageBytes: dummyBytes2,
        isFrontPage: true,
      );

      expect(layout.items.length, 2);

      final slot1 = layout.items[0];
      final slot2 = layout.items[1];

      expect(slot1.xMm, closeTo(62.2, 0.01));
      expect(slot1.yMm, closeTo(42.0, 0.01));

      expect(slot2.xMm, closeTo(62.2, 0.01));
      expect(slot2.yMm, closeTo(108.0, 0.01));
      expect(slot2.widthMm, closeTo(85.6, 0.01));
      expect(slot2.heightMm, closeTo(54.0, 0.01));
    });

    test('Front and Back pages mathematically share identical physical coordinates (Zero Drift Registration)', () {
      final frontLayout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: dummyBytes1,
        slot2ImageBytes: dummyBytes2,
        isFrontPage: true,
      );

      final backLayout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: dummyBytes1,
        slot2ImageBytes: dummyBytes2,
        isFrontPage: false,
      );

      expect(frontLayout.items.length, backLayout.items.length);

      // Slot 1
      expect(frontLayout.items[0].xMm, equals(backLayout.items[0].xMm));
      expect(frontLayout.items[0].yMm, equals(backLayout.items[0].yMm));
      expect(frontLayout.items[0].widthMm, equals(backLayout.items[0].widthMm));
      expect(frontLayout.items[0].heightMm, equals(backLayout.items[0].heightMm));

      // Slot 2
      expect(frontLayout.items[1].xMm, equals(backLayout.items[1].xMm));
      expect(frontLayout.items[1].yMm, equals(backLayout.items[1].yMm));
      expect(frontLayout.items[1].widthMm, equals(backLayout.items[1].widthMm));
      expect(frontLayout.items[1].heightMm, equals(backLayout.items[1].heightMm));
    });

    test('Custom L805 calibration offsets apply accurately to slot positions', () {
      const customCal = L805Calibration(
        cardWidthMm: 86.0,
        cardHeightMm: 54.0,
        slot1XMm: 63.0,
        slot1YMm: 43.0,
        slot2XMm: 63.0,
        slot2YMm: 110.0,
        globalOffsetX: 1.5,
        globalOffsetY: -2.0,
      );

      final layout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: dummyBytes1,
        slot2ImageBytes: dummyBytes2,
        isFrontPage: true,
        calibration: customCal,
      );

      final slot1 = layout.items[0];
      final slot2 = layout.items[1];

      // Slot 1 effective: X = 63.0 + 1.5 = 64.5, Y = 43.0 - 2.0 = 41.0
      expect(slot1.xMm, closeTo(64.5, 0.01));
      expect(slot1.yMm, closeTo(41.0, 0.01));
      expect(slot1.widthMm, closeTo(86.0, 0.01));

      // Slot 2 effective: X = 63.0 + 1.5 = 64.5, Y = 110.0 - 2.0 = 108.0
      expect(slot2.xMm, closeTo(64.5, 0.01));
      expect(slot2.yMm, closeTo(108.0, 0.01));
    });

    test('Workflow types are distinct and preserve proper defaults', () {
      expect(IdCardWorkflowType.photoPaperLamination.defaultPricePerCard, 50.0);
      expect(IdCardWorkflowType.epsonL805.defaultPricePerCard, 100.0);
      expect(IdCardWorkflowType.dragonSheet.defaultPricePerCard, 100.0);
      expect(IdCardWorkflowType.epsonL805Pvc, equals(IdCardWorkflowType.epsonL805));
    });

    test('Existing 4R Photo Paper workflow is unaffected', () {
      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: StandardPaperPresets.fourR,
        idPreset: StandardIDCardPresets.aadhaar,
        frontImageBytes: dummyBytes1,
        backImageBytes: dummyBytes2,
      );

      expect(layout.items.length, 2);
      expect(layout.paperPreset.widthMm, 101.6);
      expect(layout.paperPreset.heightMm, 152.4);
    });
  });
}
