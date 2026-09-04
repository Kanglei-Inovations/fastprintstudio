import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/core/models/pricing_item.dart';
import 'package:fastprintstudio/providers/pricing_provider.dart';
import 'package:fastprintstudio/services/storage/pricing_storage.dart';
import 'package:fastprintstudio/core/models/photo_finish.dart';
import 'package:fastprintstudio/providers/passport_photo_provider.dart';
import 'dart:typed_data';
import 'package:fastprintstudio/core/models/id_card_workflow_type.dart';
import 'package:fastprintstudio/providers/id_card_provider.dart';
import 'package:fastprintstudio/features/documents/models/document_paper_type.dart';
import 'package:fastprintstudio/features/documents/models/document_print_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pricing & Rates Tests', () {
    test('PricingItem computes profit and profit margin percentage correctly', () {
      const item = PricingItem(
        id: 'aadhaar_lamination',
        name: 'Aadhaar Lamination Print',
        category: 'Card Printing',
        price: 40.0,
        cost: 10.0,
        unit: 'per card',
      );

      expect(item.profit, equals(30.0));
      expect(item.profitMarginPct, equals(75.0));
    });

    test('PricingStorage defaults contain standard card and photo rates', () {
      final defaults = PricingStorage.defaultPricing;
      expect(defaults.length, greaterThanOrEqualTo(8));

      final photo4r = defaults.firstWhere((p) => p.id == 'photo_print_4r');
      expect(photo4r.price, equals(40.0)); // Fixed ₹40 for 4R photo
      expect(photo4r.unit, equals('per 4R sheet'));

      final aadhaar = defaults.firstWhere((p) => p.id == 'aadhaar_lamination');
      expect(aadhaar.price, equals(30.0));

      final pvc = defaults.firstWhere((p) => p.id == 'aadhaar_pvc');
      expect(pvc.price, equals(60.0));
    });

    test('PricingNotifier getPriceForService maps service names to rates', () {
      final notifier = PricingNotifier();

      final aadhaarRate = notifier.getPriceForService('Aadhaar Card (85.6 × 54 mm)');
      expect(aadhaarRate.price, equals(30.0));

      final pvcRate = notifier.getPriceForService('PVC Aadhaar Card');
      expect(pvcRate.price, equals(60.0));

      final passportRate = notifier.getPriceForService('Passport Photo (30 × 40 mm)');
      expect(passportRate.price, equals(40.0));

      final panRate = notifier.getPriceForService('PAN Card');
      expect(panRate.price, equals(35.0));

      final docBwRate = notifier.getPriceForService('Document Print');
      expect(docBwRate.price, equals(3.0));
    });

    test('PricingItem JSON serialization and deserialization', () {
      const item = PricingItem(
        id: 'custom_1',
        name: 'Glossy A4 Poster Print',
        category: 'Custom Services',
        price: 150.0,
        cost: 35.0,
        unit: 'per poster',
        description: 'High quality resin photo paper',
        isCustom: true,
      );

      final json = item.toJson();
      final restored = PricingItem.fromJson(json);

      expect(restored.id, equals('custom_1'));
      expect(restored.name, equals('Glossy A4 Poster Print'));
      expect(restored.price, equals(150.0));
      expect(restored.profit, equals(115.0));
      expect(restored.isCustom, isTrue);
    });

    test('PhotoFinish paper cost mapping and labels', () {
      expect(PhotoFinish.glossy.paperCost, equals(4.0));
      expect(PhotoFinish.matte.paperCost, equals(5.5));
      expect(PhotoFinish.matte.extraPricePerSheet, equals(10.0));
      expect(PhotoFinish.glossy.label, contains('Glossy'));
      expect(PhotoFinish.matte.label, contains('Matte'));
    });

    test('PassportPhotoState computes correct selling price, material cost, ink and profit', () {
      // 1 sheet with glossy finish, 1 job copy
      const state1 = PassportPhotoState(
        photoFinish: PhotoFinish.glossy,
        printJobCopies: 1,
      );

      expect(state1.totalSheetsRequired, equals(1));
      expect(state1.calculatedSellingPrice, equals(50.0)); // 1st sheet = ₹50
      expect(state1.calculatedMaterialCost, equals(4.0)); // Glossy paper = ₹4.0
      expect(state1.calculatedInkCost, equals(2.5)); // Ink = ₹2.5
      expect(state1.calculatedProfit, equals(43.5)); // 50 - 4.0 - 2.5 = 43.5

      // 1 sheet with matte finish (+₹10/sheet), 2 job copies
      const state2 = PassportPhotoState(
        photoFinish: PhotoFinish.matte,
        printJobCopies: 2,
      );

      expect(state2.calculatedSellingPrice, equals(120.0)); // (50 + 10) * 2
      expect(state2.calculatedMaterialCost, equals(11.0)); // 5.5 * 2
      expect(state2.calculatedInkCost, equals(5.0)); // 2.5 * 2
      expect(state2.calculatedProfit, equals(104.0)); // 120 - 11 - 5
    });

    test('IdCardState computes accurate physical workflow pricing & profit', () {
      // Workflow A: Photo Paper + Lamination (₹50/card)
      const laminationState = IdCardState(
        workflowType: IdCardWorkflowType.photoPaperLamination,
        printJobCopies: 1,
      );
      expect(laminationState.unitSellingPrice, equals(50.0));
      expect(laminationState.calculatedSellingPrice, equals(50.0));
      expect(laminationState.calculatedMaterialCost, equals(6.5)); // 4R paper ₹4 + pouch ₹2.5
      expect(laminationState.calculatedInkCost, equals(3.0));
      expect(laminationState.calculatedEstimatedProfit, equals(40.5)); // 50 - 6.5 - 3

      // Workflow B: Epson L805 PVC Tray (₹100/card)
      const pvcTrayState = IdCardState(
        workflowType: IdCardWorkflowType.epsonL805Pvc,
        pvcMode: PvcOutputMode.l805Tray,
        printJobCopies: 1,
      );
      expect(pvcTrayState.unitSellingPrice, equals(100.0));
      expect(pvcTrayState.calculatedSellingPrice, equals(100.0));
      expect(pvcTrayState.calculatedMaterialCost, equals(12.0)); // PVC blank ₹12
      expect(pvcTrayState.calculatedInkCost, equals(3.0));
      expect(pvcTrayState.calculatedEstimatedProfit, equals(85.0)); // 100 - 12 - 3
    });

    test('DocumentPaperType and DocumentBindingType properties and costs', () {
      expect(DocumentPaperType.normal70Gsm.sheetCost, equals(0.50));
      expect(DocumentPaperType.normal70Gsm.bwRatePerPage, equals(2.0));
      expect(DocumentPaperType.normal70Gsm.colorRatePerPage, equals(5.0));

      expect(DocumentPaperType.heavy100Gsm.sheetCost, equals(1.50));
      expect(DocumentPaperType.heavy100Gsm.bwRatePerPage, equals(5.0));
      expect(DocumentPaperType.heavy100Gsm.colorRatePerPage, equals(10.0));

      expect(DocumentBindingType.none.price, equals(0.0));
      expect(DocumentBindingType.spiralBinding.price, equals(30.0));
    });

    test('DocumentPrintState calculates accurate selling, material cost, ink and profit', () {
      // 10 pages B&W single sided, 70 GSM, no binding, 1 copy
      final state1 = DocumentPrintState(
        renderedPages: List.generate(10, (i) => Uint8List(0)),
        colorMode: ColorMode.blackAndWhite,
        paperType: DocumentPaperType.normal70Gsm,
        bindingType: DocumentBindingType.none,
        printSides: DuplexMode.singleSided,
        copies: 1,
      );

      expect(state1.pagesToPrint, equals(10));
      expect(state1.totalSheetsToPrint, equals(10));
      expect(state1.ratePerPage, equals(2.0));
      expect(state1.calculatedSellingPrice, equals(20.0)); // 10 * 2.0
      expect(state1.calculatedMaterialCost, equals(5.0)); // 10 sheets * 0.50
      expect(state1.calculatedInkCost, equals(4.0)); // 10 pages * 0.40
      expect(state1.calculatedProfit, equals(11.0)); // 20 - 5 - 4 = 11

      // 10 pages Color double-sided (duplex), 75 GSM, Spiral Binding (+₹30), 1 copy
      final state2 = DocumentPrintState(
        renderedPages: List.generate(10, (i) => Uint8List(0)),
        colorMode: ColorMode.color,
        paperType: DocumentPaperType.bond75Gsm,
        bindingType: DocumentBindingType.spiralBinding,
        printSides: DuplexMode.doubleSidedLongEdge,
        copies: 1,
      );

      expect(state2.pagesToPrint, equals(10));
      expect(state2.totalSheetsToPrint, equals(5)); // Duplex: 10 / 2 = 5 sheets
      expect(state2.ratePerPage, equals(7.0));
      // Selling: 10 pages * 7.0 + 30.0 binding = 100.0
      expect(state2.calculatedSellingPrice, equals(100.0));
      // Material: (5 sheets * 0.80) + 10.0 spiral material = 14.0
      expect(state2.calculatedMaterialCost, equals(14.0));
      // Ink: 10 pages * 1.80 = 18.0
      expect(state2.calculatedInkCost, equals(18.0));
      // Profit: 100 - 14 - 18 = 68.0
      expect(state2.calculatedProfit, equals(68.0));
    });
  });
}
