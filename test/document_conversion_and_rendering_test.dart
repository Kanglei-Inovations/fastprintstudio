import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fastprintstudio/features/documents/models/document_paper_type.dart';
import 'package:fastprintstudio/features/documents/models/document_print_state.dart';
import 'package:fastprintstudio/services/document/converters/docx_to_pdf_converter.dart';
import 'package:fastprintstudio/services/document/converters/pptx_to_pdf_converter.dart';
import 'package:fastprintstudio/services/document/converters/xlsx_to_pdf_converter.dart';
import 'package:fastprintstudio/services/document/detectors/document_type_detector.dart';
import 'package:fastprintstudio/services/document/document_conversion_service.dart';
import 'package:fastprintstudio/services/document/models/printable_document.dart';

/// Helper to create a minimal valid in-memory DOCX ZIP archive
Uint8List createMockDocxBytes({
  required String title,
  required List<String> paragraphs,
  List<List<String>>? tableData,
}) {
  final archive = Archive();

  // [Content_Types].xml
  const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
  archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

  // _rels/.rels
  const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
  archive.addFile(ArchiveFile('_rels/.rels', rootRelsXml.length, utf8.encode(rootRelsXml)));

  // word/_rels/document.xml.rels
  const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';
  archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, utf8.encode(docRelsXml)));

  // word/document.xml
  final bodyBuffer = StringBuffer();
  // Title paragraph
  bodyBuffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="2563EB"/></w:rPr>
        <w:t>$title</w:t>
      </w:r>
    </w:p>
  ''');

  // Paragraphs
  for (final p in paragraphs) {
    bodyBuffer.write('''
      <w:p>
        <w:r>
          <w:rPr><w:sz w:val="22"/></w:rPr>
          <w:t>$p</w:t>
        </w:r>
      </w:p>
    ''');
  }

  // Optional Table
  if (tableData != null && tableData.isNotEmpty) {
    bodyBuffer.write('<w:tbl>');
    for (final row in tableData) {
      bodyBuffer.write('<w:tr>');
      for (final cell in row) {
        bodyBuffer.write('''
          <w:tc>
            <w:p>
              <w:r><w:t>$cell</w:t></w:r>
            </w:p>
          </w:tc>
        ''');
      }
      bodyBuffer.write('</w:tr>');
    }
    bodyBuffer.write('</w:tbl>');
  }

  // Section properties
  bodyBuffer.write('''
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:bottom="1440" w:left="1440" w:right="1440"/>
    </w:sectPr>
  ''');

  final docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    $bodyBuffer
  </w:body>
</w:document>''';
  archive.addFile(ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes);
}

/// Helper to create a minimal valid in-memory XLSX ZIP archive
Uint8List createMockXlsxBytes({required List<List<String>> grid}) {
  final archive = Archive();

  // [Content_Types].xml
  const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>''';
  archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

  // Shared strings
  final sharedStrings = <String>[];
  final sharedMap = <String, int>{};
  for (final row in grid) {
    for (final cell in row) {
      if (!sharedMap.containsKey(cell)) {
        sharedMap[cell] = sharedStrings.length;
        sharedStrings.add(cell);
      }
    }
  }

  final sstBuffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sharedStrings.length}" uniqueCount="${sharedStrings.length}">');
  for (final s in sharedStrings) {
    sstBuffer.write('<si><t>$s</t></si>');
  }
  sstBuffer.write('</sst>');
  archive.addFile(ArchiveFile('xl/sharedStrings.xml', sstBuffer.length, utf8.encode(sstBuffer.toString())));

  // Sheet 1
  final sheetBuffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>');
  for (int r = 0; r < grid.length; r++) {
    sheetBuffer.write('<row r="${r + 1}">');
    for (int c = 0; c < grid[r].length; c++) {
      final colLetter = String.fromCharCode(65 + c);
      final sIdx = sharedMap[grid[r][c]]!;
      sheetBuffer.write('<c r="$colLetter${r + 1}" t="s"><v>$sIdx</v></c>');
    }
    sheetBuffer.write('</row>');
  }
  sheetBuffer.write('</sheetData></worksheet>');
  archive.addFile(ArchiveFile('xl/worksheets/sheet1.xml', sheetBuffer.length, utf8.encode(sheetBuffer.toString())));

  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes);
}

/// Helper to create a minimal valid in-memory PPTX ZIP archive
Uint8List createMockPptxBytes({required List<String> slideTitles}) {
  final archive = Archive();

  // [Content_Types].xml
  const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
</Types>''';
  archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

  for (int i = 0; i < slideTitles.length; i++) {
    final title = slideTitles[i];
    final slideXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>
        <p:txBody>
          <a:p><a:r><a:t>$title</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide${i + 1}.xml', slideXml.length, utf8.encode(slideXml)));
  }

  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentTypeDetector Tests', () {
    test('Detects PDF by extension and magic bytes', () {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35]);
      expect(DocumentTypeDetector.detect(fileName: 'invoice.pdf', bytes: pdfBytes), DocumentFileType.pdf);
      expect(DocumentTypeDetector.detect(fileName: 'INVOICE.PDF'), DocumentFileType.pdf);
    });

    test('Detects DOC and DOCX cleanly', () {
      expect(DocumentTypeDetector.detect(fileName: 'Agreement.docx'), DocumentFileType.docx);
      expect(DocumentTypeDetector.detect(fileName: 'Letter_1997.doc'), DocumentFileType.doc);

      // Legacy OLE2 magic bytes
      final ole2Bytes = Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]);
      expect(DocumentTypeDetector.detect(fileName: 'Document.doc', bytes: ole2Bytes), DocumentFileType.doc);
    });

    test('Detects XLS and XLSX cleanly', () {
      expect(DocumentTypeDetector.detect(fileName: 'Report.xlsx'), DocumentFileType.xlsx);
      expect(DocumentTypeDetector.detect(fileName: 'Accounts.xls'), DocumentFileType.xls);
    });

    test('Detects PPT and PPTX cleanly', () {
      expect(DocumentTypeDetector.detect(fileName: 'PitchDeck.pptx'), DocumentFileType.pptx);
      expect(DocumentTypeDetector.detect(fileName: 'OldSlides.ppt'), DocumentFileType.ppt);
    });

    test('Detects Image types by extension and magic bytes', () {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(DocumentTypeDetector.detect(fileName: 'photo.png', bytes: pngBytes), DocumentFileType.image);

      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      expect(DocumentTypeDetector.detect(fileName: 'scan.jpeg', bytes: jpegBytes), DocumentFileType.image);

      expect(DocumentTypeDetector.detect(fileName: 'banner.webp'), DocumentFileType.image);
      expect(DocumentTypeDetector.detect(fileName: 'artwork.bmp'), DocumentFileType.image);
    });
  });

  group('DocxToPdfConverter Pure-Dart Engine Tests', () {
    test('Converts DOCX paragraphs, formatting, and tables into a valid vector PDF', () async {
      final mockDocx = createMockDocxBytes(
        title: 'Rental Agreement Contract',
        paragraphs: [
          'This agreement is entered into on this 1st day of September.',
          'Tenant agrees to maintain the premises in good condition.',
        ],
        tableData: [
          ['Item', 'Rate', 'Total'],
          ['Monthly Rent', '₹15,000', '₹15,000'],
          ['Security Deposit', '₹50,000', '₹50,000'],
        ],
      );

      final pdfBytes = await DocxToPdfConverter.convert(mockDocx);

      // Verify that output starts with standard %PDF magic header
      expect(pdfBytes.length, greaterThan(100));
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'

      // Verify that raw ZIP/XML header strings are NEVER present in plain character bytes
      final rawString = String.fromCharCodes(pdfBytes.take(500));
      expect(rawString.contains('[Content_Types].xml'), isFalse);
      expect(rawString.contains('word/document.xml'), isFalse);
    });
  });

  group('XlsxToPdfConverter Pure-Dart Engine Tests', () {
    test('Converts XLSX spreadsheet grid into a clean landscape tabular PDF', () async {
      final mockXlsx = createMockXlsxBytes(
        grid: [
          ['Invoice #', 'Customer Name', 'Service', 'Amount', 'Status'],
          ['INV-001', 'Aarav Sharma', 'Aadhaar Card Print', '₹100', 'Paid'],
          ['INV-002', 'Priya Patel', 'Passport 8 Photos', '₹50', 'Paid'],
          ['INV-003', 'Rahul Verma', 'Document Color Print', '₹15', 'Due'],
        ],
      );

      final pdfBytes = await XlsxToPdfConverter.convert(mockXlsx);

      expect(pdfBytes.length, greaterThan(100));
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });
  });

  group('PptxToPdfConverter Pure-Dart Engine Tests', () {
    test('Converts PPTX slides into a slide-by-slide landscape PDF', () async {
      final mockPptx = createMockPptxBytes(
        slideTitles: [
          'FastPrint Studio Overview',
          'Key Print Services',
          'Financial Performance 2026',
        ],
      );

      final pdfBytes = await PptxToPdfConverter.convert(mockPptx);

      expect(pdfBytes.length, greaterThan(100));
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });
  });

  group('DocumentConversionService Pipeline & Normalized Architecture Tests', () {
    test('Successfully processes DOCX through the complete pipeline into PrintableDocument', () async {
      final mockDocx = createMockDocxBytes(
        title: 'Project Proposal',
        paragraphs: [
          'Scope of work includes multi-format print automation.',
          'Delivery scheduled within the timeline.',
        ],
      );

      final printableDoc = await DocumentConversionService.convertAndRender(
        bytes: mockDocx,
        fileName: 'Proposal.docx',
      );

      expect(printableDoc.sourceType, DocumentFileType.docx);
      expect(printableDoc.renderStatus, DocumentRenderStatus.ready);
      expect(printableDoc.hasError, isFalse);
      expect(printableDoc.pageCount, greaterThanOrEqualTo(1));
      expect(printableDoc.pages.length, printableDoc.pageCount);
      expect(printableDoc.convertedPdfBytes, isNotNull);
      expect(printableDoc.pages.first.imageBytes.isNotEmpty, isTrue);
    });

    test('Successfully processes Image file into PrintableDocument', () async {
      // Create small 100x100 PNG
      final imgObj = img.Image(width: 100, height: 100);
      img.fill(imgObj, color: img.ColorRgba8(255, 0, 0, 255));
      final pngBytes = Uint8List.fromList(img.encodePng(imgObj));

      final printableDoc = await DocumentConversionService.convertAndRender(
        bytes: pngBytes,
        fileName: 'stamp_photo.png',
      );

      expect(printableDoc.sourceType, DocumentFileType.image);
      expect(printableDoc.renderStatus, DocumentRenderStatus.ready);
      expect(printableDoc.pageCount, 1);
      expect(printableDoc.pages.first.imageBytes.isNotEmpty, isTrue);
    });

    test('Successfully processes PDF file into PrintableDocument', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Center(child: pw.Text('Test PDF Page 1')),
        ),
      );
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Center(child: pw.Text('Test PDF Page 2')),
        ),
      );
      final pdfBytes = await pdf.save();

      final printableDoc = await DocumentConversionService.convertAndRender(
        bytes: pdfBytes,
        fileName: 'sample_2page.pdf',
      );

      expect(printableDoc.sourceType, DocumentFileType.pdf);
      expect(printableDoc.renderStatus, DocumentRenderStatus.ready);
      expect(printableDoc.pageCount, 2);
      expect(printableDoc.pages.length, 2);
    });
  });

  group('DocumentPrintState & Multi-Page Navigation Tests', () {
    test('State calculates correct pages and financials for multi-page documents', () {
      final state = DocumentPrintState(
        fileName: 'Annual_Report.docx',
        fileType: 'Word Document',
        fileSize: 45000,
        renderedPages: [
          Uint8List(10),
          Uint8List(10),
          Uint8List(10),
          Uint8List(10),
          Uint8List(10),
        ],
        activePageIndex: 0,
        copies: 2,
        colorMode: ColorMode.blackAndWhite,
        paperType: DocumentPaperType.normal70Gsm,
      );

      expect(state.hasDocument, isTrue);
      expect(state.totalPages, 5);
      expect(state.pagesToPrint, 5);
      expect(state.totalSheetsToPrint, 10); // 5 pages * 2 copies
      expect(state.calculatedSellingPrice, 5 * 2.0 * 2); // ₹20.0
      expect(state.formattedFileSize, '43.9 KB');
    });
  });
}
