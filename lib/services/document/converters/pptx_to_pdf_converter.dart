import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

class PptxToPdfConverter {
  /// Converts a .pptx file bytes to a slide-by-slide landscape PDF document
  static Future<Uint8List> convert(Uint8List pptxBytes) async {
    final archive = ZipDecoder().decodeBytes(pptxBytes, verify: false);

    // 1. Gather media files
    final mediaFiles = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.startsWith('ppt/media/')) {
        final relName = file.name.substring('ppt/'.length); // media/image1.png
        mediaFiles[relName] = file.content;
        mediaFiles[file.name] = file.content;
      }
    }

    // 2. Discover slide files
    final slideFiles = <int, ArchiveFile>{};
    final relsFiles = <int, ArchiveFile>{};

    final slideRegex = RegExp(r'ppt/slides/slide(\d+)\.xml');
    final relsRegex = RegExp(r'ppt/slides/_rels/slide(\d+)\.xml\.rels');

    for (final file in archive.files) {
      final sMatch = slideRegex.firstMatch(file.name);
      if (sMatch != null) {
        final num = int.tryParse(sMatch.group(1) ?? '0') ?? 0;
        slideFiles[num] = file;
      }
      final rMatch = relsRegex.firstMatch(file.name);
      if (rMatch != null) {
        final num = int.tryParse(rMatch.group(1) ?? '0') ?? 0;
        relsFiles[num] = file;
      }
    }

    if (slideFiles.isEmpty) {
      throw Exception('Invalid PPTX: no slides found');
    }

    final sortedSlideNums = slideFiles.keys.toList()..sort();
    final pdf = pw.Document();

    for (final slideNum in sortedSlideNums) {
      final sFile = slideFiles[slideNum]!;
      final rFile = relsFiles[slideNum];

      // Parse slide rels
      final slideRels = <String, String>{};
      if (rFile != null) {
        try {
          final rXml = XmlDocument.parse(String.fromCharCodes(rFile.content));
          for (final rel in rXml.findAllElements('Relationship')) {
            final id = rel.getAttribute('Id');
            final target = rel.getAttribute('Target');
            if (id != null && target != null) {
              slideRels[id] = target.replaceAll('../', '');
            }
          }
        } catch (_) {}
      }

      // Parse slide content
      final slideXml = XmlDocument.parse(String.fromCharCodes(sFile.content));

      String slideTitle = '';
      final bodyParagraphs = <String>[];
      final slideImages = <Uint8List>[];

      // Text shapes
      for (final sp in slideXml.findAllElements('p:sp')) {
        final isTitle = sp.findAllElements('p:ph').any((ph) => ph.getAttribute('type') == 'title' || ph.getAttribute('type') == 'ctrTitle');

        final paragraphs = sp.findAllElements('a:p');
        for (final p in paragraphs) {
          final text = p.findAllElements('a:t').map((t) => t.innerText).join().trim();
          if (text.isNotEmpty) {
            if (isTitle && slideTitle.isEmpty) {
              slideTitle = text;
            } else {
              bodyParagraphs.add(text);
            }
          }
        }
      }

      // Picture shapes
      for (final pic in slideXml.findAllElements('p:pic')) {
        final blip = pic.findAllElements('a:blip').firstOrNull;
        if (blip != null) {
          final embedId = blip.getAttribute('r:embed');
          if (embedId != null && slideRels.containsKey(embedId)) {
            final target = slideRels[embedId]!;
            final imgBytes = mediaFiles[target] ?? mediaFiles['ppt/$target'] ?? mediaFiles['media/$target'];
            if (imgBytes != null && imgBytes.isNotEmpty) {
              slideImages.add(imgBytes);
            }
          }
        }
      }

      if (slideTitle.isEmpty && bodyParagraphs.isEmpty && slideImages.isEmpty) {
        slideTitle = 'Slide $slideNum';
      }

      // Build landscape slide page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Slide Header / Title
                if (slideTitle.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 1.5)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            slideTitle,
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                        ),
                        pw.Text(
                          'Slide $slideNum of ${sortedSlideNums.length}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Body content & side-by-side images
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Text content
                      if (bodyParagraphs.isNotEmpty)
                        pw.Expanded(
                          flex: slideImages.isNotEmpty ? 3 : 5,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: bodyParagraphs.map((para) {
                              return pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      margin: const pw.EdgeInsets.only(top: 5, right: 8),
                                      width: 4,
                                      height: 4,
                                      decoration: const pw.BoxDecoration(
                                        color: PdfColors.blue700,
                                        shape: pw.BoxShape.circle,
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        para,
                                        style: const pw.TextStyle(fontSize: 13, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      if (bodyParagraphs.isNotEmpty && slideImages.isNotEmpty)
                        pw.SizedBox(width: 16),

                      // Image(s)
                      if (slideImages.isNotEmpty)
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            children: slideImages.take(2).map((imgBytes) {
                              try {
                                return pw.Container(
                                  margin: const pw.EdgeInsets.only(bottom: 8),
                                  child: pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.contain),
                                );
                              } catch (_) {
                                return pw.SizedBox();
                              }
                            }).toList(),
                          ),
                        ),
                    ],
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
}
