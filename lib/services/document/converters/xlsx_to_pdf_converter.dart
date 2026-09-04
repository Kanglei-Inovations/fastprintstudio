import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

class XlsxToPdfConverter {
  /// Converts an .xlsx file bytes to a multi-page tabular PDF document
  static Future<Uint8List> convert(Uint8List xlsxBytes) async {
    final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);

    // 1. Read shared strings
    final sharedStrings = <String>[];
    for (final file in archive.files) {
      if (file.name == 'xl/sharedStrings.xml') {
        final xml = XmlDocument.parse(String.fromCharCodes(file.content));
        for (final si in xml.findAllElements('si')) {
          final textBuffer = StringBuffer();
          for (final t in si.findAllElements('t')) {
            textBuffer.write(t.innerText);
          }
          sharedStrings.add(textBuffer.toString());
        }
      }
    }

    // 2. Read sheet1.xml (or first available sheet)
    ArchiveFile? sheetFile;
    for (final file in archive.files) {
      if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
        sheetFile = file;
        break;
      }
    }

    if (sheetFile == null) {
      throw Exception('Invalid XLSX: missing worksheet XML');
    }

    final sheetXml = XmlDocument.parse(String.fromCharCodes(sheetFile.content));
    final rowsData = <List<String>>[];

    int maxCols = 0;
    for (final row in sheetXml.findAllElements('row')) {
      final cells = <int, String>{};
      int highestColIdx = 0;

      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r') ?? '';
        final colIdx = _colRefToIndex(ref);
        highestColIdx = max(highestColIdx, colIdx);

        final type = c.getAttribute('t');
        final v = c.findElements('v').firstOrNull?.innerText ?? '';

        String cellVal = '';
        if (type == 's') {
          final sIdx = int.tryParse(v);
          if (sIdx != null && sIdx >= 0 && sIdx < sharedStrings.length) {
            cellVal = sharedStrings[sIdx];
          }
        } else if (type == 'inlineStr') {
          cellVal = c.findAllElements('t').map((e) => e.innerText).join();
        } else {
          cellVal = v;
        }

        cells[colIdx] = cellVal;
      }

      final rowList = <String>[];
      for (int i = 0; i <= highestColIdx; i++) {
        rowList.add(cells[i] ?? '');
      }

      // Only add row if at least one cell has content
      if (rowList.any((val) => val.trim().isNotEmpty)) {
        rowsData.add(rowList);
        maxCols = max(maxCols, rowList.length);
      }
    }

    if (rowsData.isEmpty) {
      rowsData.add(['Empty Spreadsheet']);
      maxCols = 1;
    }

    // Standardize all rows to maxCols
    final normalizedRows = rowsData.map((row) {
      if (row.length < maxCols) {
        return [...row, ...List.filled(maxCols - row.length, '')];
      }
      return row;
    }).toList();

    // 3. Build multi-page landscape PDF
    final pdf = pw.Document();
    const rowsPerPage = 28;
    final totalPages = (normalizedRows.length / rowsPerPage).ceil();

    for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
      final start = pageIdx * rowsPerPage;
      final end = min(start + rowsPerPage, normalizedRows.length);
      final pageRows = normalizedRows.sublist(start, end);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Sheet 1  (Rows ${start + 1}-$end of ${normalizedRows.length})',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                    pw.Text(
                      'Page ${pageIdx + 1} of $totalPages',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                    children: pageRows.asMap().entries.map((entry) {
                      final rIdx = entry.key;
                      final row = entry.value;
                      final isHeader = (pageIdx == 0 && rIdx == 0);

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isHeader
                              ? PdfColors.blue50
                              : (rIdx % 2 == 0 ? PdfColors.white : PdfColors.grey100),
                        ),
                        children: row.map((cell) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                            child: pw.Text(
                              cell,
                              style: pw.TextStyle(
                                fontSize: maxCols > 8 ? 7.5 : 9.0,
                                fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                                color: isHeader ? PdfColors.blue900 : PdfColors.black,
                              ),
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  static int _colRefToIndex(String cellRef) {
    int index = 0;
    for (int i = 0; i < cellRef.length; i++) {
      final code = cellRef.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        // 'A'-'Z'
        index = (index * 26) + (code - 64);
      } else {
        break;
      }
    }
    return max(0, index - 1);
  }
}
