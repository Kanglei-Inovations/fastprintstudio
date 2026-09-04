import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PdfStatus {
  normal,
  passwordProtected,
  malformed,
  unsupported,
}

class PdfInspectionResult {
  final PdfStatus status;
  final int pageCount;
  final String? errorMessage;
  final bool isEncrypted;

  const PdfInspectionResult({
    required this.status,
    this.pageCount = 0,
    this.errorMessage,
    this.isEncrypted = false,
  });
}

class PdfUnlockResult {
  final bool success;
  final Uint8List? decryptedBytes;
  final String? errorMessage;
  final int pageCount;

  const PdfUnlockResult({
    required this.success,
    this.decryptedBytes,
    this.errorMessage,
    this.pageCount = 0,
  });
}

class PdfInspector {
  /// Quick header & binary inspection to check if PDF is encrypted or password protected.
  static PdfInspectionResult inspectPdf(Uint8List bytes) {
    if (bytes.length < 10) {
      return const PdfInspectionResult(
        status: PdfStatus.malformed,
        errorMessage: 'Unable to read this PDF. The file is empty or corrupted.',
      );
    }

    // Verify PDF header magic bytes (%PDF)
    final headerStr = String.fromCharCodes(bytes.take(10));
    if (!headerStr.contains('%PDF')) {
      return const PdfInspectionResult(
        status: PdfStatus.malformed,
        errorMessage: 'Unable to read this PDF. The file may be damaged or unsupported.',
      );
    }

    // Try loading with Syncfusion PDF
    try {
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      return PdfInspectionResult(
        status: PdfStatus.normal,
        pageCount: pageCount,
        isEncrypted: false,
      );
    } on ArgumentError catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('encrypted') || msg.contains('security')) {
        return const PdfInspectionResult(
          status: PdfStatus.passwordProtected,
          isEncrypted: true,
          errorMessage: 'This PDF is password protected.',
        );
      }
      return PdfInspectionResult(
        status: PdfStatus.malformed,
        errorMessage: 'Unable to read this PDF. The file may be damaged or unsupported.',
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // Check for password/encryption indicators
      if (msg.contains('password') ||
          msg.contains('encrypted') ||
          msg.contains('security') ||
          msg.contains('owner') ||
          msg.contains('user password')) {
        return const PdfInspectionResult(
          status: PdfStatus.passwordProtected,
          isEncrypted: true,
          errorMessage: 'This PDF is password protected.',
        );
      }

      // Check byte stream for /Encrypt dictionary as fallback
      final hasEncryptTag = _hasEncryptTag(bytes);
      if (hasEncryptTag) {
        return const PdfInspectionResult(
          status: PdfStatus.passwordProtected,
          isEncrypted: true,
          errorMessage: 'This PDF is password protected.',
        );
      }

      return PdfInspectionResult(
        status: PdfStatus.malformed,
        errorMessage: 'Unable to read this PDF. The file may be damaged or unsupported.',
      );
    }
  }

  /// Attempts to unlock/decrypt an encrypted PDF using the user provided password.
  static Future<PdfUnlockResult> unlockPdf({
    required Uint8List pdfBytes,
    required String password,
  }) async {
    try {
      // Attempt loading with password
      final document = PdfDocument(
        inputBytes: pdfBytes,
        password: password,
      );

      final pageCount = document.pages.count;
      if (pageCount == 0) {
        document.dispose();
        return const PdfUnlockResult(
          success: false,
          errorMessage: 'PDF has no readable pages.',
        );
      }

      // Create a brand-new clean unencrypted PDF document and copy all pages
      final cleanDoc = PdfDocument();
      cleanDoc.pageSettings.margins.all = 0;

      for (int i = 0; i < pageCount; i++) {
        final page = document.pages[i];
        final pageSize = page.size;
        final template = page.createTemplate();
        final cleanPage = cleanDoc.pages.add();
        cleanPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          pageSize,
        );
      }

      final unencryptedBytes = Uint8List.fromList(cleanDoc.saveSync());
      cleanDoc.dispose();
      document.dispose();

      return PdfUnlockResult(
        success: true,
        decryptedBytes: unencryptedBytes,
        pageCount: pageCount,
      );
    } on ArgumentError catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('incorrect') || msg.contains('invalid')) {
        return const PdfUnlockResult(
          success: false,
          errorMessage: 'Incorrect PDF password. Please try again.',
        );
      }
      return const PdfUnlockResult(
        success: false,
        errorMessage: 'Incorrect PDF password. Please try again.',
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('incorrect') || msg.contains('invalid') || msg.contains('match')) {
        return const PdfUnlockResult(
          success: false,
          errorMessage: 'Incorrect PDF password. Please try again.',
        );
      }
      return PdfUnlockResult(
        success: false,
        errorMessage: 'Unable to decrypt this PDF. $e',
      );
    }
  }

  static bool _hasEncryptTag(Uint8List bytes) {
    try {
      final len = bytes.length;
      final searchChunkSize = len > 8192 ? 8192 : len;
      final endBytes = bytes.sublist(len - searchChunkSize);
      final content = String.fromCharCodes(endBytes);
      return content.contains('/Encrypt');
    } catch (_) {
      return false;
    }
  }
}
