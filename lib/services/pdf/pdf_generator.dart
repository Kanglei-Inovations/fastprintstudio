import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/models/print_layout.dart';

class PdfGenerator {
  /// Generates a print-ready single-page PDF binary.
  static Future<Uint8List> generatePrintPdf(PrintLayout layout) async {
    return generateMultiPagePdf([layout]);
  }

  /// Generates a print-ready multi-page PDF binary where each layout represents a separate physical page.
  static Future<Uint8List> generateMultiPagePdf(List<PrintLayout> layouts) async {
    if (layouts.isEmpty) return Uint8List(0);

    final firstLayout = layouts.first;
    final pdf = pw.Document(
      title: '${firstLayout.serviceType} - FastPrint Studio',
      author: 'FastPrint Studio',
      creator: 'FastPrint Studio',
    );

    for (final layout in layouts) {
      final pageFormat = PdfPageFormat(
        layout.paperWidthPt,
        layout.paperHeightPt,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      );

      final imageWidgets = <pw.Widget>[];

      for (final item in layout.items) {
        final imageProvider = pw.MemoryImage(item.imageBytes);

        imageWidgets.add(
          pw.Positioned(
            left: item.xPt,
            top: item.yPt,
            child: pw.SizedBox(
              width: item.widthPt,
              height: item.heightPt,
              child: item.rotationDegrees != 0
                  ? pw.Transform.rotateBox(
                      angle: item.rotationDegrees * 3.1415926535897932 / 180.0,
                      child: pw.Image(
                        imageProvider,
                        fit: pw.BoxFit.fill,
                      ),
                    )
                  : pw.Image(
                      imageProvider,
                      fit: pw.BoxFit.fill, // Exact physical bounds
                    ),
            ),
          ),
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Stack(
              children: imageWidgets,
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
