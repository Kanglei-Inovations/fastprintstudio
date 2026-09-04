import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/paper_presets.dart';
import '../../../core/models/paper_preset.dart';
import '../../../core/models/print_history_item.dart';
import '../../../providers/app_providers.dart';
import '../../../services/document/document_conversion_service.dart';
import '../../../services/document/models/printable_document.dart';
import '../../../services/pdf/pdf_inspector.dart';
import '../../../services/pdf/pdf_rasterizer.dart';
import '../../../services/project/fps_project_service.dart';
import '../../../services/storage/draft_storage_service.dart';
import '../../../services/storage/recent_projects_service.dart';
import '../models/document_paper_type.dart';
import '../models/document_print_state.dart';

class DocumentNotifier extends StateNotifier<DocumentPrintState> {
  final Ref _ref;
  static const _uuid = Uuid();

  DocumentNotifier(this._ref) : super(const DocumentPrintState());

  void _pushUndoState() {
    final currentSnapshot = state.createSnapshot();
    final newUndo = [currentSnapshot, ...state.undoStack];
    if (newUndo.length > 30) {
      newUndo.removeLast();
    }
    state = state.copyWith(
      undoStack: newUndo,
      redoStack: const [],
    );
  }

  void undo() {
    if (!state.canUndo) return;
    final currentSnapshot = state.createSnapshot();
    final previous = state.undoStack.first;
    final newUndo = state.undoStack.sublist(1);

    _applySnapshot(previous);
    state = state.copyWith(
      undoStack: newUndo,
      redoStack: [currentSnapshot, ...state.redoStack],
    );
    saveDraft();
  }

  void redo() {
    if (!state.canRedo) return;
    final currentSnapshot = state.createSnapshot();
    final next = state.redoStack.first;
    final newRedo = state.redoStack.sublist(1);

    _applySnapshot(next);
    state = state.copyWith(
      undoStack: [currentSnapshot, ...state.undoStack],
      redoStack: newRedo,
    );
    saveDraft();
  }

  void _applySnapshot(DocumentStateSnapshot snap) {
    state = state.copyWith(
      activePageIndex: snap.activePageIndex,
      rotationAngle: snap.rotationAngle,
      copies: snap.copies,
      colorMode: snap.colorMode,
      pageRangeMode: snap.pageRangeMode,
      customRangeText: snap.customRangeText,
      selectedPageIndices: snap.selectedPageIndices,
      printSides: snap.printSides,
      collateCopies: snap.collateCopies,
      reverseOrder: snap.reverseOrder,
      paperPreset: snap.paperPreset,
      orientation: snap.orientation,
      scaling: snap.scaling,
      customScalePercent: snap.customScalePercent,
      autoRotatePages: snap.autoRotatePages,
      pagesPerSheet: snap.pagesPerSheet,
      marginMm: snap.marginMm,
      spacingMm: snap.spacingMm,
      centerPages: snap.centerPages,
      borderAroundPages: snap.borderAroundPages,
      paperType: snap.paperType,
      bindingType: snap.bindingType,
    );
  }

  /// Saves project state into local draft storage so work continues even after PC shutdown
  Future<void> saveDraft() async {
    final raw = state.rawBytes;
    final fName = state.fileName;
    if (raw == null || fName == null) return;

    final metadata = {
      'activePageIndex': state.activePageIndex,
      'rotationAngle': state.rotationAngle,
      'copies': state.copies,
      'colorMode': state.colorMode.name,
      'pageRangeMode': state.pageRangeMode.name,
      'customRangeText': state.customRangeText,
      'selectedPageIndices': state.selectedPageIndices.toList(),
      'printSides': state.printSides.name,
      'collateCopies': state.collateCopies,
      'reverseOrder': state.reverseOrder,
      'paperPresetName': state.paperPreset.name,
      'orientation': state.orientation.name,
      'scaling': state.scaling.name,
      'customScalePercent': state.customScalePercent,
      'autoRotatePages': state.autoRotatePages,
      'pagesPerSheet': state.pagesPerSheet,
      'marginMm': state.marginMm,
      'spacingMm': state.spacingMm,
      'centerPages': state.centerPages,
      'borderAroundPages': state.borderAroundPages,
      'paperTypeName': state.paperType.name,
      'bindingTypeName': state.bindingType.name,
    };

    await DraftStorageService.saveDocumentDraft(
      bytes: raw,
      fileName: fName,
      metadata: metadata,
    );
  }

  /// Restores complete document project from saved draft or .fps file cleanly
  Future<void> restoreProjectFromData({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    await loadDocument(bytes: bytes, fileName: fileName, isRestoringDraft: true);

    try {
      PaperPreset preset = state.paperPreset;
      final pName = metadata['paperPresetName'] as String?;
      if (pName != null) {
        final found = StandardPaperPresets.all.where((p) => p.name == pName).firstOrNull;
        if (found != null) preset = found;
      }

      DocumentPaperType paperType = state.paperType;
      final ptName = metadata['paperTypeName'] as String?;
      if (ptName != null) {
        final found = DocumentPaperType.values.where((p) => p.name == ptName).firstOrNull;
        if (found != null) paperType = found;
      }

      DocumentBindingType bindingType = state.bindingType;
      final btName = metadata['bindingTypeName'] as String?;
      if (btName != null) {
        final found = DocumentBindingType.values.where((b) => b.name == btName).firstOrNull;
        if (found != null) bindingType = found;
      }

      final copies = metadata['copies'] as int? ?? state.copies;
      final customScale = (metadata['customScalePercent'] as num?)?.toDouble() ?? state.customScalePercent;
      final rotation = metadata['rotationAngle'] as int? ?? state.rotationAngle;
      final margin = (metadata['marginMm'] as num?)?.toDouble() ?? state.marginMm;
      final spacing = (metadata['spacingMm'] as num?)?.toDouble() ?? state.spacingMm;
      final nUp = metadata['pagesPerSheet'] as int? ?? state.pagesPerSheet;

      ColorMode colorMode = state.colorMode;
      if (metadata['colorMode'] == 'color') colorMode = ColorMode.color;
      if (metadata['colorMode'] == 'blackAndWhite') colorMode = ColorMode.blackAndWhite;

      PaperOrientation orientation = state.orientation;
      if (metadata['orientation'] == 'landscape') orientation = PaperOrientation.landscape;
      if (metadata['orientation'] == 'portrait') orientation = PaperOrientation.portrait;

      PageScaling scaling = state.scaling;
      if (metadata['scaling'] != null) {
        final found = PageScaling.values.where((s) => s.name == metadata['scaling']).firstOrNull;
        if (found != null) scaling = found;
      }

      state = state.copyWith(
        copies: copies,
        colorMode: colorMode,
        paperPreset: preset,
        orientation: orientation,
        scaling: scaling,
        customScalePercent: customScale,
        rotationAngle: rotation,
        marginMm: margin,
        spacingMm: spacing,
        pagesPerSheet: nUp,
        paperType: paperType,
        bindingType: bindingType,
      );
    } catch (e) {
      debugPrint('Error applying restored draft metadata: $e');
    }
  }

  /// Automatically restores last active document project draft when app starts
  Future<void> restoreDraftIfExists() async {
    final draft = await DraftStorageService.loadDocumentDraft();
    if (draft == null) return;

    final bytes = draft['bytes'] as Uint8List?;
    final fName = draft['fileName'] as String?;
    final meta = draft['metadata'] as Map<String, dynamic>? ?? {};

    if (bytes != null && bytes.isNotEmpty && fName != null) {
      debugPrint('Auto-restoring last document print project draft: $fName');
      await restoreProjectFromData(bytes: bytes, fileName: fName, metadata: meta);
    }
  }

  /// Loads PDF, Word (.doc, .docx), Excel (.xls, .xlsx), PowerPoint (.ppt, .pptx), or Image documents
  /// using the multi-format DocumentConversionService pipeline.
  Future<void> loadDocument({
    required Uint8List bytes,
    required String fileName,
    bool isRestoringDraft = false,
  }) async {
    state = state.copyWith(
      rawBytes: bytes,
      fileName: fileName,
      fileSize: bytes.length,
      renderStatus: DocumentRenderStatus.preparing,
      statusMessage: 'Preparing document preview…',
      isProcessing: true,
      isPasswordRequired: false,
      clearPendingEncryptedBytes: true,
      clearError: true,
      clearPasswordError: true,
    );

    try {
      final printableDoc = await DocumentConversionService.convertAndRender(
        bytes: bytes,
        fileName: fileName,
        dpi: 300,
      );

      if (printableDoc.hasError) {
        if (printableDoc.conversionError == 'PASSWORD_PROTECTED') {
          state = state.copyWith(
            isPasswordRequired: true,
            pendingEncryptedPdfBytes: bytes,
            pendingEncryptedFileName: fileName,
            isProcessing: false,
            clearError: true,
            clearPasswordError: true,
          );
          return;
        }

        state = state.copyWith(
          printableDocument: printableDoc,
          renderStatus: DocumentRenderStatus.error,
          errorMessage: printableDoc.conversionError ?? 'Unable to preview document.',
          isProcessing: false,
        );
        return;
      }

      final pagesList = printableDoc.pages.map((p) => p.imageBytes).toList();
      final allIndices = List.generate(pagesList.length, (i) => i).toSet();

      state = state.copyWith(
        printableDocument: printableDoc,
        renderedPages: pagesList,
        activePageIndex: 0,
        selectedPageIndices: allIndices,
        pageRangeMode: PageRangeMode.all,
        customRangeText: '1-${pagesList.length}',
        fileType: printableDoc.sourceType.displayName,
        orientation: printableDoc.orientation,
        renderStatus: DocumentRenderStatus.ready,
        statusMessage: 'Document ready — ${pagesList.length} ${pagesList.length == 1 ? "page" : "pages"}',
        isProcessing: false,
        clearError: true,
      );

      // Auto-save draft so state is preserved across PC shutdown
      if (!isRestoringDraft) {
        await saveDraft();
      }
    } catch (e) {
      debugPrint('Error loading document: $e');
      if (e is PdfPasswordException) {
        state = state.copyWith(
          isPasswordRequired: true,
          pendingEncryptedPdfBytes: bytes,
          pendingEncryptedFileName: fileName,
          isProcessing: false,
        );
      } else {
        state = state.copyWith(
          renderStatus: DocumentRenderStatus.error,
          isProcessing: false,
          errorMessage: e is PdfMalformedException ? e.message : 'Failed to process document: $e',
        );
      }
    }
  }

  /// Retries loading and converting the current document
  Future<void> retryConversion() async {
    final raw = state.rawBytes;
    final fName = state.fileName;
    if (raw != null && fName != null) {
      await loadDocument(bytes: raw, fileName: fName);
    }
  }

  /// Unlocks password-protected PDF and loads it
  Future<bool> unlockPasswordProtectedPdf(String password) async {
    final pendingBytes = state.pendingEncryptedPdfBytes;
    final fName = state.pendingEncryptedFileName ?? 'document.pdf';
    if (pendingBytes == null) return false;

    state = state.copyWith(isProcessing: true, clearPasswordError: true);

    final unlockResult = await PdfInspector.unlockPdf(
      pdfBytes: pendingBytes,
      password: password,
    );

    if (unlockResult.success && unlockResult.decryptedBytes != null) {
      final decrypted = unlockResult.decryptedBytes!;

      state = state.copyWith(
        isPasswordRequired: false,
        clearPendingEncryptedBytes: true,
        clearPasswordError: true,
      );

      await loadDocument(bytes: decrypted, fileName: fName);
      return true;
    } else {
      state = state.copyWith(
        isProcessing: false,
        passwordError: unlockResult.errorMessage ?? 'Incorrect PDF password. Please try again.',
      );
      return false;
    }
  }

  void cancelPasswordPrompt() {
    state = state.copyWith(
      isPasswordRequired: false,
      clearPendingEncryptedBytes: true,
      clearPasswordError: true,
    );
  }

  // --- Page Navigation & Rotation ---
  void setActivePage(int index) {
    if (index >= 0 && index < state.totalPages) {
      state = state.copyWith(activePageIndex: index);
    }
  }

  void nextPage() {
    if (state.activePageIndex < state.totalPages - 1) {
      state = state.copyWith(activePageIndex: state.activePageIndex + 1);
    }
  }

  void previousPage() {
    if (state.activePageIndex > 0) {
      state = state.copyWith(activePageIndex: state.activePageIndex - 1);
    }
  }

  void firstPage() {
    state = state.copyWith(activePageIndex: 0);
  }

  void lastPage() {
    if (state.totalPages > 0) {
      state = state.copyWith(activePageIndex: state.totalPages - 1);
    }
  }

  void rotateLeft() {
    _pushUndoState();
    state = state.copyWith(rotationAngle: (state.rotationAngle - 90 + 360) % 360);
    saveDraft();
  }

  void rotateRight() {
    _pushUndoState();
    state = state.copyWith(rotationAngle: (state.rotationAngle + 90) % 360);
    saveDraft();
  }

  // --- Section 2: Print Options ---
  void setCopies(int copies) {
    _pushUndoState();
    state = state.copyWith(copies: copies.clamp(1, 999));
    saveDraft();
  }

  void setColorMode(ColorMode mode) {
    _pushUndoState();
    state = state.copyWith(colorMode: mode);
    saveDraft();
  }

  void setPrintSides(DuplexMode mode) {
    _pushUndoState();
    state = state.copyWith(printSides: mode);
    saveDraft();
  }

  void setCollateCopies(bool collate) {
    _pushUndoState();
    state = state.copyWith(collateCopies: collate);
    saveDraft();
  }

  void setReverseOrder(bool reverse) {
    _pushUndoState();
    state = state.copyWith(reverseOrder: reverse);
    saveDraft();
  }

  void setPageRangeMode(PageRangeMode mode) {
    _pushUndoState();
    if (mode == PageRangeMode.all) {
      final allIndices = List.generate(state.totalPages, (i) => i).toSet();
      state = state.copyWith(
        pageRangeMode: mode,
        selectedPageIndices: allIndices,
        customRangeText: '1-${state.totalPages}',
      );
    } else if (mode == PageRangeMode.current) {
      state = state.copyWith(
        pageRangeMode: mode,
        selectedPageIndices: {state.activePageIndex},
      );
    } else {
      state = state.copyWith(pageRangeMode: mode);
      _parseCustomRange(state.customRangeText);
    }
    saveDraft();
  }

  void setCustomRangeText(String text) {
    _pushUndoState();
    state = state.copyWith(
      customRangeText: text,
      pageRangeMode: PageRangeMode.custom,
    );
    _parseCustomRange(text);
    saveDraft();
  }

  void _parseCustomRange(String input) {
    if (input.trim().isEmpty) {
      state = state.copyWith(selectedPageIndices: {});
      return;
    }

    final selected = <int>{};
    final parts = input.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final subParts = trimmed.split('-');
        if (subParts.length == 2) {
          final start = int.tryParse(subParts[0].trim());
          final end = int.tryParse(subParts[1].trim());
          if (start != null && end != null && start <= end) {
            for (int p = start; p <= end; p++) {
              final idx = p - 1;
              if (idx >= 0 && idx < state.totalPages) {
                selected.add(idx);
              }
            }
          }
        }
      } else {
        final pageNum = int.tryParse(trimmed);
        if (pageNum != null) {
          final idx = pageNum - 1;
          if (idx >= 0 && idx < state.totalPages) {
            selected.add(idx);
          }
        }
      }
    }

    state = state.copyWith(selectedPageIndices: selected);
  }

  void selectAllPages() {
    _pushUndoState();
    final all = List.generate(state.totalPages, (i) => i).toSet();
    state = state.copyWith(
      pageRangeMode: PageRangeMode.all,
      selectedPageIndices: all,
      customRangeText: '1-${state.totalPages}',
    );
    saveDraft();
  }

  void clearPageSelection() {
    _pushUndoState();
    state = state.copyWith(
      selectedPageIndices: {},
      pageRangeMode: PageRangeMode.custom,
      customRangeText: '',
    );
    saveDraft();
  }

  void selectOddPages() {
    _pushUndoState();
    final odds = <int>{};
    for (int i = 0; i < state.totalPages; i++) {
      if ((i + 1) % 2 != 0) odds.add(i);
    }
    state = state.copyWith(
      selectedPageIndices: odds,
      pageRangeMode: PageRangeMode.custom,
      customRangeText: odds.map((i) => (i + 1).toString()).join(', '),
    );
    saveDraft();
  }

  void selectEvenPages() {
    _pushUndoState();
    final evens = <int>{};
    for (int i = 0; i < state.totalPages; i++) {
      if ((i + 1) % 2 == 0) evens.add(i);
    }
    state = state.copyWith(
      selectedPageIndices: evens,
      pageRangeMode: PageRangeMode.custom,
      customRangeText: evens.map((i) => (i + 1).toString()).join(', '),
    );
    saveDraft();
  }

  // --- Section 3: Paper & Layout ---
  void setPaperPreset(PaperPreset preset) {
    _pushUndoState();
    state = state.copyWith(paperPreset: preset);
    saveDraft();
  }

  void setOrientation(PaperOrientation orientation) {
    _pushUndoState();
    state = state.copyWith(orientation: orientation);
    saveDraft();
  }

  void setScaling(PageScaling scaling) {
    _pushUndoState();
    state = state.copyWith(scaling: scaling);
    saveDraft();
  }

  void setCustomScalePercent(double percent) {
    _pushUndoState();
    state = state.copyWith(
      customScalePercent: percent.clamp(10.0, 500.0),
      scaling: PageScaling.custom,
    );
    saveDraft();
  }

  void setAutoRotatePages(bool autoRotate) {
    _pushUndoState();
    state = state.copyWith(autoRotatePages: autoRotate);
    saveDraft();
  }

  void setPagesPerSheet(int nUp) {
    _pushUndoState();
    state = state.copyWith(pagesPerSheet: nUp);
    saveDraft();
  }

  void setMarginMm(double mm) {
    _pushUndoState();
    state = state.copyWith(marginMm: mm.clamp(0.0, 50.0));
    saveDraft();
  }

  void setSpacingMm(double mm) {
    _pushUndoState();
    state = state.copyWith(spacingMm: mm.clamp(0.0, 50.0));
    saveDraft();
  }

  void setCenterPages(bool center) {
    _pushUndoState();
    state = state.copyWith(centerPages: center);
    saveDraft();
  }

  void setBorderAroundPages(bool border) {
    _pushUndoState();
    state = state.copyWith(borderAroundPages: border);
    saveDraft();
  }

  void setPaperType(DocumentPaperType paperType) {
    _pushUndoState();
    state = state.copyWith(paperType: paperType);
    saveDraft();
  }

  void setBindingType(DocumentBindingType bindingType) {
    _pushUndoState();
    state = state.copyWith(bindingType: bindingType);
    saveDraft();
  }

  // --- Zoom Controls ---
  void setZoomScale(double scale) {
    state = state.copyWith(zoomScale: scale.clamp(0.2, 4.0));
  }

  void zoomIn() {
    state = state.copyWith(zoomScale: (state.zoomScale + 0.15).clamp(0.2, 4.0));
  }

  void zoomOut() {
    state = state.copyWith(zoomScale: (state.zoomScale - 0.15).clamp(0.2, 4.0));
  }

  void resetZoom() {
    state = state.copyWith(zoomScale: 1.0);
  }

  // --- Printing & Export ---
  /// Compiles a print-ready PDF containing the selected pages formatted with paper, scaling, and color mode
  Future<Uint8List> generatePrintablePdf() async {
    final pdf = pw.Document();

    final paperFormat = PdfPageFormat(
      state.paperPreset.widthPt(state.orientation),
      state.paperPreset.heightPt(state.orientation),
      marginLeft: state.marginMm * 2.83465,
      marginRight: state.marginMm * 2.83465,
      marginTop: state.marginMm * 2.83465,
      marginBottom: state.marginMm * 2.83465,
    );

    // Determine page indices to print
    List<int> pagesToPrint = state.selectedPageIndices.toList()..sort();
    if (pagesToPrint.isEmpty) {
      pagesToPrint = List.generate(state.totalPages, (i) => i);
    }
    if (state.reverseOrder) {
      pagesToPrint = pagesToPrint.reversed.toList();
    }

    final nUp = state.pagesPerSheet;
    final pagesList = state.printableDocument?.pages.map((p) => p.imageBytes).toList() ?? state.renderedPages;

    if (nUp == 1) {
      for (final pIdx in pagesToPrint) {
        if (pIdx >= pagesList.length) continue;
        final rawPageBytes = pagesList[pIdx];
        final processedBytes = _applyColorAndRotation(rawPageBytes);
        final pdfImage = pw.MemoryImage(processedBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: paperFormat,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pdfImage,
                  fit: state.scaling == PageScaling.fillPage
                      ? pw.BoxFit.fill
                      : (state.scaling == PageScaling.actualSize ? pw.BoxFit.none : pw.BoxFit.contain),
                ),
              );
            },
          ),
        );
      }
    } else {
      // Multi-page N-up layout (e.g. 2, 4, 6 pages per sheet)
      for (int i = 0; i < pagesToPrint.length; i += nUp) {
        final chunk = pagesToPrint.sublist(i, min(i + nUp, pagesToPrint.length));
        final chunkImages = <pw.MemoryImage>[];

        for (final pIdx in chunk) {
          if (pIdx < pagesList.length) {
            final processed = _applyColorAndRotation(pagesList[pIdx]);
            chunkImages.add(pw.MemoryImage(processed));
          }
        }

        pdf.addPage(
          pw.Page(
            pageFormat: paperFormat,
            build: (pw.Context context) {
              return pw.GridView(
                crossAxisCount: nUp == 2 ? 1 : 2,
                childAspectRatio: 1.4,
                children: chunkImages.map((img) {
                  return pw.Container(
                    margin: pw.EdgeInsets.all(state.spacingMm * 1.5),
                    decoration: state.borderAroundPages
                        ? pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5))
                        : null,
                    child: pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
                  );
                }).toList(),
              );
            },
          ),
        );
      }
    }

    return await pdf.save();
  }

  Uint8List _applyColorAndRotation(Uint8List imageBytes) {
    if (state.colorMode == ColorMode.color && state.rotationAngle == 0) {
      return imageBytes;
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    img.Image modified = decoded;

    // Apply rotation
    if (state.rotationAngle != 0) {
      modified = img.copyRotate(modified, angle: state.rotationAngle);
    }

    // Apply Black & White grayscale
    if (state.colorMode == ColorMode.blackAndWhite) {
      modified = img.grayscale(modified);
    }

    return Uint8List.fromList(img.encodePng(modified));
  }

  /// Sends document to printer service — ONLY physical prints are recorded to history!
  Future<bool> printDocument({Printer? targetPrinter}) async {
    if (!state.hasDocument) return false;

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final pdfBytes = await generatePrintablePdf();
      final printerService = _ref.read(printerServiceProvider);
      final jobName = '${state.fileName ?? "Document"} - ${state.colorMode.displayName}';

      final success = await printerService.directPrintPdf(
        pdfBytes,
        printer: targetPrinter,
        jobName: jobName,
      );

      // Record to history ONLY on actual print
      await _ref.read(historyProvider.notifier).addRecord(
            PrintHistoryItem(
              id: _uuid.v4(),
              timestamp: DateTime.now(),
              serviceName: state.colorMode == ColorMode.color ? 'Document Print (Color)' : 'Document Print (B&W)',
              paperName: '${state.paperPreset.name} (${state.paperType.name})',
              copiesCount: state.totalSheetsToPrint,
              printerName: targetPrinter?.name ?? 'System Print Dialog',
              status: success ? 'Printed' : 'Print Submitted',
              dimensionsSummary: '${state.paperPreset.name} (${state.pagesToPrint} pgs × ${state.copies} copies)',
              sellingPrice: state.calculatedSellingPrice,
              materialCost: state.calculatedMaterialCost,
              inkCost: state.calculatedInkCost,
              profit: state.calculatedProfit,
              paymentStatus: 'Paid',
              paymentMethod: 'Cash',
            ),
          );

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('Error printing document: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Print failed: $e');
      return false;
    }
  }

  /// Prints only the current active preview page
  Future<bool> printCurrentPage({Printer? targetPrinter}) async {
    final originalSelection = state.selectedPageIndices;
    final originalMode = state.pageRangeMode;

    state = state.copyWith(
      pageRangeMode: PageRangeMode.current,
      selectedPageIndices: {state.activePageIndex},
    );

    final success = await printDocument(targetPrinter: targetPrinter);

    state = state.copyWith(
      pageRangeMode: originalMode,
      selectedPageIndices: originalSelection,
    );

    return success;
  }

  /// Exports printable PDF file — Does NOT record to history!
  Future<bool> exportPdf() async {
    if (!state.hasDocument) return false;

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      Uint8List pdfBytes;
      final isDefaultFullDocument = state.pagesPerSheet == 1 &&
          state.colorMode == ColorMode.color &&
          state.rotationAngle == 0 &&
          state.marginMm == 0 &&
          (state.selectedPageIndices.length == state.totalPages || state.selectedPageIndices.isEmpty) &&
          !state.reverseOrder;

      if (isDefaultFullDocument && state.printableDocument?.convertedPdfBytes != null) {
        pdfBytes = state.printableDocument!.convertedPdfBytes!;
      } else {
        pdfBytes = await generatePrintablePdf();
      }

      final baseName = state.fileName?.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '') ?? 'Document';
      final fileName = '${baseName}_Exported.pdf';

      final success = await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      state = state.copyWith(isProcessing: false);
      return success;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Export failed: $e');
      return false;
    }
  }

  /// Saves current document project as a standalone .fps project file
  Future<String?> saveProjectAsFps() async {
    final raw = state.rawBytes;
    final fName = state.fileName;
    if (raw == null || fName == null || raw.isEmpty) return null;

    final metadata = {
      'copies': state.copies,
      'colorMode': state.colorMode.name,
      'pageRangeMode': state.pageRangeMode.name,
      'customRangeText': state.customRangeText,
      'rotationAngle': state.rotationAngle,
      'printSides': state.printSides.name,
      'collateCopies': state.collateCopies,
      'reverseOrder': state.reverseOrder,
      'paperPresetName': state.paperPreset.name,
      'orientation': state.orientation.name,
      'scaling': state.scaling.name,
      'customScalePercent': state.customScalePercent,
      'autoRotatePages': state.autoRotatePages,
      'pagesPerSheet': state.pagesPerSheet,
      'marginMm': state.marginMm,
      'spacingMm': state.spacingMm,
      'centerPages': state.centerPages,
      'borderAroundPages': state.borderAroundPages,
      'paperTypeName': state.paperType.name,
      'bindingTypeName': state.bindingType.name,
      'totalPages': state.totalPages,
    };

    final thumb = state.renderedPages.isNotEmpty ? state.renderedPages.first : null;
    final path = await FpsProjectService.saveProjectAsFps(
      projectType: 'document',
      rawBytes: raw,
      fileName: fName,
      metadata: metadata,
      thumbnailBytes: thumb,
    );

    if (path != null) {
      await saveDraft();
    }
    return path;
  }

  /// Opens and loads a .fps project file from file path or file dialog
  Future<bool> loadProjectFromFps({String? filePath}) async {
    Map<String, dynamic>? data;
    if (filePath != null) {
      data = await FpsProjectService.loadFpsFromFile(filePath);
    } else {
      data = await FpsProjectService.pickAndLoadFpsFile(title: 'Open Document Project');
    }

    if (data == null) return false;

    final bytes = data['bytes'] as Uint8List?;
    final fName = data['fileName'] as String?;
    final meta = data['metadata'] as Map<String, dynamic>? ?? {};

    if (bytes == null || bytes.isEmpty || fName == null) return false;

    await restoreProjectFromData(bytes: bytes, fileName: fName, metadata: meta);
    await saveDraft();
    return true;
  }

  /// Closes current active document project, saves to Recent Projects, and resets workspace
  Future<void> closeCurrentProject() async {
    if (state.hasDocument) {
      try {
        final raw = state.rawBytes!;
        final fName = state.fileName ?? 'Untitled Document';
        final thumb = state.renderedPages.isNotEmpty ? state.renderedPages.first : null;
        final totalP = state.totalPages;
        final colorName = state.colorMode == ColorMode.color ? 'Color' : 'B&W';
        final modeLabel = totalP > 0 ? '$colorName • $totalP Page${totalP > 1 ? "s" : ""}' : colorName;

        final metadata = {
          'copies': state.copies,
          'colorMode': state.colorMode.name,
          'pageRangeMode': state.pageRangeMode.name,
          'customRangeText': state.customRangeText,
          'rotationAngle': state.rotationAngle,
          'printSides': state.printSides.name,
          'collateCopies': state.collateCopies,
          'reverseOrder': state.reverseOrder,
          'paperPresetName': state.paperPreset.name,
          'orientation': state.orientation.name,
          'scaling': state.scaling.name,
          'customScalePercent': state.customScalePercent,
          'autoRotatePages': state.autoRotatePages,
          'pagesPerSheet': state.pagesPerSheet,
          'marginMm': state.marginMm,
          'spacingMm': state.spacingMm,
          'centerPages': state.centerPages,
          'borderAroundPages': state.borderAroundPages,
          'paperTypeName': state.paperType.name,
          'bindingTypeName': state.bindingType.name,
          'totalPages': state.totalPages,
        };

        await RecentProjectsService.addProject(
          RecentProjectItem(
            id: _uuid.v4(),
            projectType: 'document',
            fileName: fName,
            presetMode: modeLabel,
            paperName: state.paperPreset.name,
            orientation: state.orientation.displayName,
            timestamp: DateTime.now(),
            thumbnailBytes: thumb,
            projectData: {
              'format': FpsProjectService.formatIdentifier,
              'version': FpsProjectService.currentVersion,
              'projectType': 'document',
              'fileName': fName,
              'savedAt': DateTime.now().toIso8601String(),
              'metadata': metadata,
              'rawImageBase64': base64Encode(raw),
            },
          ),
        );
      } catch (e) {
        debugPrint('Error saving document to recents on close: $e');
      }
    }

    await DraftStorageService.clearDocumentDraft();
    state = const DocumentPrintState();
  }

  Future<void> clearAll() async {
    await closeCurrentProject();
  }

  Future<void> reset() async {
    await closeCurrentProject();
  }
}

final documentPrintProvider = StateNotifierProvider<DocumentNotifier, DocumentPrintState>((ref) {
  return DocumentNotifier(ref);
});
