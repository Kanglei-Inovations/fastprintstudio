import 'dart:typed_data';
import '../../../core/models/paper_preset.dart';

enum DocumentFileType {
  pdf('PDF Document', '.pdf'),
  doc('Word 97-2003 Document', '.doc'),
  docx('Word Document', '.docx'),
  xls('Excel 97-2003 Spreadsheet', '.xls'),
  xlsx('Excel Spreadsheet', '.xlsx'),
  ppt('PowerPoint 97-2003 Presentation', '.ppt'),
  pptx('PowerPoint Presentation', '.pptx'),
  image('Image File', '.img'),
  unknown('Unknown Document', '');

  final String displayName;
  final String primaryExtension;
  const DocumentFileType(this.displayName, this.primaryExtension);

  bool get isWord => this == DocumentFileType.doc || this == DocumentFileType.docx;
  bool get isExcel => this == DocumentFileType.xls || this == DocumentFileType.xlsx;
  bool get isPowerPoint => this == DocumentFileType.ppt || this == DocumentFileType.pptx;
  bool get isOfficeDocument => isWord || isExcel || isPowerPoint;
  bool get isPdf => this == DocumentFileType.pdf;
  bool get isImage => this == DocumentFileType.image;
}

enum DocumentRenderStatus {
  idle,
  preparing,
  ready,
  error,
}

class PrintablePage {
  final int pageNumber; // 1-based index
  final Uint8List imageBytes; // Rendered raster image for preview & print
  final double widthPt;
  final double heightPt;

  const PrintablePage({
    required this.pageNumber,
    required this.imageBytes,
    this.widthPt = 595.28, // A4 default width in points (72 pt/in)
    this.heightPt = 841.89, // A4 default height in points
  });

  double get aspectRatio => widthPt > 0 && heightPt > 0 ? widthPt / heightPt : 1.0;
  PaperOrientation get orientation => widthPt > heightPt ? PaperOrientation.landscape : PaperOrientation.portrait;
}

class PrintableDocument {
  final DocumentFileType sourceType;
  final String originalFileName;
  final int fileSize;
  final int pageCount;
  final List<PrintablePage> pages;
  final double pageWidth;
  final double pageHeight;
  final PaperOrientation orientation;
  final DocumentRenderStatus renderStatus;
  final String? conversionError;
  final Uint8List? convertedPdfBytes; // Standardized vector/print PDF
  final Uint8List? rawBytes;

  const PrintableDocument({
    required this.sourceType,
    required this.originalFileName,
    this.fileSize = 0,
    this.pageCount = 0,
    this.pages = const [],
    this.pageWidth = 210.0, // mm
    this.pageHeight = 297.0, // mm
    this.orientation = PaperOrientation.portrait,
    this.renderStatus = DocumentRenderStatus.idle,
    this.conversionError,
    this.convertedPdfBytes,
    this.rawBytes,
  });

  bool get isReady => renderStatus == DocumentRenderStatus.ready && pages.isNotEmpty;
  bool get hasError => renderStatus == DocumentRenderStatus.error || conversionError != null;

  PrintablePage? getPage(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return null;
  }

  PrintableDocument copyWith({
    DocumentFileType? sourceType,
    String? originalFileName,
    int? fileSize,
    int? pageCount,
    List<PrintablePage>? pages,
    double? pageWidth,
    double? pageHeight,
    PaperOrientation? orientation,
    DocumentRenderStatus? renderStatus,
    String? conversionError,
    bool clearError = false,
    Uint8List? convertedPdfBytes,
    Uint8List? rawBytes,
  }) {
    return PrintableDocument(
      sourceType: sourceType ?? this.sourceType,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      pages: pages ?? this.pages,
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      orientation: orientation ?? this.orientation,
      renderStatus: renderStatus ?? this.renderStatus,
      conversionError: clearError ? null : (conversionError ?? this.conversionError),
      convertedPdfBytes: convertedPdfBytes ?? this.convertedPdfBytes,
      rawBytes: rawBytes ?? this.rawBytes,
    );
  }
}
