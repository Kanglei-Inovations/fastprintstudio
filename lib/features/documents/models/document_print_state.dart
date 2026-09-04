import 'dart:typed_data';
import '../../../core/constants/paper_presets.dart';
import '../../../core/models/paper_preset.dart';
import '../../../services/document/models/printable_document.dart';
import 'document_paper_type.dart';

enum ColorMode {
  blackAndWhite('Black & White'),
  color('Color');

  final String displayName;
  const ColorMode(this.displayName);
}

enum PageRangeMode {
  all('All Pages'),
  current('Current Page'),
  custom('Custom Range');

  final String displayName;
  const PageRangeMode(this.displayName);
}

enum DuplexMode {
  singleSided('Single Sided'),
  doubleSidedLongEdge('Double Sided (Long Edge)'),
  doubleSidedShortEdge('Double Sided (Short Edge)');

  final String displayName;
  const DuplexMode(this.displayName);
}

enum PageScaling {
  fitToPage('Fit to Page'),
  actualSize('Actual Size / 100%'),
  fillPage('Fill Page'),
  custom('Custom %');

  final String displayName;
  const PageScaling(this.displayName);
}

class DocumentStateSnapshot {
  final int activePageIndex;
  final int rotationAngle;
  final int copies;
  final ColorMode colorMode;
  final PageRangeMode pageRangeMode;
  final String customRangeText;
  final Set<int> selectedPageIndices;
  final DuplexMode printSides;
  final bool collateCopies;
  final bool reverseOrder;
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final PageScaling scaling;
  final double customScalePercent;
  final bool autoRotatePages;
  final int pagesPerSheet;
  final double marginMm;
  final double spacingMm;
  final bool centerPages;
  final bool borderAroundPages;
  final DocumentPaperType paperType;
  final DocumentBindingType bindingType;

  const DocumentStateSnapshot({
    required this.activePageIndex,
    required this.rotationAngle,
    required this.copies,
    required this.colorMode,
    required this.pageRangeMode,
    required this.customRangeText,
    required this.selectedPageIndices,
    required this.printSides,
    required this.collateCopies,
    required this.reverseOrder,
    required this.paperPreset,
    required this.orientation,
    required this.scaling,
    required this.customScalePercent,
    required this.autoRotatePages,
    required this.pagesPerSheet,
    required this.marginMm,
    required this.spacingMm,
    required this.centerPages,
    required this.borderAroundPages,
    required this.paperType,
    required this.bindingType,
  });
}

class DocumentPrintState {
  final Uint8List? rawBytes;
  final String? fileName;
  final String? fileType;
  final int fileSize;
  final List<Uint8List> renderedPages;
  final int activePageIndex;
  final int rotationAngle; // 0, 90, 180, 270

  // Normalized Printable Document
  final PrintableDocument? printableDocument;
  final DocumentRenderStatus renderStatus;
  final String? statusMessage;

  // Section 2: Print Options
  final int copies;
  final ColorMode colorMode;
  final PageRangeMode pageRangeMode;
  final String customRangeText;
  final Set<int> selectedPageIndices;
  final DuplexMode printSides;
  final bool collateCopies;
  final bool reverseOrder;

  // Section 3: Paper & Layout
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final PageScaling scaling;
  final double customScalePercent;
  final bool autoRotatePages;
  final int pagesPerSheet; // 1, 2, 4, 6
  final double marginMm;
  final double spacingMm;
  final bool centerPages;
  final bool borderAroundPages;

  // Zoom & UI state
  final double zoomScale;
  final bool isProcessing;
  final String? errorMessage;

  // Password protected PDF
  final bool isPasswordRequired;
  final Uint8List? pendingEncryptedPdfBytes;
  final String? pendingEncryptedFileName;
  final String? passwordError;

  // Paper GSM & Finishing Options
  final DocumentPaperType paperType;
  final DocumentBindingType bindingType;

  // Undo / Redo Stacks
  final List<DocumentStateSnapshot> undoStack;
  final List<DocumentStateSnapshot> redoStack;

  const DocumentPrintState({
    this.rawBytes,
    this.fileName,
    this.fileType,
    this.fileSize = 0,
    this.renderedPages = const [],
    this.activePageIndex = 0,
    this.rotationAngle = 0,
    this.printableDocument,
    this.renderStatus = DocumentRenderStatus.idle,
    this.statusMessage,
    this.copies = 1,
    this.colorMode = ColorMode.blackAndWhite,
    this.pageRangeMode = PageRangeMode.all,
    this.customRangeText = '',
    this.selectedPageIndices = const {},
    this.printSides = DuplexMode.singleSided,
    this.collateCopies = true,
    this.reverseOrder = false,
    this.paperPreset = StandardPaperPresets.a4,
    this.orientation = PaperOrientation.portrait,
    this.scaling = PageScaling.fitToPage,
    this.customScalePercent = 100.0,
    this.autoRotatePages = true,
    this.pagesPerSheet = 1,
    this.marginMm = 5.0,
    this.spacingMm = 4.0,
    this.centerPages = true,
    this.borderAroundPages = false,
    this.zoomScale = 1.0,
    this.isProcessing = false,
    this.errorMessage,
    this.isPasswordRequired = false,
    this.pendingEncryptedPdfBytes,
    this.pendingEncryptedFileName,
    this.passwordError,
    this.paperType = DocumentPaperType.normal70Gsm,
    this.bindingType = DocumentBindingType.none,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  bool get hasDocument =>
      (printableDocument?.isReady ?? false) ||
      renderedPages.isNotEmpty ||
      (rawBytes != null && rawBytes!.isNotEmpty);

  int get totalPages => printableDocument?.pageCount ?? renderedPages.length;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  DocumentStateSnapshot createSnapshot() {
    return DocumentStateSnapshot(
      activePageIndex: activePageIndex,
      rotationAngle: rotationAngle,
      copies: copies,
      colorMode: colorMode,
      pageRangeMode: pageRangeMode,
      customRangeText: customRangeText,
      selectedPageIndices: Set.from(selectedPageIndices),
      printSides: printSides,
      collateCopies: collateCopies,
      reverseOrder: reverseOrder,
      paperPreset: paperPreset,
      orientation: orientation,
      scaling: scaling,
      customScalePercent: customScalePercent,
      autoRotatePages: autoRotatePages,
      pagesPerSheet: pagesPerSheet,
      marginMm: marginMm,
      spacingMm: spacingMm,
      centerPages: centerPages,
      borderAroundPages: borderAroundPages,
      paperType: paperType,
      bindingType: bindingType,
    );
  }

  int get pagesToPrint => selectedPageIndices.isEmpty ? totalPages : selectedPageIndices.length;

  double get ratePerPage => colorMode == ColorMode.color ? paperType.colorRatePerPage : paperType.bwRatePerPage;

  double get calculatedSellingPrice =>
      (ratePerPage * pagesToPrint * copies) + (bindingType.price * copies);

  double get calculatedMaterialCost {
    final paperCost = paperType.sheetCost * totalSheetsToPrint;
    final bindingCost = (bindingType == DocumentBindingType.spiralBinding ? 10.0 : (bindingType == DocumentBindingType.hardBinding ? 40.0 : (bindingType == DocumentBindingType.cornerStaple ? 0.20 : 0.0))) * copies;
    return paperCost + bindingCost;
  }

  double get calculatedInkCost =>
      (colorMode == ColorMode.color ? 1.80 : 0.40) * pagesToPrint * copies;

  double get calculatedProfit => calculatedSellingPrice - calculatedMaterialCost - calculatedInkCost;

  Uint8List? get activePageImageBytes {
    if (printableDocument != null && printableDocument!.pages.isNotEmpty) {
      final page = printableDocument!.getPage(activePageIndex);
      if (page != null) return page.imageBytes;
    }
    if (renderedPages.isNotEmpty && activePageIndex < renderedPages.length) {
      return renderedPages[activePageIndex];
    }
    return null;
  }

  int get totalSheetsToPrint {
    final pageCount = selectedPageIndices.isEmpty ? totalPages : selectedPageIndices.length;
    final perSheet = pagesPerSheet > 0 ? pagesPerSheet : 1;
    int sheetsPerCopy = (pageCount / perSheet).ceil();
    if (printSides != DuplexMode.singleSided) {
      sheetsPerCopy = (sheetsPerCopy / 2).ceil();
    }
    return sheetsPerCopy * copies;
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DocumentPrintState copyWith({
    Uint8List? rawBytes,
    String? fileName,
    String? fileType,
    int? fileSize,
    List<Uint8List>? renderedPages,
    int? activePageIndex,
    int? rotationAngle,
    PrintableDocument? printableDocument,
    DocumentRenderStatus? renderStatus,
    String? statusMessage,
    bool clearStatusMessage = false,
    int? copies,
    ColorMode? colorMode,
    PageRangeMode? pageRangeMode,
    String? customRangeText,
    Set<int>? selectedPageIndices,
    DuplexMode? printSides,
    bool? collateCopies,
    bool? reverseOrder,
    PaperPreset? paperPreset,
    PaperOrientation? orientation,
    PageScaling? scaling,
    double? customScalePercent,
    bool? autoRotatePages,
    int? pagesPerSheet,
    double? marginMm,
    double? spacingMm,
    bool? centerPages,
    bool? borderAroundPages,
    double? zoomScale,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
    bool? isPasswordRequired,
    Uint8List? pendingEncryptedPdfBytes,
    bool clearPendingEncryptedBytes = false,
    String? pendingEncryptedFileName,
    String? passwordError,
    bool clearPasswordError = false,
    DocumentPaperType? paperType,
    DocumentBindingType? bindingType,
    List<DocumentStateSnapshot>? undoStack,
    List<DocumentStateSnapshot>? redoStack,
  }) {
    return DocumentPrintState(
      rawBytes: rawBytes ?? this.rawBytes,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      renderedPages: renderedPages ?? this.renderedPages,
      activePageIndex: activePageIndex ?? this.activePageIndex,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      printableDocument: printableDocument ?? this.printableDocument,
      renderStatus: renderStatus ?? this.renderStatus,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      copies: copies ?? this.copies,
      colorMode: colorMode ?? this.colorMode,
      pageRangeMode: pageRangeMode ?? this.pageRangeMode,
      customRangeText: customRangeText ?? this.customRangeText,
      selectedPageIndices: selectedPageIndices ?? this.selectedPageIndices,
      printSides: printSides ?? this.printSides,
      collateCopies: collateCopies ?? this.collateCopies,
      reverseOrder: reverseOrder ?? this.reverseOrder,
      paperPreset: paperPreset ?? this.paperPreset,
      orientation: orientation ?? this.orientation,
      scaling: scaling ?? this.scaling,
      customScalePercent: customScalePercent ?? this.customScalePercent,
      autoRotatePages: autoRotatePages ?? this.autoRotatePages,
      pagesPerSheet: pagesPerSheet ?? this.pagesPerSheet,
      marginMm: marginMm ?? this.marginMm,
      spacingMm: spacingMm ?? this.spacingMm,
      centerPages: centerPages ?? this.centerPages,
      borderAroundPages: borderAroundPages ?? this.borderAroundPages,
      zoomScale: zoomScale ?? this.zoomScale,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPasswordRequired: isPasswordRequired ?? this.isPasswordRequired,
      pendingEncryptedPdfBytes: clearPendingEncryptedBytes ? null : (pendingEncryptedPdfBytes ?? this.pendingEncryptedPdfBytes),
      pendingEncryptedFileName: pendingEncryptedFileName ?? this.pendingEncryptedFileName,
      passwordError: clearPasswordError ? null : (passwordError ?? this.passwordError),
      paperType: paperType ?? this.paperType,
      bindingType: bindingType ?? this.bindingType,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}
