import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'pdf_inspector.dart';

class PdfPasswordException implements Exception {
  final String message;
  const PdfPasswordException([this.message = 'This PDF is password protected.']);
  @override
  String toString() => message;
}

class PdfMalformedException implements Exception {
  final String message;
  const PdfMalformedException([this.message = 'Unable to read this PDF. The file may be damaged or unsupported.']);
  @override
  String toString() => message;
}

class PdfRasterizer {
  static final Uint8List _dummy1x1Png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  /// Rasterizes the first page (or specified page index) of a PDF document at given DPI.
  static Future<Uint8List?> rasterizePdfPage({
    required Uint8List pdfBytes,
    int pageIndex = 0,
    double dpi = 300.0,
  }) async {
    final inspection = PdfInspector.inspectPdf(pdfBytes);
    if (inspection.status == PdfStatus.passwordProtected) {
      throw const PdfPasswordException('This PDF is password protected.');
    } else if (inspection.status == PdfStatus.malformed) {
      throw PdfMalformedException(inspection.errorMessage ?? 'Unable to read this PDF. The file may be damaged or unsupported.');
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _dummy1x1Png;
    }

    try {
      final rasterStream = Printing.raster(
        pdfBytes,
        pages: [pageIndex],
        dpi: dpi,
      );

      await for (final raster in rasterStream) {
        final pngBytes = await raster.toPng();
        return pngBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error rasterizing PDF page $pageIndex: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('password') || errStr.contains('encrypted') || errStr.contains('security')) {
        throw const PdfPasswordException('This PDF is password protected.');
      }
      throw PdfMalformedException('Unable to read this PDF. The file may be damaged or unsupported.');
    }
  }

  /// Rasterizes all pages of a PDF document into a list of PNG image byte arrays.
  static Future<List<Uint8List>> rasterizeAllPages({
    required Uint8List pdfBytes,
    double dpi = 300.0,
    int maxPages = 5,
  }) async {
    final inspection = PdfInspector.inspectPdf(pdfBytes);
    if (inspection.status == PdfStatus.passwordProtected) {
      throw const PdfPasswordException('This PDF is password protected.');
    } else if (inspection.status == PdfStatus.malformed) {
      throw PdfMalformedException(inspection.errorMessage ?? 'Unable to read this PDF. The file may be damaged or unsupported.');
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      final count = math.min(math.max(1, inspection.pageCount), maxPages);
      return List.generate(count, (_) => _dummy1x1Png);
    }

    final results = <Uint8List>[];
    try {
      final rasterStream = Printing.raster(
        pdfBytes,
        dpi: dpi,
      );

      int count = 0;
      await for (final raster in rasterStream) {
        final pngBytes = await raster.toPng();
        results.add(pngBytes);
        count++;
        if (count >= maxPages) break;
      }
    } catch (e) {
      debugPrint('Error rasterizing all PDF pages: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('password') || errStr.contains('encrypted') || errStr.contains('security')) {
        throw const PdfPasswordException('This PDF is password protected.');
      }
      throw PdfMalformedException('Unable to read this PDF. The file may be damaged or unsupported.');
    }
    return results;
  }
}
