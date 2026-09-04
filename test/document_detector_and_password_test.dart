import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fastprintstudio/core/constants/id_card_presets.dart';
import 'package:fastprintstudio/services/detection/document_detector.dart';
import 'package:fastprintstudio/services/pdf/pdf_inspector.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Intelligent Document Detector & PDF Password Tests', () {
    // Helper to generate a synthetic test image with rectangular card blocks
    Uint8List createTestDocImage({
      required int width,
      required int height,
      required List<List<int>> cardRects, // [x, y, w, h]
    }) {
      final image = img.Image(width: width, height: height);
      // Fill with white background
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      for (final rect in cardRects) {
        final x = rect[0];
        final y = rect[1];
        final w = rect[2];
        final h = rect[3];

        // Draw solid dark card border
        img.drawRect(
          image,
          x1: x,
          y1: y,
          x2: x + w,
          y2: y + h,
          color: img.ColorRgb8(30, 41, 59),
        );

        // Fill card area with simulated content / photo / text blocks
        img.fillRect(
          image,
          x1: x + 4,
          y1: y + 4,
          x2: x + w - 4,
          y2: y + h - 4,
          color: img.ColorRgb8(240, 245, 250),
        );

        // Photo box
        img.fillRect(
          image,
          x1: x + 10,
          y1: y + 10,
          x2: x + 50,
          y2: y + 60,
          color: img.ColorRgb8(59, 130, 246),
        );

        // QR Code box
        img.fillRect(
          image,
          x1: x + w - 50,
          y1: y + 10,
          x2: x + w - 10,
          y2: y + 50,
          color: img.ColorRgb8(15, 23, 42),
        );
      }

      return Uint8List.fromList(img.encodePng(image));
    }

    test('TEST 1: Front + Back vertically arranged card layout', () async {
      // Create vertical stack of 2 cards (Front top, Back bottom)
      final bytes = createTestDocImage(
        width: 600,
        height: 800,
        cardRects: [
          [80, 80, 440, 280], // Top Card (Front)
          [80, 420, 440, 280], // Bottom Card (Back)
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.aadhaar,
      );

      expect(result.isDetected, isTrue);
      expect(result.hasBothSides, isTrue);
      expect(result.frontCrop.top, lessThan(result.backCrop!.top));
      expect(result.frontCrop.width, greaterThan(0.5));
      expect(result.backCrop!.width, greaterThan(0.5));
    });

    test('TEST 2: Front + Back horizontally arranged card layout', () async {
      // Create side-by-side horizontal pair (Front left, Back right)
      final bytes = createTestDocImage(
        width: 1000,
        height: 500,
        cardRects: [
          [50, 80, 420, 265], // Left Card (Front)
          [520, 80, 420, 265], // Right Card (Back)
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.aadhaar,
      );

      expect(result.isDetected, isTrue);
      expect(result.hasBothSides, isTrue);
      expect(result.frontCrop.left, lessThan(result.backCrop!.left));
    });

    test('TEST 3: Aadhaar-style A4 page with multiple sections and bottom cutout cards', () async {
      // Create A4 page (width: 700, height: 1000) with header text and 2 bottom cutout cards
      final bytes = createTestDocImage(
        width: 700,
        height: 1000,
        cardRects: [
          [50, 100, 600, 200], // Letter / Instructions header area
          [40, 650, 300, 200], // Bottom Left Aadhaar Card (Front)
          [360, 650, 300, 200], // Bottom Right Aadhaar Card (Back)
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.aadhaar,
      );

      expect(result.isDetected, isTrue);
      expect(result.hasBothSides, isTrue);
      expect(result.frontCrop.top, greaterThanOrEqualTo(0.5));
      expect(result.backCrop!.top, greaterThanOrEqualTo(0.5));
    });

    test('TEST 4: Single ID Card Image detection', () async {
      final bytes = createTestDocImage(
        width: 600,
        height: 400,
        cardRects: [
          [40, 40, 520, 320], // Single Centered Card
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.aadhaar,
      );

      expect(result.isDetected, isTrue);
      expect(result.hasBothSides, isFalse);
      expect(result.backCrop, isNull);
      expect(result.frontCrop.width, greaterThan(0.7));
    });

    test('TEST 5: Two-sided ID Card candidates extraction', () async {
      final bytes = createTestDocImage(
        width: 800,
        height: 600,
        cardRects: [
          [40, 50, 340, 220],
          [420, 50, 340, 220],
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.aadhaar,
      );

      expect(result.isDetected, isTrue);
      expect(result.candidates.length, greaterThanOrEqualTo(2));
      expect(result.candidates.any((c) => c.isFrontSuggestion), isTrue);
      expect(result.candidates.any((c) => c.isBackSuggestion), isTrue);
    });

    test('TEST 6: Rotated / Landscape Page layout', () async {
      final bytes = createTestDocImage(
        width: 900,
        height: 600,
        cardRects: [
          [50, 100, 380, 240],
          [470, 100, 380, 240],
        ],
      );

      final result = await DocumentDetector.detectIDCard(
        imageBytes: bytes,
        preset: StandardIDCardPresets.panCard,
      );

      expect(result.isDetected, isTrue);
      expect(result.hasBothSides, isTrue);
    });

    test('TEST 7: Password-Protected PDF Detection via PdfInspector', () {
      // Create a password protected PDF using Syncfusion PDF
      final document = PdfDocument();
      document.pages.add().graphics.drawString(
        'Aadhaar Secret Data',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
      document.security.userPassword = 'secretPassword123';
      final encryptedBytes = Uint8List.fromList(document.saveSync());
      document.dispose();

      // Test Inspection
      final inspection = PdfInspector.inspectPdf(encryptedBytes);
      expect(inspection.status, equals(PdfStatus.passwordProtected));
      expect(inspection.isEncrypted, isTrue);
    });

    test('TEST 8: Password-Protected PDF Unlock and Incorrect Password Handling', () async {
      final document = PdfDocument();
      document.pages.add().graphics.drawString(
        'Secret Aadhaar Document Content',
        PdfStandardFont(PdfFontFamily.helvetica, 14),
      );
      document.security.userPassword = 'mySecurePassword';
      final encryptedBytes = Uint8List.fromList(document.saveSync());
      document.dispose();

      // 1. Wrong Password -> Must return failure with clean message
      final wrongAttempt = await PdfInspector.unlockPdf(
        pdfBytes: encryptedBytes,
        password: 'wrongPassword999',
      );
      expect(wrongAttempt.success, isFalse);
      expect(wrongAttempt.errorMessage, contains('Incorrect PDF password'));

      // 2. Correct Password -> Must unlock and return decrypted byte array
      final correctAttempt = await PdfInspector.unlockPdf(
        pdfBytes: encryptedBytes,
        password: 'mySecurePassword',
      );
      expect(correctAttempt.success, isTrue);
      expect(correctAttempt.decryptedBytes, isNotNull);
      expect(correctAttempt.pageCount, equals(1));
    });

    test('TEST 9: Corrupted / Malformed PDF Detection', () {
      final corruptedBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final inspection = PdfInspector.inspectPdf(corruptedBytes);

      expect(inspection.status, equals(PdfStatus.malformed));
      expect(inspection.errorMessage, contains('Unable to read this PDF'));
    });
  });
}
