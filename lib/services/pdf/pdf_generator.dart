import 'dart:math' as math;
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

      final isL805 = layout.paperPreset.id.contains('l805') ||
          layout.serviceType.toLowerCase().contains('l805') ||
          layout.paperPreset.id == 'l805_tray';

      final isDragon = layout.showDragonCutLines &&
          !isL805 &&
          (layout.paperPreset.id == 'dragon_sheet_200x300' ||
              layout.serviceType.toLowerCase().contains('dragon'));

      final isLamination = layout.showDragonCutLines &&
          !isDragon &&
          !isL805 &&
          (layout.paperPreset.id == '4r' ||
              layout.paperPreset.id == 'four_r' ||
              layout.paperPreset.id == 'a4' ||
              layout.serviceType.toLowerCase().contains('lamination') ||
              layout.serviceType.toLowerCase().contains('aadhaar') ||
              layout.serviceType.toLowerCase().contains('id card'));

      if (isDragon && layout.items.isNotEmpty) {
        imageWidgets.addAll(_buildDragonCutLines(layout));
      } else if (isLamination && layout.items.isNotEmpty) {
        imageWidgets.addAll(_buildLaminationCutLines(layout));
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

  static List<pw.Widget> _buildDragonCutLines(PrintLayout layout) {
    if (layout.items.isEmpty) return [];

    double minX = layout.items.first.xPt;
    double minY = layout.items.first.yPt;
    double maxX = layout.items.first.xPt + layout.items.first.widthPt;
    double maxY = layout.items.first.yPt + layout.items.first.heightPt;

    final horizontalYs = <double>{};

    for (final it in layout.items) {
      minX = math.min(minX, it.xPt);
      minY = math.min(minY, it.yPt);
      maxX = math.max(maxX, it.xPt + it.widthPt);
      maxY = math.max(maxY, it.yPt + it.heightPt);

      horizontalYs.add((it.yPt * 10).round() / 10.0);
      horizontalYs.add(((it.yPt + it.heightPt) * 10).round() / 10.0);
    }

    final centerPt = layout.paperWidthPt / 2.0;
    const borderSide = pw.BorderSide(
      color: PdfColors.red,
      width: 0.5,
      style: pw.BorderStyle.dashed,
    );

    final widgets = <pw.Widget>[];

    // 1. Vertical left cut line
    widgets.add(
      pw.Positioned(
        left: minX,
        top: minY,
        child: pw.Container(
          height: maxY - minY,
          width: 0.5,
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: borderSide),
          ),
        ),
      ),
    );

    // 2. Vertical center cut line (middle of Dragon Sheet between Front and Back)
    widgets.add(
      pw.Positioned(
        left: centerPt,
        top: minY,
        child: pw.Container(
          height: maxY - minY,
          width: 0.5,
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: borderSide),
          ),
        ),
      ),
    );

    // 3. Vertical right cut line
    widgets.add(
      pw.Positioned(
        left: maxX,
        top: minY,
        child: pw.Container(
          height: maxY - minY,
          width: 0.5,
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: borderSide),
          ),
        ),
      ),
    );

    // 4. Horizontal row cut lines
    for (final y in horizontalYs) {
      widgets.add(
        pw.Positioned(
          left: minX,
          top: y,
          child: pw.Container(
            width: maxX - minX,
            height: 0.5,
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: borderSide),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildLaminationCutLines(PrintLayout layout) {
    if (layout.items.isEmpty) return [];

    const borderSide = pw.BorderSide(
      color: PdfColors.red,
      width: 0.5,
      style: pw.BorderStyle.dashed,
    );

    final widgets = <pw.Widget>[];
    final pairedItemIds = <String>{};

    // 1. Foldable card pairs (Front stacked above Back rotated 180°)
    for (int i = 0; i < layout.items.length; i++) {
      final backItem = layout.items[i];
      if (backItem.rotationDegrees == 180) {
        for (int j = 0; j < layout.items.length; j++) {
          if (i == j) continue;
          final frontItem = layout.items[j];
          if ((frontItem.xPt - backItem.xPt).abs() < 15.0 &&
              frontItem.yPt < backItem.yPt &&
              (backItem.yPt - (frontItem.yPt + frontItem.heightPt)).abs() < 30.0) {
            pairedItemIds.add(backItem.id);
            pairedItemIds.add(frontItem.id);

            final pairLeft = math.min(frontItem.xPt, backItem.xPt);
            final pairRight = math.max(frontItem.xPt + frontItem.widthPt, backItem.xPt + backItem.widthPt);
            final pairTop = frontItem.yPt;
            final pairBottom = backItem.yPt + backItem.heightPt;
            final pairW = pairRight - pairLeft;
            final pairH = pairBottom - pairTop;

            // Top cut line
            widgets.add(pw.Positioned(
              left: pairLeft,
              top: pairTop,
              child: pw.Container(
                width: pairW,
                height: 0.5,
                decoration: const pw.BoxDecoration(border: pw.Border(top: borderSide)),
              ),
            ));

            // Bottom cut line
            widgets.add(pw.Positioned(
              left: pairLeft,
              top: pairBottom,
              child: pw.Container(
                width: pairW,
                height: 0.5,
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
              ),
            ));

            // Left cut line
            widgets.add(pw.Positioned(
              left: pairLeft,
              top: pairTop,
              child: pw.Container(
                width: 0.5,
                height: pairH,
                decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
              ),
            ));

            // Right cut line
            widgets.add(pw.Positioned(
              left: pairRight,
              top: pairTop,
              child: pw.Container(
                width: 0.5,
                height: pairH,
                decoration: const pw.BoxDecoration(border: pw.Border(right: borderSide)),
              ),
            ));

            // NOTE: Middle between front and back has NO cut line (fold line)
            break;
          }
        }
      }
    }

    // 2. Standalone or non-stacked items on Lamination
    for (final item in layout.items) {
      if (pairedItemIds.contains(item.id)) continue;

      final left = item.xPt;
      final top = item.yPt;
      final w = item.widthPt;
      final h = item.heightPt;

      widgets.add(pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: w,
          height: 0.5,
          decoration: const pw.BoxDecoration(border: pw.Border(top: borderSide)),
        ),
      ));

      widgets.add(pw.Positioned(
        left: left,
        top: top + h,
        child: pw.Container(
          width: w,
          height: 0.5,
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
        ),
      ));

      widgets.add(pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: 0.5,
          height: h,
          decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
        ),
      ));

      widgets.add(pw.Positioned(
        left: left + w,
        top: top,
        child: pw.Container(
          width: 0.5,
          height: h,
          decoration: const pw.BoxDecoration(border: pw.Border(right: borderSide)),
        ),
      ));
    }

    return widgets;
  }
}
