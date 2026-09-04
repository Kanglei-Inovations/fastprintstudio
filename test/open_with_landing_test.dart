import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/features/landing/open_with_landing_screen.dart';
import 'package:fastprintstudio/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandingFileData Tests', () {
    test('correctly identifies image, pdf, and document file types', () {
      final img = LandingFileData(
        filePath: 'C:/Users/User/Pictures/sample.png',
        fileName: 'sample.png',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileSizeBytes: 2048,
        extension: '.png',
        modifiedAt: DateTime(2026, 9, 3, 10, 0),
      );

      expect(img.isImage, isTrue);
      expect(img.isPdf, isFalse);
      expect(img.formatBadge, equals('PNG'));
      expect(img.formattedFileSize, equals('2.0 KB'));

      final pdf = LandingFileData(
        filePath: 'C:/Users/User/Documents/aadhaar.pdf',
        fileName: 'aadhaar.pdf',
        bytes: Uint8List.fromList([4, 5, 6]),
        fileSizeBytes: 1048576,
        extension: '.pdf',
        modifiedAt: DateTime(2026, 9, 3, 10, 0),
      );

      expect(pdf.isPdf, isTrue);
      expect(pdf.isImage, isFalse);
      expect(pdf.isDocument, isTrue);
      expect(pdf.formatBadge, equals('PDF'));
      expect(pdf.formattedFileSize, equals('1.0 MB'));
    });
  });

  group('OpenWithLandingScreen Widget Tests', () {
    testWidgets('renders file hero card and all 3 destination studio options', (tester) async {
      final dummyPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final dummyFile = LandingFileData(
        filePath: 'C:/Users/User/Pictures/customer_photo.png',
        fileName: 'customer_photo.png',
        bytes: dummyPngBytes,
        fileSizeBytes: 4096,
        extension: '.png',
        modifiedAt: DateTime(2026, 9, 3, 11, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            landingFileProvider.overrideWith((ref) => dummyFile),
            navIndexProvider.overrideWith((ref) => 7),
          ],
          child: const MaterialApp(
            home: OpenWithLandingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and file name
      expect(find.text('Where would you like to continue?'), findsOneWidget);
      expect(find.text('customer_photo.png'), findsOneWidget);
      expect(find.text('4.0 KB'), findsOneWidget);

      // Check the 3 destination cards
      expect(find.text('Photo Printing'), findsOneWidget);
      expect(find.text('Aadhaar / ID Card'), findsOneWidget);
      expect(find.text('Document Printing'), findsOneWidget);

      expect(find.text('Open in Photo Studio'), findsOneWidget);
      expect(find.text('Open in ID Card Studio'), findsOneWidget);
      expect(find.text('Open in Document Studio'), findsOneWidget);

      // Check return button
      expect(find.text('Return to Dashboard'), findsOneWidget);
    });
  });
}
