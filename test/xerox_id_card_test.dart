import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/models/id_card_entry.dart';
import 'package:fastprintstudio/core/models/id_card_workflow_type.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/providers/id_card_provider.dart';
import 'package:fastprintstudio/providers/pricing_provider.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';
import 'package:fastprintstudio/services/storage/pricing_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyFront1 = Uint8List.fromList([1, 1, 1, 1]);
  final dummyBack1 = Uint8List.fromList([1, 2, 2, 1]);
  final dummyFront2 = Uint8List.fromList([2, 1, 1, 2]);
  final dummyBack2 = Uint8List.fromList([2, 2, 2, 2]);
  final dummyFront3 = Uint8List.fromList([3, 1, 1, 3]);
  final dummyBack3 = Uint8List.fromList([3, 2, 2, 3]);

  final card1 = IdCardEntry(
    id: 'c1',
    name: 'Person 1',
    rawBytes: dummyFront1,
    isPdf: false,
    renderedPages: [dummyFront1],
    selectedPageIndex: 0,
    hasBothSides: true,
    frontBytes: dummyFront1,
    backBytes: dummyBack1,
  );

  final card2 = IdCardEntry(
    id: 'c2',
    name: 'Person 2',
    rawBytes: dummyFront2,
    isPdf: false,
    renderedPages: [dummyFront2],
    selectedPageIndex: 0,
    hasBothSides: true,
    frontBytes: dummyFront2,
    backBytes: dummyBack2,
  );

  final card3 = IdCardEntry(
    id: 'c3',
    name: 'Person 3',
    rawBytes: dummyFront3,
    isPdf: false,
    renderedPages: [dummyFront3],
    selectedPageIndex: 0,
    hasBothSides: true,
    frontBytes: dummyFront3,
    backBytes: dummyBack3,
  );

  group('Xerox Workflow Type Model Definition', () {
    test('Xerox enum properties and defaults', () {
      const type = IdCardWorkflowType.xerox;
      expect(type.label, equals('Xerox'));
      expect(type.defaultPricePerCard, equals(10.0));
      expect(type.description, contains('Paper'));
      expect(type.frontRotationDegrees, equals(0));
      expect(type.backRotationDegrees, equals(0));
      expect(type.defaultSpacingMm, equals(6.0));
      expect(type.defaultMarginMm, equals(5.0));
    });

    test('Orientation contract: Xerox Back has 0° rotation, Lamination has 180° rotation', () {
      expect(IdCardWorkflowType.xerox.backRotationDegrees, equals(0));
      expect(IdCardWorkflowType.photoPaperLamination.backRotationDegrees, equals(180));
    });

    test('Xerox is placed last after Dragon Sheet in enum values', () {
      expect(IdCardWorkflowType.values.last, equals(IdCardWorkflowType.xerox));
    });
  });

  group('Xerox Layout Engine Tests', () {
    test('Single duplex card: Front 0° above Back 0° with configurable gap', () {
      final layouts = LayoutEngine.calculateMultiXeroxLayoutPages(
        paperPreset: StandardPaperPresets.a4,
        idPreset: StandardIDCardPresets.aadhaar,
        cards: [card1],
        orientation: PaperOrientation.portrait,
        marginMm: 5.0,
        gapMm: 6.0,
        showCutLines: true,
      );

      expect(layouts.length, equals(1));
      final page = layouts.first;
      expect(page.items.length, equals(2));
      expect(page.serviceType, equals('Xerox (Front + Back Paper Copy)'));
      expect(page.showDragonCutLines, isFalse);

      final frontItem = page.items[0];
      final backItem = page.items[1];

      // Physical mm preserved
      expect(frontItem.widthMm, closeTo(85.6, 0.01));
      expect(frontItem.heightMm, closeTo(54.0, 0.01));
      expect(backItem.widthMm, closeTo(85.6, 0.01));
      expect(backItem.heightMm, closeTo(54.0, 0.01));

      // Orientation contract: 0° for both
      expect(frontItem.rotationDegrees, equals(0));
      expect(backItem.rotationDegrees, equals(0));

      // Front vertically above Back
      expect(frontItem.yMm, lessThan(backItem.yMm));
      final actualGap = backItem.yMm - frontItem.bottomMm;
      expect(actualGap, closeTo(6.0, 0.01));

      // Horizontally aligned and centered
      expect(frontItem.xMm, closeTo(backItem.xMm, 0.01));
      final pageMidX = page.paperWidthMm / 2.0;
      final frontMidX = frontItem.xMm + (frontItem.widthMm / 2.0);
      expect(frontMidX, closeTo(pageMidX, 0.01));

      // Vertically centered on A4 paper
      // Total height = 54 + 6 + 54 = 114 mm. Page height = 297 mm.
      // Top margin = (297 - 114) / 2 = 91.5 mm.
      expect(frontItem.yMm, closeTo(91.5, 0.01));
      expect(backItem.yMm, closeTo(91.5 + 54.0 + 6.0, 0.01));
    });

    test('Single-sided card: Only Front is placed, no back placeholder', () {
      final singleSidedCard = IdCardEntry(
        id: 'single1',
        name: 'Single Sided',
        rawBytes: dummyFront1,
        isPdf: false,
        renderedPages: [dummyFront1],
        selectedPageIndex: 0,
        hasBothSides: false,
        frontBytes: dummyFront1,
        backBytes: null,
      );

      final layouts = LayoutEngine.calculateMultiXeroxLayoutPages(
        paperPreset: StandardPaperPresets.a4,
        idPreset: StandardIDCardPresets.aadhaar,
        cards: [singleSidedCard],
        orientation: PaperOrientation.portrait,
        marginMm: 5.0,
        gapMm: 6.0,
      );

      expect(layouts.length, equals(1));
      expect(layouts.first.items.length, equals(1));
      final item = layouts.first.items.first;
      expect(item.rotationDegrees, equals(0));
      // Centered on page
      final pageMidY = layouts.first.paperHeightMm / 2.0;
      final itemMidY = item.yMm + (item.heightMm / 2.0);
      expect(itemMidY, closeTo(pageMidY, 0.01));
    });

    test('Multiple cards pagination: Always 1 person (Front + Back) per sheet (3 cards = 3 sheets)', () {
      final layouts = LayoutEngine.calculateMultiXeroxLayoutPages(
        paperPreset: StandardPaperPresets.a4,
        idPreset: StandardIDCardPresets.aadhaar,
        cards: [card1, card2, card3],
        orientation: PaperOrientation.portrait,
        marginMm: 5.0,
        gapMm: 6.0,
      );

      expect(layouts.length, equals(3), reason: 'Each person gets their own separate sheet');

      // Sheet 1: Person 1 (2 items: front, back)
      final sheet1 = layouts[0];
      expect(sheet1.items.length, equals(2));
      expect(sheet1.serviceType, equals('Xerox Copy (Sheet 1 of 3)'));
      expect(sheet1.showDragonCutLines, isFalse);
      expect(sheet1.items[0].imageBytes, equals(dummyFront1));
      expect(sheet1.items[1].imageBytes, equals(dummyBack1));

      // Sheet 2: Person 2 (2 items: front, back)
      final sheet2 = layouts[1];
      expect(sheet2.items.length, equals(2));
      expect(sheet2.serviceType, equals('Xerox Copy (Sheet 2 of 3)'));
      expect(sheet2.showDragonCutLines, isFalse);
      expect(sheet2.items[0].imageBytes, equals(dummyFront2));
      expect(sheet2.items[1].imageBytes, equals(dummyBack2));

      // Sheet 3: Person 3 (2 items: front, back)
      final sheet3 = layouts[2];
      expect(sheet3.items.length, equals(2));
      expect(sheet3.serviceType, equals('Xerox Copy (Sheet 3 of 3)'));
      expect(sheet3.showDragonCutLines, isFalse);
      expect(sheet3.items[0].imageBytes, equals(dummyFront3));
      expect(sheet3.items[1].imageBytes, equals(dummyBack3));

      // All items have 0° rotation
      for (final layout in layouts) {
        for (final item in layout.items) {
          expect(item.rotationDegrees, equals(0));
        }
      }
    });

    test('Xerox layouts never have cut lines or borders', () {
      final layouts = LayoutEngine.calculateMultiXeroxLayoutPages(
        paperPreset: StandardPaperPresets.a4,
        idPreset: StandardIDCardPresets.aadhaar,
        cards: [card1],
      );

      expect(layouts.first.showDragonCutLines, isFalse);
    });
  });

  group('Xerox Pricing and Cost Calculations', () {
    test('Default pricing storage includes id_card_xerox at ₹10.0 / ₹1.5', () {
      final item = PricingStorage.defaultPricing.firstWhere((p) => p.id == 'id_card_xerox');
      expect(item.name, equals('ID Card Xerox (Paper Copy)'));
      expect(item.price, equals(10.0));
      expect(item.cost, equals(1.5));
      expect(item.category, equals('Card Printing'));
    });

    test('PricingProvider lookup resolves Xerox price', () {
      final container = ProviderContainer();
      final pricing = container.read(pricingProvider.notifier);
      final item = pricing.getPriceForService('id_card_xerox');
      expect(item.price, equals(10.0));
    });

    test('IdCardState calculates correct costs for Xerox', () {
      const state = IdCardState(
        workflowType: IdCardWorkflowType.xerox,
        printJobCopies: 2,
      );

      // 1 card * 2 copies = 2
      // Selling price: 10.0 * 1 * 2 = 20.0
      expect(state.calculatedSellingPrice, equals(20.0));
      // Material cost: 1.5 * 1 * 2 = 3.0
      expect(state.calculatedMaterialCost, equals(3.0));
      // Ink cost: 1.0 * 1 * 2 = 2.0
      expect(state.calculatedInkCost, equals(2.0));
      // Profit: 20.0 - 3.0 - 2.0 = 15.0
      expect(state.calculatedEstimatedProfit, equals(15.0));
    });
  });

  group('IdCardProvider Xerox Workflow Integration', () {
    test('setWorkflowType(IdCardWorkflowType.xerox) sets defaults correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(idCardProvider.notifier);

      // Switch to Xerox
      notifier.setWorkflowType(IdCardWorkflowType.xerox);

      final state = container.read(idCardProvider);
      expect(state.workflowType, equals(IdCardWorkflowType.xerox));
      expect(state.paperPreset.id, equals(StandardPaperPresets.a4.id));
      expect(state.orientation, equals(PaperOrientation.portrait));
      expect(state.gapMm, equals(6.0));
      expect(state.marginMm, equals(5.0));
    });

    test('State with multiple cards calculates correct Xerox layouts and counts', () {
      final state = IdCardState(
        workflowType: IdCardWorkflowType.xerox,
        cards: [card1, card2],
      );
      expect(state.workflowType, equals(IdCardWorkflowType.xerox));
      expect(state.totalCardsCount, equals(2));
      expect(state.calculatedSellingPrice, equals(20.0)); // 10.0 * 2 cards
      expect(state.calculatedMaterialCost, equals(3.0)); // 1.5 * 2 cards
      expect(state.calculatedInkCost, equals(2.0)); // 1.0 * 2 cards
      expect(state.calculatedEstimatedProfit, equals(15.0));
    });

    test('Existing workflows remain untouched and intact', () {
      final container = ProviderContainer();
      final notifier = container.read(idCardProvider.notifier);

      // Test Lamination
      notifier.setWorkflowType(IdCardWorkflowType.photoPaperLamination);
      expect(container.read(idCardProvider).paperPreset.id, equals(StandardPaperPresets.fourR.id));

      // Test Epson L805
      notifier.setWorkflowType(IdCardWorkflowType.epsonL805);
      expect(container.read(idCardProvider).paperPreset.id, equals(StandardPaperPresets.a4.id));

      // Test Dragon Sheet
      notifier.setWorkflowType(IdCardWorkflowType.dragonSheet);
      expect(container.read(idCardProvider).paperPreset.id, equals(StandardPaperPresets.dragonSheet200x300.id));
    });
  });
}
