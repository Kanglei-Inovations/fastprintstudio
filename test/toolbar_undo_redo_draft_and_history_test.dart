import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastprintstudio/core/models/paper_preset.dart';
import 'package:fastprintstudio/features/documents/models/document_paper_type.dart';
import 'package:fastprintstudio/features/documents/models/document_print_state.dart';
import 'package:fastprintstudio/features/documents/providers/document_provider.dart';
import 'package:fastprintstudio/providers/app_providers.dart';
import 'package:fastprintstudio/services/storage/draft_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Document Undo / Redo Suite', () {
    test('Initial state has canUndo = false and canRedo = false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(documentPrintProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('Changing print options records undo history and allows undo/redo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(documentPrintProvider.notifier);

      // Initial copies = 1
      expect(container.read(documentPrintProvider).copies, 1);
      expect(container.read(documentPrintProvider).canUndo, isFalse);

      // 1. Change copies to 5
      notifier.setCopies(5);
      expect(container.read(documentPrintProvider).copies, 5);
      expect(container.read(documentPrintProvider).canUndo, isTrue);
      expect(container.read(documentPrintProvider).canRedo, isFalse);

      // 2. Change color mode to color
      notifier.setColorMode(ColorMode.color);
      expect(container.read(documentPrintProvider).colorMode, ColorMode.color);
      expect(container.read(documentPrintProvider).undoStack.length, 2);

      // 3. Rotate 90 degrees
      notifier.rotateRight();
      expect(container.read(documentPrintProvider).rotationAngle, 90);
      expect(container.read(documentPrintProvider).undoStack.length, 3);

      // 4. Undo rotation -> should return to 0 angle, colorMode=color
      notifier.undo();
      expect(container.read(documentPrintProvider).rotationAngle, 0);
      expect(container.read(documentPrintProvider).colorMode, ColorMode.color);
      expect(container.read(documentPrintProvider).canRedo, isTrue);

      // 5. Undo color mode -> should return to B&W, copies=5
      notifier.undo();
      expect(container.read(documentPrintProvider).colorMode, ColorMode.blackAndWhite);
      expect(container.read(documentPrintProvider).copies, 5);

      // 6. Undo copies -> should return to copies=1
      notifier.undo();
      expect(container.read(documentPrintProvider).copies, 1);
      expect(container.read(documentPrintProvider).canUndo, isFalse);
      expect(container.read(documentPrintProvider).canRedo, isTrue);

      // 7. Redo -> copies=5
      notifier.redo();
      expect(container.read(documentPrintProvider).copies, 5);
      expect(container.read(documentPrintProvider).canUndo, isTrue);
    });

    test('Paper preset and layout changes are undoable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(documentPrintProvider.notifier);

      notifier.setOrientation(PaperOrientation.landscape);
      expect(container.read(documentPrintProvider).orientation, PaperOrientation.landscape);

      notifier.setPaperType(DocumentPaperType.glossyPhoto);
      expect(container.read(documentPrintProvider).paperType, DocumentPaperType.glossyPhoto);

      notifier.undo();
      expect(container.read(documentPrintProvider).paperType, DocumentPaperType.normal70Gsm);

      notifier.undo();
      expect(container.read(documentPrintProvider).orientation, PaperOrientation.portrait);
    });
  });

  group('Draft Storage Service Suite', () {
    test('Saves, loads, and clears Document draft', () async {
      final mockBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      const mockFileName = 'test_document.docx';
      final mockMeta = {
        'copies': 3,
        'colorMode': 'color',
        'paperPresetName': 'A4',
      };

      await DraftStorageService.saveDocumentDraft(
        bytes: mockBytes,
        fileName: mockFileName,
        metadata: mockMeta,
      );

      final loaded = await DraftStorageService.loadDocumentDraft();
      expect(loaded, isNotNull);
      expect(loaded!['fileName'], mockFileName);
      expect(loaded['bytes'], mockBytes);
      expect(loaded['metadata']['copies'], 3);
      expect(loaded['metadata']['colorMode'], 'color');

      await DraftStorageService.clearDocumentDraft();
      final afterClear = await DraftStorageService.loadDocumentDraft();
      expect(afterClear, isNull);
    });

    test('Saves, loads, and clears ID Card draft', () async {
      final mockBytes = Uint8List.fromList([10, 20, 30, 40]);
      const mockFileName = 'aadhaar_card.pdf';
      final mockMeta = {
        'idCardPresetId': 'aadhaar',
        'workflowTypeName': 'epsonL805',
        'hasBothSides': true,
      };

      await DraftStorageService.saveIdCardDraft(
        bytes: mockBytes,
        fileName: mockFileName,
        metadata: mockMeta,
      );

      final loaded = await DraftStorageService.loadIdCardDraft();
      expect(loaded, isNotNull);
      expect(loaded!['fileName'], mockFileName);
      expect(loaded['bytes'], mockBytes);
      expect(loaded['metadata']['idCardPresetId'], 'aadhaar');
      expect(loaded['metadata']['hasBothSides'], isTrue);

      await DraftStorageService.clearIdCardDraft();
      final afterClear = await DraftStorageService.loadIdCardDraft();
      expect(afterClear, isNull);
    });

    test('Saves, loads, and clears Photo draft', () async {
      final mockBytes = Uint8List.fromList([50, 60, 70, 80]);
      const mockFileName = 'passport_photo.jpg';
      final mockMeta = {
        'presetModeName': 'passportPlusStamp',
        'printJobCopies': 2,
        'outerBorderMm': 1.5,
      };

      await DraftStorageService.savePhotoDraft(
        bytes: mockBytes,
        fileName: mockFileName,
        metadata: mockMeta,
      );

      final loaded = await DraftStorageService.loadPhotoDraft();
      expect(loaded, isNotNull);
      expect(loaded!['fileName'], mockFileName);
      expect(loaded['bytes'], mockBytes);
      expect(loaded['metadata']['presetModeName'], 'passportPlusStamp');

      await DraftStorageService.clearPhotoDraft();
      final afterClear = await DraftStorageService.loadPhotoDraft();
      expect(afterClear, isNull);
    });
  });

  group('Print History Recording Rules', () {
    test('Export PDF does not add records to historyProvider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final historyItems = container.read(historyProvider);
      final initialHistoryCount = historyItems.length;

      final docNotifier = container.read(documentPrintProvider.notifier);

      // Attempting export on empty or loaded doc returns false / completes without recording history
      await docNotifier.exportPdf();

      final updatedHistory = container.read(historyProvider);
      expect(updatedHistory.length, initialHistoryCount);
    });
  });
}
