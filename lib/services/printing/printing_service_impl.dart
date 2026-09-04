import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/models/print_layout.dart';
import '../pdf/pdf_generator.dart';
import 'printer_service.dart';

class PrintingServiceImpl implements PrinterService {
  @override
  Future<List<Printer>> getPrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  @override
  Future<Printer?> getDefaultPrinter() async {
    try {
      final printers = await getPrinters();
      if (printers.isEmpty) return null;
      return printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );
    } catch (e) {
      debugPrint('Error getting default printer: $e');
      return null;
    }
  }

  @override
  Future<bool> printLayout(
    PrintLayout layout, {
    Printer? printer,
    String? jobName,
  }) async {
    try {
      final pdfBytes = await PdfGenerator.generatePrintPdf(layout);
      final pageFormat = PdfPageFormat(
        layout.paperWidthPt,
        layout.paperHeightPt,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      );

      final name = jobName ?? '${layout.serviceType} Print';

      if (printer != null) {
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) async => pdfBytes,
          name: name,
          format: pageFormat,
        );
      } else {
        return await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: name,
          format: pageFormat,
        );
      }
    } catch (e) {
      debugPrint('Error printing layout: $e');
      return false;
    }
  }

  @override
  Future<bool> directPrintPdf(
    Uint8List pdfBytes, {
    Printer? printer,
    String? jobName,
  }) async {
    try {
      if (printer != null) {
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) async => pdfBytes,
          name: jobName ?? 'FastPrint Job',
        );
      } else {
        return await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: jobName ?? 'FastPrint Job',
        );
      }
    } catch (e) {
      debugPrint('Error direct printing PDF: $e');
      return false;
    }
  }

  @override
  Future<bool> showPrintDialog(PrintLayout layout) async {
    try {
      final pdfBytes = await PdfGenerator.generatePrintPdf(layout);
      final pageFormat = PdfPageFormat(
        layout.paperWidthPt,
        layout.paperHeightPt,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      );

      return await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: '${layout.serviceType} Print',
        format: pageFormat,
      );
    } catch (e) {
      debugPrint('Error showing print dialog: $e');
      return false;
    }
  }

  @override
  Future<bool> exportPdf(PrintLayout layout, String suggestedFileName) async {
    try {
      final pdfBytes = await PdfGenerator.generatePrintPdf(layout);
      return await Printing.sharePdf(
        bytes: pdfBytes,
        filename: suggestedFileName.endsWith('.pdf') ? suggestedFileName : '$suggestedFileName.pdf',
      );
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return false;
    }
  }

  @override
  Future<bool> printMultiLayout(
    List<PrintLayout> layouts, {
    Printer? printer,
    String? jobName,
  }) async {
    try {
      if (layouts.isEmpty) return false;
      final pdfBytes = await PdfGenerator.generateMultiPagePdf(layouts);
      final firstLayout = layouts.first;
      final pageFormat = PdfPageFormat(
        firstLayout.paperWidthPt,
        firstLayout.paperHeightPt,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      );

      final name = jobName ?? '${firstLayout.serviceType} Print';

      if (printer != null) {
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) async => pdfBytes,
          name: name,
          format: pageFormat,
        );
      } else {
        return await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: name,
          format: pageFormat,
        );
      }
    } catch (e) {
      debugPrint('Error printing multi-layout: $e');
      return false;
    }
  }

  @override
  Future<bool> exportMultiLayoutPdf(
    List<PrintLayout> layouts,
    String suggestedFileName,
  ) async {
    try {
      if (layouts.isEmpty) return false;
      final pdfBytes = await PdfGenerator.generateMultiPagePdf(layouts);
      final name = suggestedFileName.endsWith('.pdf') ? suggestedFileName : '$suggestedFileName.pdf';
      return await Printing.sharePdf(
        bytes: pdfBytes,
        filename: name,
      );
    } catch (e) {
      debugPrint('Error exporting multi-layout PDF: $e');
      return false;
    }
  }
}
