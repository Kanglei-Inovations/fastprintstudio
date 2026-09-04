import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

class DocxToPdfConverter {
  /// Converts a .docx file bytes to a formatted vector PDF document
  static Future<Uint8List> convert(Uint8List docxBytes) async {
    final archive = ZipDecoder().decodeBytes(docxBytes, verify: false);

    // 1. Locate word/document.xml
    ArchiveFile? docXmlFile;
    ArchiveFile? relsXmlFile;
    final mediaFiles = <String, Uint8List>{};

    for (final file in archive.files) {
      if (file.name == 'word/document.xml') {
        docXmlFile = file;
      } else if (file.name == 'word/_rels/document.xml.rels') {
        relsXmlFile = file;
      } else if (file.name.startsWith('word/media/')) {
        final relName = file.name.substring('word/'.length); // e.g. media/image1.png
        mediaFiles[relName] = file.content;
        mediaFiles[file.name] = file.content;
      }
    }

    if (docXmlFile == null) {
      throw Exception('Invalid DOCX: missing word/document.xml');
    }

    // 2. Parse relationships for embedded media images
    final relsMap = <String, String>{};
    if (relsXmlFile != null) {
      try {
        final relsXml = XmlDocument.parse(String.fromCharCodes(relsXmlFile.content));
        for (final rel in relsXml.findAllElements('Relationship')) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          if (id != null && target != null) {
            relsMap[id] = target;
          }
        }
      } catch (e) {
        debugPrint('Error parsing docx rels: $e');
      }
    }

    // 3. Parse word/document.xml
    final docXml = XmlDocument.parse(String.fromCharCodes(docXmlFile.content));
    final body = docXml.findAllElements('w:body').firstOrNull;
    if (body == null) {
      throw Exception('Invalid DOCX: missing w:body in document.xml');
    }

    // Check page orientation and margins from sectPr
    bool isLandscape = false;
    final sectPr = body.findElements('w:sectPr').firstOrNull ?? docXml.findAllElements('w:sectPr').firstOrNull;
    if (sectPr != null) {
      final pgSz = sectPr.findElements('w:pgSz').firstOrNull;
      if (pgSz != null) {
        final orient = pgSz.getAttribute('w:orient');
        if (orient == 'landscape') {
          isLandscape = true;
        }
      }
    }

    final pdf = pw.Document();
    final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    final widgets = <pw.Widget>[];

    // Process all children in body (<w:p>, <w:tbl>, etc.)
    for (final child in body.children.whereType<XmlElement>()) {
      if (child.name.local == 'p') {
        final pWidget = _parseParagraph(child, relsMap, mediaFiles);
        if (pWidget != null) {
          widgets.add(pWidget);
        }
      } else if (child.name.local == 'tbl') {
        final tblWidget = _parseTable(child, relsMap, mediaFiles);
        if (tblWidget != null) {
          widgets.add(tblWidget);
          widgets.add(pw.SizedBox(height: 8));
        }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            'Blank Word Document',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36), // 0.5 inch margins
        build: (pw.Context context) => widgets,
      ),
    );

    return await pdf.save();
  }

  static pw.Widget? _parseParagraph(
    XmlElement p,
    Map<String, String> relsMap,
    Map<String, Uint8List> mediaFiles,
  ) {
    // Check paragraph alignment
    pw.TextAlign textAlign = pw.TextAlign.left;
    final pPr = p.findElements('w:pPr').firstOrNull;
    if (pPr != null) {
      final jc = pPr.findElements('w:jc').firstOrNull;
      if (jc != null) {
        final val = jc.getAttribute('w:val');
        if (val == 'center') {
          textAlign = pw.TextAlign.center;
        } else if (val == 'right') {
          textAlign = pw.TextAlign.right;
        } else if (val == 'both') {
          textAlign = pw.TextAlign.justify;
        }
      }
    }

    // Check for page break in paragraph
    final isPageBreak = p.findAllElements('w:br').any((br) => br.getAttribute('w:type') == 'page');
    if (isPageBreak) {
      return pw.NewPage();
    }

    // Check for images embedded in this paragraph
    final drawings = p.findAllElements('w:drawing');
    if (drawings.isNotEmpty) {
      for (final drawing in drawings) {
        final blip = drawing.findAllElements('a:blip').firstOrNull;
        if (blip != null) {
          final embedId = blip.getAttribute('r:embed');
          if (embedId != null && relsMap.containsKey(embedId)) {
            final target = relsMap[embedId]!;
            final imgBytes = mediaFiles[target] ?? mediaFiles['word/$target'] ?? mediaFiles['media/$target'];
            if (imgBytes != null && imgBytes.isNotEmpty) {
              try {
                final pdfImage = pw.MemoryImage(imgBytes);
                return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 6),
                  alignment: textAlign == pw.TextAlign.center
                      ? pw.Alignment.center
                      : (textAlign == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
                  child: pw.ConstrainedBox(
                    constraints: const pw.BoxConstraints(maxHeight: 280, maxWidth: 450),
                    child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                  ),
                );
              } catch (_) {}
            }
          }
        }
      }
    }

    // Parse text spans
    final spans = <pw.InlineSpan>[];
    for (final r in p.findElements('w:r')) {
      final rPr = r.findElements('w:rPr').firstOrNull;
      bool isBold = false;
      bool isItalic = false;
      bool isUnderline = false;
      double fontSize = 11.0;
      PdfColor fontColor = PdfColors.black;

      if (rPr != null) {
        if (rPr.findElements('w:b').isNotEmpty) isBold = true;
        if (rPr.findElements('w:i').isNotEmpty) isItalic = true;
        if (rPr.findElements('w:u').isNotEmpty) isUnderline = true;

        final sz = rPr.findElements('w:sz').firstOrNull;
        if (sz != null) {
          final szVal = double.tryParse(sz.getAttribute('w:val') ?? '');
          if (szVal != null && szVal > 0) {
            fontSize = szVal / 2.0; // half-points to pt
          }
        }

        final color = rPr.findElements('w:color').firstOrNull;
        if (color != null) {
          final hex = color.getAttribute('w:val');
          if (hex != null && hex.length == 6) {
            final cInt = int.tryParse('FF$hex', radix: 16);
            if (cInt != null) fontColor = PdfColor.fromInt(cInt);
          }
        }
      }

      final texts = r.findElements('w:t');
      for (final t in texts) {
        final textVal = t.innerText;
        if (textVal.isNotEmpty) {
          spans.add(
            pw.TextSpan(
              text: textVal,
              style: pw.TextStyle(
                fontSize: fontSize.clamp(8.0, 36.0),
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                decoration: isUnderline ? pw.TextDecoration.underline : null,
                color: fontColor,
              ),
            ),
          );
        }
      }
    }

    if (spans.isEmpty) {
      return pw.SizedBox(height: 4); // Empty line spacing
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.RichText(
        textAlign: textAlign,
        text: pw.TextSpan(children: spans),
      ),
    );
  }

  static pw.Widget? _parseTable(
    XmlElement tbl,
    Map<String, String> relsMap,
    Map<String, Uint8List> mediaFiles,
  ) {
    final rows = <pw.TableRow>[];

    for (final tr in tbl.findElements('w:tr')) {
      final cells = <pw.Widget>[];

      for (final tc in tr.findElements('w:tc')) {
        final cellContent = <pw.Widget>[];

        for (final p in tc.findElements('w:p')) {
          final pWidget = _parseParagraph(p, relsMap, mediaFiles);
          if (pWidget != null) {
            cellContent.add(pWidget);
          }
        }

        cells.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: cellContent.isNotEmpty
                ? pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: cellContent)
                : pw.SizedBox(height: 12),
          ),
        );
      }

      if (cells.isNotEmpty) {
        rows.add(pw.TableRow(children: cells));
      }
    }

    if (rows.isEmpty) return null;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: rows,
    );
  }
}
