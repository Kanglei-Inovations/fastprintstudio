import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/core/constants/paper_presets.dart';
import 'package:fastprintstudio/core/models/id_card_entry.dart';
import 'package:fastprintstudio/core/models/id_card_workflow_type.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/providers/id_card_provider.dart';
import 'package:fastprintstudio/services/layout/layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final validPngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  group('Multi-Card ID Card Workflow & Layout Tests', () {
    final dummyFront1 = Uint8List.fromList([1, 1, 1, 1]);
    final dummyBack1 = Uint8List.fromList([1, 2, 2, 1]);
    final dummyFront2 = Uint8List.fromList([2, 1, 1, 2]);
    final dummyBack2 = Uint8List.fromList([2, 2, 2, 2]);
    final dummyFront3 = Uint8List.fromList([3, 1, 1, 3]);
    final dummyBack3 = Uint8List.fromList([3, 2, 2, 3]);
    final dummyFront4 = Uint8List.fromList([4, 1, 1, 4]);
    final dummyBack4 = Uint8List.fromList([4, 2, 2, 4]);

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

    final card4 = IdCardEntry(
      id: 'c4',
      name: 'Person 4',
      rawBytes: dummyFront4,
      isPdf: false,
      renderedPages: [dummyFront4],
      selectedPageIndex: 0,
      hasBothSides: true,
      frontBytes: dummyFront4,
      backBytes: dummyBack4,
    );

    // =========================================================================
    // 1. PHOTO PAPER & LAMINATION (4R & A4)
    // =========================================================================
    group('Photo Paper & Lamination Multi-Page Pagination', () {
      test('4R Sheet paginates 1 duplex card per sheet (3 cards = 3 sheets)', () {
        final layouts = LayoutEngine.calculateMultiIdCardLayoutPages(
          paperPreset: StandardPaperPresets.fourR,
          idPreset: StandardIDCardPresets.aadhaar,
          cards: [card1, card2, card3],
          orientation: PaperOrientation.landscape,
          marginMm: 6.0,
          gapMm: 4.0,
        );

        expect(layouts.length, 3, reason: 'Each duplex card on 4R must have its own sheet');
        for (int i = 0; i < layouts.length; i++) {
          final l = layouts[i];
          expect(l.paperPreset.effectiveWidthMm(l.orientation), closeTo(152.4, 0.5));
          expect(l.paperPreset.effectiveHeightMm(l.orientation), closeTo(101.6, 0.5));
          expect(l.items.length, 2, reason: 'Front and Back side placed on sheet');
        }

        // Sheet 1 has Person 1 bytes
        expect(layouts[0].items[0].imageBytes, dummyFront1);
        expect(layouts[0].items[1].imageBytes, dummyBack1);

        // Sheet 2 has Person 2 bytes
        expect(layouts[1].items[0].imageBytes, dummyFront2);
        expect(layouts[1].items[1].imageBytes, dummyBack2);

        // Sheet 3 has Person 3 bytes
        expect(layouts[2].items[0].imageBytes, dummyFront3);
        expect(layouts[2].items[1].imageBytes, dummyBack3);
      });

      test('4R Sheet in Portrait orientation places 1 duplex card per sheet with back rotated 180 deg', () {
        final layouts = LayoutEngine.calculateMultiIdCardLayoutPages(
          paperPreset: StandardPaperPresets.fourR,
          idPreset: StandardIDCardPresets.aadhaar,
          cards: [card1, card2],
          orientation: PaperOrientation.portrait,
          marginMm: 4.0,
          gapMm: 0.0,
        );

        expect(layouts.length, 2, reason: '2 cards on 4R portrait must produce 2 sheets');
        // Sheet 1 has Person 1 Front & Back stacked vertically
        expect(layouts[0].items.length, 2);
        expect(layouts[0].items[0].imageBytes, dummyFront1);
        expect(layouts[0].items[1].imageBytes, dummyBack1);
        expect(layouts[0].items[0].rotationDegrees, 0);
        expect(layouts[0].items[1].rotationDegrees, 180, reason: 'Back card must be rotated 180 deg for fold alignment');

        // Sheet 2 has Person 2 Front & Back stacked vertically
        expect(layouts[1].items.length, 2);
        expect(layouts[1].items[0].imageBytes, dummyFront2);
        expect(layouts[1].items[1].imageBytes, dummyBack2);
        expect(layouts[1].items[0].rotationDegrees, 0);
        expect(layouts[1].items[1].rotationDegrees, 180, reason: 'Back card must be rotated 180 deg for fold alignment');
      });

      test('A4 Sheet packs multiple duplex card pairs row-by-row starting from top-left', () {
        final layouts = LayoutEngine.calculateMultiIdCardLayoutPages(
          paperPreset: StandardPaperPresets.a4,
          idPreset: StandardIDCardPresets.aadhaar,
          cards: [card1, card2, card3, card4],
          orientation: PaperOrientation.portrait,
          marginMm: 10.0,
          gapMm: 5.0,
        );

        expect(layouts.isNotEmpty, true);
        final firstLayout = layouts[0];
        // 4 duplex cards = 8 card sides
        // An A4 sheet (210 x 297 mm) can easily fit 4 duplex pairs (8 items)
        expect(firstLayout.items.length, 8);

        // Card 1 Front and Back are in the first row
        final c1Front = firstLayout.items[0];
        final c1Back = firstLayout.items[1];
        expect(c1Front.yMm, c1Back.yMm);
        expect(c1Front.xMm < c1Back.xMm, true);

        // Card 2 Front and Back are in the second row (or adjacent column)
        final c2Front = firstLayout.items[2];
        expect(c2Front.yMm >= c1Front.yMm + 54.0 - 0.1 || c2Front.xMm > c1Back.xMm, true);
      });
    });

    // =========================================================================
    // 2. EPSON L805 PVC TRAY (FRONT PAGE 1, BACK PAGE 2)
    // =========================================================================
    group('Epson L805 PVC Tray Batch Pagination', () {
      test('1 card creates Page 1 (Front in Slot 1) and Page 2 (Back in Slot 1)', () {
        final layouts = LayoutEngine.calculateMultiL805TrayLayoutPages(
          cards: [card1],
          cardsPerTray: 2,
        );

        expect(layouts.length, 2, reason: '1 card requires 2 pages (Front then Back)');

        // Page 1: Front in Slot 1
        final page1 = layouts[0];
        expect(page1.items.length, 1);
        expect(page1.items[0].imageBytes, dummyFront1);
        expect(page1.items[0].label, contains('Slot 1'));

        // Page 2: Back in Slot 1
        final page2 = layouts[1];
        expect(page2.items.length, 1);
        expect(page2.items[0].imageBytes, dummyBack1);
        expect(page2.items[0].label, contains('Slot 1'));

        // Positions match exactly
        expect(page1.items[0].xMm, page2.items[0].xMm);
        expect(page1.items[0].yMm, page2.items[0].yMm);
      });

      test('2 cards create Page 1 (Front of A and B) and Page 2 (Back of A and B)', () {
        final layouts = LayoutEngine.calculateMultiL805TrayLayoutPages(
          cards: [card1, card2],
          cardsPerTray: 2,
        );

        expect(layouts.length, 2, reason: '1 batch of 2 cards requires 2 pages (Fronts then Backs)');

        // Page 1: Fronts
        final page1 = layouts[0];
        expect(page1.items.length, 2);
        expect(page1.items[0].imageBytes, dummyFront1, reason: 'Slot 1 Page 1 is Card 1 Front');
        expect(page1.items[1].imageBytes, dummyFront2, reason: 'Slot 2 Page 1 is Card 2 Front');

        // Page 2: Backs
        final page2 = layouts[1];
        expect(page2.items.length, 2);
        expect(page2.items[0].imageBytes, dummyBack1, reason: 'Slot 1 Page 2 is Card 1 Back');
        expect(page2.items[1].imageBytes, dummyBack2, reason: 'Slot 2 Page 2 is Card 2 Back');

        // Slot positions must match exactly between Front and Back (Zero Drift)
        expect(page1.items[0].xMm, page2.items[0].xMm);
        expect(page1.items[0].yMm, page2.items[0].yMm);
        expect(page1.items[1].xMm, page2.items[1].xMm);
        expect(page1.items[1].yMm, page2.items[1].yMm);
      });

      test('4 cards create 4 pages: Batch 1 (P1 Fronts, P2 Backs) and Batch 2 (P3 Fronts, P4 Backs)', () {
        final layouts = LayoutEngine.calculateMultiL805TrayLayoutPages(
          cards: [card1, card2, card3, card4],
          cardsPerTray: 2,
        );

        expect(layouts.length, 4, reason: '4 cards across 2-card tray = 2 batches = 4 pages total');

        // Batch 1 Fronts (Page 1)
        expect(layouts[0].items[0].imageBytes, dummyFront1);
        expect(layouts[0].items[1].imageBytes, dummyFront2);

        // Batch 1 Backs (Page 2)
        expect(layouts[1].items[0].imageBytes, dummyBack1);
        expect(layouts[1].items[1].imageBytes, dummyBack2);

        // Batch 2 Fronts (Page 3)
        expect(layouts[2].items[0].imageBytes, dummyFront3);
        expect(layouts[2].items[1].imageBytes, dummyFront4);

        // Batch 2 Backs (Page 4)
        expect(layouts[3].items[0].imageBytes, dummyBack3);
        expect(layouts[3].items[1].imageBytes, dummyBack4);
      });

      test('3 cards (odd count) cleanly generates Page 3 with 1 Front and Page 4 with 1 Back', () {
        final layouts = LayoutEngine.calculateMultiL805TrayLayoutPages(
          cards: [card1, card2, card3],
          cardsPerTray: 2,
        );

        expect(layouts.length, 4);

        // Page 3 has Slot 1 Front for Card 3
        expect(layouts[2].items.length, 1);
        expect(layouts[2].items[0].imageBytes, dummyFront3);

        // Page 4 has Slot 1 Back for Card 3
        expect(layouts[3].items.length, 1);
        expect(layouts[3].items[0].imageBytes, dummyBack3);
      });
    });

    // =========================================================================
    // 3. DRAGON SHEET (200x300mm): START FROM TOP, FRONT LEFT & BACK RIGHT
    // =========================================================================
    group('Dragon Sheet Multi-Card Row-by-Row Layout', () {
      test('Uses default margin 2.0mm and spacing 0.5mm starting from y = 2.0mm', () {
        final layout = LayoutEngine.calculateDragonSheetLayout(
          cardImages: [dummyFront1, dummyBack1],
          isDuplex: true,
          marginMm: 2.0,
          spacingMm: 0.5,
        );

        expect(layout.items.length, 2);
        final front = layout.items[0];
        final back = layout.items[1];

        expect(front.yMm, 2.0, reason: 'Must start from top margin 2.0mm');
        expect(back.yMm, 2.0);
        // Spacing between front right edge and back left edge is 0.5mm
        expect(back.xMm - (front.xMm + 85.6), closeTo(0.5, 0.01));
      });

      test('Starts from TOP with Front on Left and Back on Right, Card 2 at Row 1 below', () {
        final layout = LayoutEngine.calculateDragonSheetLayout(
          cardImages: [dummyFront1, dummyBack1, dummyFront2, dummyBack2],
          isDuplex: true,
          marginMm: 12.0,
          spacingMm: 4.0,
        );

        expect(layout.items.length, 4);
        expect(layout.paperPreset.widthMm, 200.0);
        expect(layout.paperPreset.heightMm, 300.0);

        final c1Front = layout.items[0];
        final c1Back = layout.items[1];
        final c2Front = layout.items[2];
        final c2Back = layout.items[3];

        // Row 0: Card 1 Front (Left) and Back (Right)
        expect(c1Front.yMm, 12.0, reason: 'Must start from top margin');
        expect(c1Back.yMm, 12.0, reason: 'Back must be in same row as front');
        expect(c1Front.xMm < c1Back.xMm, true, reason: 'Front on Left, Back on Right');

        // Row 1: Card 2 Front (Left) and Back (Right) below Row 0
        const expectedRow1Y = 12.0 + 54.0 + 4.0; // startY + cardH + spacing
        expect(c2Front.yMm, closeTo(expectedRow1Y, 0.01));
        expect(c2Back.yMm, closeTo(expectedRow1Y, 0.01));
        expect(c2Front.xMm, closeTo(c1Front.xMm, 0.01));
        expect(c2Back.xMm, closeTo(c1Back.xMm, 0.01));
      });

      test('Paginates to Sheet 2 when card count exceeds 5 cards (duplex)', () {
        final sixCards = [card1, card2, card3, card4, card1, card2];
        final layouts = LayoutEngine.calculateMultiDragonSheetLayoutPages(
          cards: sixCards,
          isDuplex: true,
          marginMm: 10.0,
          spacingMm: 4.0,
        );

        expect(layouts.length, 2, reason: '6 duplex cards exceed 5 per sheet and must create 2 sheets');

        // Sheet 1 has 5 cards (10 items)
        expect(layouts[0].items.length, 10);
        // Sheet 2 has 1 card (2 items) starting from TOP again
        expect(layouts[1].items.length, 2);
        expect(layouts[1].items[0].yMm, 10.0, reason: 'Sheet 2 must start from top margin again');
      });

      test('Dragon Sheet: 1 duplex card places exactly 1 row (Front Left, Back Right) at top, remaining rows empty', () {
        final layouts = LayoutEngine.calculateMultiDragonSheetLayoutPages(
          cards: [card1],
          isDuplex: true,
          marginMm: 2.0,
          spacingMm: 0.5,
        );

        expect(layouts.length, 1);
        expect(layouts[0].items.length, 2, reason: '1 card = 1 pair (Front Left, Back Right)');
        final front = layouts[0].items[0];
        final back = layouts[0].items[1];
        expect(front.xMm < back.xMm, true, reason: 'Row 0: Front on Left, Back on Right');
        expect(front.yMm, back.yMm, reason: 'Row 0: Same horizontal level');
        expect(front.yMm, 2.0, reason: 'Starts at top margin 2.0mm');
      });

      test('Dragon Sheet: 2 duplex cards place 2 rows (4 items total)', () {
        final layouts = LayoutEngine.calculateMultiDragonSheetLayoutPages(
          cards: [card1, card2],
          isDuplex: true,
          marginMm: 2.0,
          spacingMm: 0.5,
        );

        expect(layouts.length, 1);
        expect(layouts[0].items.length, 4, reason: '2 cards = 2 pairs (4 items total)');
        // Row 0 has Card 1
        expect(layouts[0].items[0].imageBytes, dummyFront1);
        expect(layouts[0].items[1].imageBytes, dummyBack1);
        // Row 1 has Card 2
        expect(layouts[0].items[2].imageBytes, dummyFront2);
        expect(layouts[0].items[3].imageBytes, dummyBack2);
      });

      test('Dragon Sheet: front-only card produces 1 card slot on sheet without duplication', () {
        final frontOnlyCard = IdCardEntry(
          id: 'fo1',
          name: 'PAN Front',
          rawBytes: dummyFront1,
          isPdf: false,
          hasBothSides: false,
          frontBytes: dummyFront1,
          backBytes: null,
        );

        final layouts = LayoutEngine.calculateMultiDragonSheetLayoutPages(
          cards: [frontOnlyCard],
          isDuplex: false,
          marginMm: 2.0,
          spacingMm: 0.5,
        );

        expect(layouts.length, 1);
        expect(layouts[0].items.length, 1, reason: '1 front-only card fills 1 slot');
        expect(layouts[0].items[0].imageBytes, dummyFront1);
        expect(layouts[0].items[0].isFront, true);
      });
    });

    // =========================================================================
    // 4. PASSWORD PROTECTED PDF IMPORT & QUEUE TESTS
    // =========================================================================
    group('Password-Protected PDF Import & Queue Tests', () {
      final encryptedPdfBytes = Uint8List.fromList(
        '%PDF-1.4\n1 0 obj\n<< /Encrypt 2 0 R >>\nendobj\n%%EOF'.codeUnits,
      );

      test('addCardDocument detects password protection and prompts for password', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.addCardDocument(
          bytes: encryptedPdfBytes,
          fileName: 'aadhaar_locked.pdf',
          isPdf: true,
        );

        final state = container.read(idCardProvider);
        expect(state.isPasswordRequired, isTrue, reason: 'Password modal must be shown');
        expect(state.pendingEncryptedFileName, 'aadhaar_locked.pdf');
        expect(state.pendingEncryptedPdfBytes, encryptedPdfBytes);
        expect(state.isProcessing, isFalse);
      });

      test('loadMultipleDocuments queues encrypted PDFs while processing valid files', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        final unencryptedImageBytes = validPngBytes;
        final fileList = [
          (bytes: unencryptedImageBytes, fileName: 'card1.png', isPdf: false),
          (bytes: encryptedPdfBytes, fileName: 'secret_card.pdf', isPdf: true),
        ];

        await notifier.loadMultipleDocuments(fileList);

        final state = container.read(idCardProvider);
        // Valid image should be imported
        expect(state.cards.length, 1);
        expect(state.cards.first.name, 'card1.png');

        // Encrypted PDF should prompt password modal
        expect(state.isPasswordRequired, isTrue);
        expect(state.pendingEncryptedFileName, 'secret_card.pdf');
      });

      test('cancelPasswordPrompt advances queue if more files pending or clears prompt', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        final secondEncrypted = Uint8List.fromList(
          '%PDF-1.4\n2 0 obj\n<< /Encrypt 3 0 R >>\nendobj\n%%EOF'.codeUnits,
        );

        final fileList = [
          (bytes: encryptedPdfBytes, fileName: 'first_locked.pdf', isPdf: true),
          (bytes: secondEncrypted, fileName: 'second_locked.pdf', isPdf: true),
        ];

        await notifier.loadMultipleDocuments(fileList);

        var state = container.read(idCardProvider);
        expect(state.isPasswordRequired, isTrue);
        expect(state.pendingEncryptedFileName, 'first_locked.pdf');
        expect(state.pendingEncryptedQueue.length, 1);

        // Cancel the first file -> prompts for second file
        notifier.cancelPasswordPrompt();
        state = container.read(idCardProvider);
        expect(state.isPasswordRequired, isTrue);
        expect(state.pendingEncryptedFileName, 'second_locked.pdf');
        expect(state.pendingEncryptedQueue.isEmpty, isTrue);

        // Cancel second file -> closes password modal
        notifier.cancelPasswordPrompt();
        state = container.read(idCardProvider);
        expect(state.isPasswordRequired, isFalse);
        expect(state.pendingEncryptedPdfBytes, isNull);
      });
    });

    // =========================================================================
    // 5. AUTO WORKFLOW SWITCHING (1 FILE = LAMINATION, >1 FILE = DRAGON SHEET)
    // =========================================================================
    group('Auto Workflow Switching (1 File Lamination, >1 File Dragon Sheet)', () {
      test('1 file defaults to photoPaperLamination with 0.5mm gap', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'person1.png',
          isPdf: false,
        );

        final state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.workflowType, IdCardWorkflowType.photoPaperLamination);
        expect(state.gapMm, 0.5, reason: 'Default lamination spacing must be 0.5mm');
        expect(state.paperPreset.id, '4r');
      });

      test('Adding 2nd card switches workflow automatically to dragonSheet', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'person1.png',
          isPdf: false,
        );

        var state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.workflowType, IdCardWorkflowType.photoPaperLamination);

        // Add 2nd card
        await notifier.addCardDocument(
          bytes: validPngBytes,
          fileName: 'person2.png',
          isPdf: false,
        );

        state = container.read(idCardProvider);
        expect(state.cards.length, 2);
        expect(state.workflowType, IdCardWorkflowType.dragonSheet, reason: '>1 file must automatically switch to Dragon Sheet');
        expect(state.gapMm, 0.5);
        expect(state.marginMm, 2.0);
        expect(state.paperPreset.id, 'dragon_sheet_200x300');

        // Remove card 2 -> switches back to lamination
        notifier.removeCard(state.cards[1].id);
        state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.workflowType, IdCardWorkflowType.photoPaperLamination, reason: '1 file must switch back to Lamination');
        expect(state.gapMm, 0.5);
        expect(state.paperPreset.id, '4r');
      });

      test('replaceActiveCard replaces the active card in-place without changing count', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'person1.png',
          isPdf: false,
        );

        var state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.cards.first.name, 'person1.png');

        await notifier.replaceActiveCard(
          bytes: validPngBytes,
          fileName: 'person1_replaced.png',
          isPdf: false,
        );

        state = container.read(idCardProvider);
        expect(state.cards.length, 1, reason: 'Card count must remain 1 after replacement');
        expect(state.cards.first.name, 'person1_replaced.png');
      });

      test('mergeCardsAsDuplex merges two cards into a single duplex card', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'front_person.png',
          isPdf: false,
        );

        await notifier.addCardDocument(
          bytes: validPngBytes,
          fileName: 'back_person.png',
          isPdf: false,
        );

        var state = container.read(idCardProvider);
        expect(state.cards.length, 2);
        final frontId = state.cards[0].id;
        final backId = state.cards[1].id;

        notifier.mergeCardsAsDuplex(frontId, backId);

        state = container.read(idCardProvider);
        expect(state.cards.length, 1, reason: 'Merged card should reduce count from 2 to 1');
        final mergedCard = state.cards.first;
        expect(mergedCard.id, frontId);
        expect(mergedCard.hasBothSides, isTrue);
        expect(mergedCard.backRawBytes, isNotNull);
        expect(mergedCard.backSourceImageBytes, isNotNull);
        expect(mergedCard.name, contains('front_person'));
      });

      test('uploadCustomBackFile assigns custom back side to active card', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'person_front.png',
          isPdf: false,
        );

        var state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.cards.first.backRawBytes, isNull);

        await notifier.uploadCustomBackFile(
          bytes: validPngBytes,
          fileName: 'custom_back.png',
          isPdf: false,
        );

        state = container.read(idCardProvider);
        expect(state.cards.length, 1);
        expect(state.cards.first.backRawBytes, isNotNull);
        expect(state.cards.first.hasBothSides, isTrue);
        expect(state.cards.first.backSourceImageBytes, isNotNull);
      });

      test('setShowDragonCutLines updates state and propagates to layout', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(idCardProvider.notifier);

        await notifier.loadDocument(
          bytes: validPngBytes,
          fileName: 'person1.png',
          isPdf: false,
        );

        notifier.setWorkflowType(IdCardWorkflowType.dragonSheet);

        var state = container.read(idCardProvider);
        expect(state.showDragonCutLines, isTrue);
        expect(state.currentLayout?.showDragonCutLines, isTrue);

        notifier.setShowDragonCutLines(false);
        state = container.read(idCardProvider);
        expect(state.showDragonCutLines, isFalse);
        expect(state.currentLayout?.showDragonCutLines, isFalse);

        notifier.setShowDragonCutLines(true);
        state = container.read(idCardProvider);
        expect(state.showDragonCutLines, isTrue);
        expect(state.currentLayout?.showDragonCutLines, isTrue);
      });
    });
  });
}
