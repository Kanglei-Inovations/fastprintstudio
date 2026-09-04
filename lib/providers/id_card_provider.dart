import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../services/project/fps_project_service.dart';
import '../services/storage/recent_projects_service.dart';
import '../core/constants/id_card_presets.dart';
import '../core/constants/paper_presets.dart';
import '../core/models/crop_rect_data.dart';
import '../core/models/crop_result.dart';
import '../core/models/enhancement_config.dart';
import '../core/models/id_card_preset.dart';
import '../core/models/id_card_workflow_type.dart';
import '../core/models/l805_calibration.dart';
import '../core/models/paper_preset.dart';
import '../core/models/print_history_item.dart';
import '../core/models/print_layout.dart';
import '../services/detection/document_detector.dart';
import '../services/image/image_processor.dart';
import '../services/layout/layout_engine.dart';
import '../services/pdf/pdf_inspector.dart';
import '../services/pdf/pdf_rasterizer.dart';
import '../services/storage/draft_storage_service.dart';
import '../services/storage/l805_calibration_storage.dart';
import 'app_providers.dart';

class IdCardStateSnapshot {
  final CropRectData frontCrop;
  final CropRectData? backCrop;
  final bool hasBothSides;
  final bool swapFrontBack;
  final double gapMm;
  final double marginMm;
  final int printJobCopies;
  final EnhancementConfig frontEnhancement;
  final EnhancementConfig backEnhancement;
  final IdCardWorkflowType workflowType;
  final PvcOutputMode pvcMode;
  final int l805CardQuantity;
  final bool l805PreviewFront;

  IdCardStateSnapshot({
    required this.frontCrop,
    required this.backCrop,
    required this.hasBothSides,
    required this.swapFrontBack,
    required this.gapMm,
    required this.marginMm,
    required this.printJobCopies,
    required this.frontEnhancement,
    required this.backEnhancement,
    this.workflowType = IdCardWorkflowType.photoPaperLamination,
    this.pvcMode = PvcOutputMode.l805Tray,
    this.l805CardQuantity = 1,
    this.l805PreviewFront = true,
  });
}

class IdCardState {
  final Uint8List? rawSourceBytes;
  final bool isPdfSource;
  final String? fileName;
  final List<Uint8List> renderedPages;
  final int selectedPageIndex;
  final IDCardPreset idCardPreset;
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final bool hasBothSides;
  final CropRectData frontCrop;
  final CropRectData? backCrop;
  final EnhancementConfig frontEnhancement;
  final EnhancementConfig backEnhancement;
  final double gapMm;
  final double marginMm;
  final int printJobCopies;
  final bool swapFrontBack;
  final bool isProcessing;
  final bool isDetecting;
  final DocumentDetectionResult? detectionResult;
  final Uint8List? processedFrontBytes;
  final Uint8List? processedBackBytes;
  final PrintLayout? currentLayout;
  final String? errorMessage;
  final List<IdCardStateSnapshot> undoStack;
  final List<IdCardStateSnapshot> redoStack;

  // Password-protected PDF state
  final bool isPasswordRequired;
  final Uint8List? pendingEncryptedPdfBytes;
  final String? pendingEncryptedFileName;
  final String? passwordError;

  // Real print-shop workflow options
  final IdCardWorkflowType workflowType;
  final PvcOutputMode pvcMode;
  final List<Uint8List> dragonCards;
  final bool isDragonDuplex;

  // Epson L805 PVC Tray features
  final int l805CardQuantity; // 1 or 2
  final bool l805PreviewFront; // true: preview Front page, false: preview Back page
  final Uint8List? card2FrontBytes; // optional 2nd card front
  final Uint8List? card2BackBytes; // optional 2nd card back
  final L805Calibration l805Calibration;
  final PrintLayout? l805BackLayout;

  const IdCardState({
    this.rawSourceBytes,
    this.isPdfSource = false,
    this.fileName,
    this.renderedPages = const [],
    this.selectedPageIndex = 0,
    this.idCardPreset = StandardIDCardPresets.aadhaar,
    this.paperPreset = StandardPaperPresets.fourR,
    this.orientation = PaperOrientation.portrait,
    this.hasBothSides = true,
    this.frontCrop = const CropRectData(),
    this.backCrop,
    this.frontEnhancement = const EnhancementConfig(),
    this.backEnhancement = const EnhancementConfig(),
    this.gapMm = 5.0,
    this.marginMm = 4.0,
    this.printJobCopies = 1,
    this.swapFrontBack = false,
    this.isProcessing = false,
    this.isDetecting = false,
    this.detectionResult,
    this.processedFrontBytes,
    this.processedBackBytes,
    this.currentLayout,
    this.errorMessage,
    this.undoStack = const [],
    this.redoStack = const [],
    this.isPasswordRequired = false,
    this.pendingEncryptedPdfBytes,
    this.pendingEncryptedFileName,
    this.passwordError,
    this.workflowType = IdCardWorkflowType.photoPaperLamination,
    this.pvcMode = PvcOutputMode.l805Tray,
    this.dragonCards = const [],
    this.isDragonDuplex = true,
    this.l805CardQuantity = 1,
    this.l805PreviewFront = true,
    this.card2FrontBytes,
    this.card2BackBytes,
    this.l805Calibration = L805Calibration.factoryDefault,
    this.l805BackLayout,
  });

  bool get hasSource => rawSourceBytes != null && rawSourceBytes!.isNotEmpty;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  double get unitSellingPrice => workflowType.defaultPricePerCard;

  int get totalCardsCount {
    if (workflowType == IdCardWorkflowType.photoPaperLamination) {
      return 1;
    } else if (workflowType == IdCardWorkflowType.epsonL805) {
      return l805CardQuantity;
    } else {
      if (pvcMode == PvcOutputMode.dragonSheetDuplex) {
        return 5;
      } else {
        return 10;
      }
    }
  }

  double get calculatedSellingPrice => (unitSellingPrice * totalCardsCount * printJobCopies);

  double get calculatedMaterialCost {
    if (workflowType == IdCardWorkflowType.photoPaperLamination) {
      // 4R Photo Paper (₹4) + 4R Lamination Pouch (₹2.5) = ₹6.5 per sheet
      return (6.5 * printJobCopies);
    } else if (workflowType == IdCardWorkflowType.epsonL805) {
      // PVC card blank = ₹12.0 each
      return (12.0 * l805CardQuantity * printJobCopies);
    } else {
      // 200x300mm Dragon Sheet = ₹45.0
      return (45.0 * printJobCopies);
    }
  }

  double get calculatedInkCost => (3.0 * totalCardsCount * printJobCopies);

  double get calculatedEstimatedProfit => calculatedSellingPrice - calculatedMaterialCost - calculatedInkCost;

  Uint8List? get activePageImageBytes {
    if (renderedPages.isNotEmpty && selectedPageIndex < renderedPages.length) {
      return renderedPages[selectedPageIndex];
    }
    return rawSourceBytes;
  }

  IdCardState copyWith({
    Uint8List? rawSourceBytes,
    bool? isPdfSource,
    String? fileName,
    List<Uint8List>? renderedPages,
    int? selectedPageIndex,
    IDCardPreset? idCardPreset,
    PaperPreset? paperPreset,
    PaperOrientation? orientation,
    bool? hasBothSides,
    CropRectData? frontCrop,
    CropRectData? backCrop,
    bool clearBackCrop = false,
    EnhancementConfig? frontEnhancement,
    EnhancementConfig? backEnhancement,
    double? gapMm,
    double? marginMm,
    int? printJobCopies,
    bool? swapFrontBack,
    bool? isProcessing,
    bool? isDetecting,
    DocumentDetectionResult? detectionResult,
    Uint8List? processedFrontBytes,
    Uint8List? processedBackBytes,
    bool clearProcessedBackBytes = false,
    PrintLayout? currentLayout,
    String? errorMessage,
    bool clearError = false,
    List<IdCardStateSnapshot>? undoStack,
    List<IdCardStateSnapshot>? redoStack,
    bool? isPasswordRequired,
    Uint8List? pendingEncryptedPdfBytes,
    bool clearPendingEncryptedBytes = false,
    String? pendingEncryptedFileName,
    String? passwordError,
    bool clearPasswordError = false,
    IdCardWorkflowType? workflowType,
    PvcOutputMode? pvcMode,
    List<Uint8List>? dragonCards,
    bool? isDragonDuplex,
    int? l805CardQuantity,
    bool? l805PreviewFront,
    Uint8List? card2FrontBytes,
    bool clearCard2FrontBytes = false,
    Uint8List? card2BackBytes,
    bool clearCard2BackBytes = false,
    L805Calibration? l805Calibration,
    PrintLayout? l805BackLayout,
    bool clearL805BackLayout = false,
  }) {
    return IdCardState(
      rawSourceBytes: rawSourceBytes ?? this.rawSourceBytes,
      isPdfSource: isPdfSource ?? this.isPdfSource,
      fileName: fileName ?? this.fileName,
      renderedPages: renderedPages ?? this.renderedPages,
      selectedPageIndex: selectedPageIndex ?? this.selectedPageIndex,
      idCardPreset: idCardPreset ?? this.idCardPreset,
      paperPreset: paperPreset ?? this.paperPreset,
      orientation: orientation ?? this.orientation,
      hasBothSides: hasBothSides ?? this.hasBothSides,
      frontCrop: frontCrop ?? this.frontCrop,
      backCrop: clearBackCrop ? null : (backCrop ?? this.backCrop),
      frontEnhancement: frontEnhancement ?? this.frontEnhancement,
      backEnhancement: backEnhancement ?? this.backEnhancement,
      gapMm: gapMm ?? this.gapMm,
      marginMm: marginMm ?? this.marginMm,
      printJobCopies: printJobCopies ?? this.printJobCopies,
      swapFrontBack: swapFrontBack ?? this.swapFrontBack,
      isProcessing: isProcessing ?? this.isProcessing,
      isDetecting: isDetecting ?? this.isDetecting,
      detectionResult: detectionResult ?? this.detectionResult,
      processedFrontBytes: processedFrontBytes ?? this.processedFrontBytes,
      processedBackBytes: clearProcessedBackBytes ? null : (processedBackBytes ?? this.processedBackBytes),
      currentLayout: currentLayout ?? this.currentLayout,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isPasswordRequired: isPasswordRequired ?? this.isPasswordRequired,
      pendingEncryptedPdfBytes: clearPendingEncryptedBytes ? null : (pendingEncryptedPdfBytes ?? this.pendingEncryptedPdfBytes),
      pendingEncryptedFileName: pendingEncryptedFileName ?? this.pendingEncryptedFileName,
      passwordError: clearPasswordError ? null : (passwordError ?? this.passwordError),
      workflowType: workflowType ?? this.workflowType,
      pvcMode: pvcMode ?? this.pvcMode,
      dragonCards: dragonCards ?? this.dragonCards,
      isDragonDuplex: isDragonDuplex ?? this.isDragonDuplex,
      l805CardQuantity: l805CardQuantity ?? this.l805CardQuantity,
      l805PreviewFront: l805PreviewFront ?? this.l805PreviewFront,
      card2FrontBytes: clearCard2FrontBytes ? null : (card2FrontBytes ?? this.card2FrontBytes),
      card2BackBytes: clearCard2BackBytes ? null : (card2BackBytes ?? this.card2BackBytes),
      l805Calibration: l805Calibration ?? this.l805Calibration,
      l805BackLayout: clearL805BackLayout ? null : (l805BackLayout ?? this.l805BackLayout),
    );
  }
}

class IdCardNotifier extends StateNotifier<IdCardState> {
  final Ref _ref;
  static const _uuid = Uuid();

  IdCardNotifier(this._ref) : super(const IdCardState()) {
    _loadPersistedCalibration();
  }

  Future<void> _loadPersistedCalibration() async {
    try {
      final cal = await L805CalibrationStorage.loadCalibration();
      state = state.copyWith(l805Calibration: cal);
    } catch (_) {}
  }

  void _pushUndo() {
    final snapshot = IdCardStateSnapshot(
      frontCrop: state.frontCrop,
      backCrop: state.backCrop,
      hasBothSides: state.hasBothSides,
      swapFrontBack: state.swapFrontBack,
      gapMm: state.gapMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      frontEnhancement: state.frontEnhancement,
      backEnhancement: state.backEnhancement,
      workflowType: state.workflowType,
      pvcMode: state.pvcMode,
      l805CardQuantity: state.l805CardQuantity,
      l805PreviewFront: state.l805PreviewFront,
    );
    final newUndo = [...state.undoStack, snapshot];
    if (newUndo.length > 20) newUndo.removeAt(0);
    state = state.copyWith(undoStack: newUndo, redoStack: []);
  }

  /// Loads PDF or Image document and runs dynamic Aadhaar detection & layout pipeline
  Future<void> loadDocument({
    required Uint8List bytes,
    required String fileName,
    required bool isPdf,
    bool isRestoringDraft = false,
  }) async {
    // If PDF, inspect encryption and validity first
    if (isPdf) {
      final inspection = PdfInspector.inspectPdf(bytes);
      if (inspection.status == PdfStatus.passwordProtected) {
        state = state.copyWith(
          isPasswordRequired: true,
          pendingEncryptedPdfBytes: bytes,
          pendingEncryptedFileName: fileName,
          isProcessing: false,
          isDetecting: false,
          clearError: true,
          clearPasswordError: true,
        );
        return;
      } else if (inspection.status == PdfStatus.malformed) {
        state = state.copyWith(
          isProcessing: false,
          isDetecting: false,
          errorMessage: 'Unable to read this PDF. The file may be damaged or unsupported.',
        );
        return;
      }
    }

    state = state.copyWith(
      rawSourceBytes: bytes,
      fileName: fileName,
      isPdfSource: isPdf,
      isProcessing: true,
      isDetecting: true,
      isPasswordRequired: false,
      clearPendingEncryptedBytes: true,
      clearError: true,
      clearPasswordError: true,
    );

    try {
      List<Uint8List> pages = [];
      if (isPdf) {
        pages = await PdfRasterizer.rasterizeAllPages(pdfBytes: bytes, dpi: 300);
      } else {
        pages = [bytes];
      }

      if (pages.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          isDetecting: false,
          errorMessage: 'Unable to render document pages.',
        );
        return;
      }

      final workingImageBytes = pages.first;

      // Dynamic Content & Boundary Detection
      final detection = await DocumentDetector.detectIDCard(
        imageBytes: workingImageBytes,
        preset: state.idCardPreset,
      );

      final frontCrop = detection.frontCrop;
      final backCrop = detection.backCrop;
      final hasBoth = backCrop != null;

      // Extract and enhance cards
      final frontBytes = await ImageProcessor.processCardAsync(
        sourceBytes: workingImageBytes,
        cropData: frontCrop,
        enhancement: state.frontEnhancement,
        targetWidthMm: state.idCardPreset.widthMm,
        targetHeightMm: state.idCardPreset.heightMm,
      );

      Uint8List? backBytes;
      if (hasBoth) {
        backBytes = await ImageProcessor.processCardAsync(
          sourceBytes: workingImageBytes,
          cropData: backCrop,
          enhancement: state.backEnhancement,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
        );
      }

      // Calculate 4R Layout
      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: frontBytes,
        backImageBytes: backBytes,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );

      state = state.copyWith(
        renderedPages: pages,
        frontCrop: frontCrop,
        backCrop: backCrop,
        hasBothSides: hasBoth,
        detectionResult: detection,
        processedFrontBytes: frontBytes,
        processedBackBytes: backBytes,
        currentLayout: layout,
        isProcessing: false,
        isDetecting: false,
      );

      // Auto-save draft so document state is preserved across refresh / app close
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
          isDetecting: false,
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          isDetecting: false,
          errorMessage: e is PdfMalformedException ? e.message : 'Failed to process document: $e',
        );
      }
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

      // Explicitly clear password required state first
      state = state.copyWith(
        isPasswordRequired: false,
        clearPendingEncryptedBytes: true,
        clearPasswordError: true,
      );

      await loadDocument(bytes: decrypted, fileName: fName, isPdf: true);
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

  /// Manually re-runs dynamic auto-detection on the currently loaded document page
  Future<void> runAutoDetect() async {
    final activeBytes = state.activePageImageBytes;
    if (activeBytes == null) return;
    _pushUndo();
    state = state.copyWith(isProcessing: true, isDetecting: true, clearError: true);

    try {
      final detection = await DocumentDetector.detectIDCard(
        imageBytes: activeBytes,
        preset: state.idCardPreset,
      );

      final frontCrop = detection.frontCrop;
      final backCrop = detection.backCrop;
      final hasBoth = backCrop != null;

      final frontBytes = await ImageProcessor.processCardAsync(
        sourceBytes: activeBytes,
        cropData: frontCrop,
        enhancement: state.frontEnhancement,
        targetWidthMm: state.idCardPreset.widthMm,
        targetHeightMm: state.idCardPreset.heightMm,
      );

      Uint8List? backBytes;
      if (hasBoth) {
        backBytes = await ImageProcessor.processCardAsync(
          sourceBytes: activeBytes,
          cropData: backCrop,
          enhancement: state.backEnhancement,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
        );
      }

      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: frontBytes,
        backImageBytes: backBytes,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );

      state = state.copyWith(
        frontCrop: frontCrop,
        backCrop: backCrop,
        hasBothSides: hasBoth,
        detectionResult: detection,
        processedFrontBytes: frontBytes,
        processedBackBytes: backBytes,
        currentLayout: layout,
        isProcessing: false,
        isDetecting: false,
      );
    } catch (e) {
      debugPrint('Error running auto detect: $e');
      state = state.copyWith(
        isProcessing: false,
        isDetecting: false,
        errorMessage: 'Auto detection failed: $e',
      );
    }
  }

  /// Changes the active page when a multi-page PDF is loaded
  Future<void> selectPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= state.renderedPages.length) return;
    _pushUndo();
    state = state.copyWith(selectedPageIndex: pageIndex, isProcessing: true);

    final pageBytes = state.renderedPages[pageIndex];

    try {
      final detection = await DocumentDetector.detectIDCard(
        imageBytes: pageBytes,
        preset: state.idCardPreset,
      );

      final frontCrop = detection.frontCrop;
      final backCrop = detection.backCrop;
      final hasBoth = backCrop != null;

      final frontBytes = await ImageProcessor.processCardAsync(
        sourceBytes: pageBytes,
        cropData: frontCrop,
        enhancement: state.frontEnhancement,
        targetWidthMm: state.idCardPreset.widthMm,
        targetHeightMm: state.idCardPreset.heightMm,
      );

      Uint8List? backBytes;
      if (hasBoth) {
        backBytes = await ImageProcessor.processCardAsync(
          sourceBytes: pageBytes,
          cropData: backCrop,
          enhancement: state.backEnhancement,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
        );
      }

      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: frontBytes,
        backImageBytes: backBytes,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );

      state = state.copyWith(
        selectedPageIndex: pageIndex,
        frontCrop: frontCrop,
        backCrop: backCrop,
        hasBothSides: hasBoth,
        detectionResult: detection,
        processedFrontBytes: frontBytes,
        processedBackBytes: backBytes,
        currentLayout: layout,
        isProcessing: false,
      );
    } catch (e) {
      debugPrint('Error selecting page: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to process page: $e');
    }
  }

  /// Assigns a specific detected candidate as the Front Side
  Future<void> setCandidateAsFront(DetectedCandidate candidate) async {
    _pushUndo();
    state = state.copyWith(frontCrop: candidate.crop);
    await _reprocess();
  }

  /// Assigns a specific detected candidate as the Back Side
  Future<void> setCandidateAsBack(DetectedCandidate candidate) async {
    _pushUndo();
    state = state.copyWith(backCrop: candidate.crop, hasBothSides: true);
    await _reprocess();
  }

  /// Applies manual crop result from CropEditorModal for Front Card
  Future<void> applyFrontCropResult(CropResult cropResult) async {
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final normRect = cropResult.normalizedRect;
      final frontCrop = CropRectData(
        left: normRect.left,
        top: normRect.top,
        width: normRect.width,
        height: normRect.height,
        rotationDegrees: cropResult.rotationDegrees.toDouble(),
        fineAngleDegrees: cropResult.fineAngleDegrees,
        quadPoints: cropResult.quadPoints != null && cropResult.sourceWidth > 0 && cropResult.sourceHeight > 0
            ? cropResult.quadPoints!.scale(1.0 / cropResult.sourceWidth, 1.0 / cropResult.sourceHeight)
            : null,
      );

      final rawFront = state.activePageImageBytes ?? cropResult.croppedBytes;
      final frontBytes = await compute(
        _resizeCardWorker,
        _ResizeParams(
          bytes: rawFront,
          cropData: frontCrop,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
          enhancement: state.frontEnhancement,
          dpi: 300,
        ),
      );

      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: frontBytes,
        backImageBytes: state.hasBothSides ? state.processedBackBytes : null,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );

      state = state.copyWith(
        frontCrop: frontCrop,
        processedFrontBytes: frontBytes,
        currentLayout: layout,
        isProcessing: false,
      );
    } catch (e) {
      debugPrint('Error applying front crop: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to apply front crop: $e');
    }
  }

  /// Applies manual crop result from CropEditorModal for Back Card
  Future<void> applyBackCropResult(CropResult cropResult) async {
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final normRect = cropResult.normalizedRect;
      final backCrop = CropRectData(
        left: normRect.left,
        top: normRect.top,
        width: normRect.width,
        height: normRect.height,
        rotationDegrees: cropResult.rotationDegrees.toDouble(),
        fineAngleDegrees: cropResult.fineAngleDegrees,
        quadPoints: cropResult.quadPoints != null && cropResult.sourceWidth > 0 && cropResult.sourceHeight > 0
            ? cropResult.quadPoints!.scale(1.0 / cropResult.sourceWidth, 1.0 / cropResult.sourceHeight)
            : null,
      );

      final rawBack = state.activePageImageBytes ?? cropResult.croppedBytes;
      final backBytes = await compute(
        _resizeCardWorker,
        _ResizeParams(
          bytes: rawBack,
          cropData: backCrop,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
          enhancement: state.backEnhancement,
          dpi: 300,
        ),
      );

      final layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: state.processedFrontBytes!,
        backImageBytes: backBytes,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );

      state = state.copyWith(
        backCrop: backCrop,
        hasBothSides: true,
        processedBackBytes: backBytes,
        currentLayout: layout,
        isProcessing: false,
      );
    } catch (e) {
      debugPrint('Error applying back crop: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to apply back crop: $e');
    }
  }

  /// Toggles whether Back Side is included on the 4R sheet
  Future<void> toggleHasBothSides(bool hasBoth) async {
    _pushUndo();
    if (hasBoth && state.backCrop == null) {
      final fallbackBack = CropRectData(
        left: (state.frontCrop.left + 0.5).clamp(0.0, 0.95),
        top: state.frontCrop.top,
        width: state.frontCrop.width,
        height: state.frontCrop.height,
      );
      state = state.copyWith(hasBothSides: true, backCrop: fallbackBack);
    } else {
      state = state.copyWith(hasBothSides: hasBoth);
    }
    await _reprocess();
  }

  /// Swaps front and back placement
  void setSwapFrontBack(bool swap) {
    _pushUndo();
    state = state.copyWith(swapFrontBack: swap);
    _recalculateLayout();
  }

  /// Updates spacing between cards in mm
  void setGapMm(double gapMm) {
    _pushUndo();
    state = state.copyWith(gapMm: gapMm.clamp(0.0, 30.0));
    _recalculateLayout();
  }

  /// Updates margin around cards in mm
  void setMarginMm(double marginMm) {
    _pushUndo();
    state = state.copyWith(marginMm: marginMm.clamp(0.0, 30.0));
    _recalculateLayout();
  }

  void setPrintJobCopies(int copies) {
    state = state.copyWith(printJobCopies: copies.clamp(1, 100));
  }

  /// Updates paper preset
  void setPaperPreset(PaperPreset paper) {
    state = state.copyWith(paperPreset: paper);
    _recalculateLayout();
  }

  /// Updates orientation
  void setOrientation(PaperOrientation orientation) {
    state = state.copyWith(orientation: orientation);
    _recalculateLayout();
  }

  /// Updates ID card preset (e.g. Aadhaar, PAN, Voter ID)
  Future<void> setIdCardPreset(IDCardPreset preset) async {
    if (!state.hasSource) {
      state = state.copyWith(idCardPreset: preset);
      return;
    }
    _pushUndo();
    state = state.copyWith(idCardPreset: preset);
    await _reprocess();
  }

  /// Updates enhancements for both sides
  Future<void> updateEnhancements({
    double? brightness,
    double? contrast,
    double? sharpness,
  }) async {
    _pushUndo();
    final newFront = state.frontEnhancement.copyWith(
      brightness: brightness,
      contrast: contrast,
      sharpness: sharpness,
    );
    final newBack = state.backEnhancement.copyWith(
      brightness: brightness,
      contrast: contrast,
      sharpness: sharpness,
    );
    state = state.copyWith(
      frontEnhancement: newFront,
      backEnhancement: newBack,
    );
    await _reprocess();
  }

  /// Resets all image enhancements back to 0%
  Future<void> resetEnhancements() async {
    _pushUndo();
    state = state.copyWith(
      frontEnhancement: const EnhancementConfig(),
      backEnhancement: const EnhancementConfig(),
    );
    await _reprocess();
  }

  /// Updates front enhancement
  Future<void> updateFrontEnhancement(EnhancementConfig config) async {
    _pushUndo();
    state = state.copyWith(frontEnhancement: config);
    await _reprocess();
  }

  /// Updates back enhancement
  Future<void> updateBackEnhancement(EnhancementConfig config) async {
    _pushUndo();
    state = state.copyWith(backEnhancement: config);
    await _reprocess();
  }

  Future<void> _reprocess() async {
    final activeBytes = state.activePageImageBytes;
    if (activeBytes == null) return;
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final frontBytes = await ImageProcessor.processCardAsync(
        sourceBytes: activeBytes,
        cropData: state.frontCrop,
        enhancement: state.frontEnhancement,
        targetWidthMm: state.idCardPreset.widthMm,
        targetHeightMm: state.idCardPreset.heightMm,
      );

      Uint8List? backBytes;
      if (state.hasBothSides && state.backCrop != null) {
        backBytes = await ImageProcessor.processCardAsync(
          sourceBytes: activeBytes,
          cropData: state.backCrop!,
          enhancement: state.backEnhancement,
          targetWidthMm: state.idCardPreset.widthMm,
          targetHeightMm: state.idCardPreset.heightMm,
        );
      }

      PrintLayout layout;
      PrintLayout? backLayout;

      if (state.workflowType == IdCardWorkflowType.epsonL805) {
        final front1 = frontBytes;
        final back1 = state.hasBothSides ? backBytes : null;
        final front2 = state.card2FrontBytes ?? front1;
        final back2 = state.hasBothSides ? (state.card2BackBytes ?? back1) : null;

        final frontLayout = LayoutEngine.calculateL805A4TrayLayout(
          slot1ImageBytes: state.swapFrontBack ? (back1 ?? front1) : front1,
          slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? (back2 ?? front2) : front2) : null,
          isFrontPage: !state.swapFrontBack,
          calibration: state.l805Calibration,
        );

        if (state.hasBothSides && back1 != null) {
          backLayout = LayoutEngine.calculateL805A4TrayLayout(
            slot1ImageBytes: state.swapFrontBack ? front1 : back1,
            slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? front2 : (back2 ?? front2)) : null,
            isFrontPage: state.swapFrontBack,
            calibration: state.l805Calibration,
          );
        }

        layout = (state.l805PreviewFront || backLayout == null) ? frontLayout : backLayout;
      } else if (state.workflowType == IdCardWorkflowType.dragonSheet) {
        final cardList = <Uint8List>[];
        if (state.dragonCards.isNotEmpty) {
          cardList.addAll(state.dragonCards);
        } else {
          for (int i = 0; i < 10; i++) {
            if (state.pvcMode == PvcOutputMode.dragonSheetDuplex) {
              cardList.add((i % 2 == 0) ? frontBytes : (backBytes ?? frontBytes));
            } else {
              cardList.add(frontBytes);
            }
          }
        }
        layout = LayoutEngine.calculateDragonSheetLayout(
          cardImages: cardList,
          isDuplex: state.pvcMode == PvcOutputMode.dragonSheetDuplex,
          marginMm: state.marginMm,
          spacingMm: state.gapMm,
        );
      } else {
        layout = LayoutEngine.calculateIdCardLayout(
          paperPreset: state.paperPreset,
          idPreset: state.idCardPreset,
          frontImageBytes: frontBytes,
          backImageBytes: backBytes,
          swapFrontBack: state.swapFrontBack,
          gapMm: state.gapMm,
          marginMm: state.marginMm,
          orientation: state.orientation,
        );
      }

      state = state.copyWith(
        processedFrontBytes: frontBytes,
        processedBackBytes: backBytes,
        currentLayout: layout,
        l805BackLayout: backLayout,
        isProcessing: false,
      );
      saveDraft();
    } catch (e) {
      debugPrint('Error reprocessing ID Card: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Reprocessing failed: $e',
      );
    }
  }

  void _recalculateLayout() {
    if (state.processedFrontBytes == null) return;

    PrintLayout layout;
    PrintLayout? backLayout;

    if (state.workflowType == IdCardWorkflowType.epsonL805) {
      final front1 = state.processedFrontBytes!;
      final back1 = state.hasBothSides ? state.processedBackBytes : null;
      final front2 = state.card2FrontBytes ?? front1;
      final back2 = state.hasBothSides ? (state.card2BackBytes ?? back1) : null;

      final frontLayout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: state.swapFrontBack ? (back1 ?? front1) : front1,
        slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? (back2 ?? front2) : front2) : null,
        isFrontPage: !state.swapFrontBack,
        calibration: state.l805Calibration,
      );

      if (state.hasBothSides && back1 != null) {
        backLayout = LayoutEngine.calculateL805A4TrayLayout(
          slot1ImageBytes: state.swapFrontBack ? front1 : back1,
          slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? front2 : (back2 ?? front2)) : null,
          isFrontPage: state.swapFrontBack,
          calibration: state.l805Calibration,
        );
      }

      layout = (state.l805PreviewFront || backLayout == null) ? frontLayout : backLayout;
    } else if (state.workflowType == IdCardWorkflowType.dragonSheet) {
      final cardList = <Uint8List>[];
      if (state.dragonCards.isNotEmpty) {
        cardList.addAll(state.dragonCards);
      } else {
        for (int i = 0; i < 10; i++) {
          if (state.pvcMode == PvcOutputMode.dragonSheetDuplex) {
            cardList.add((i % 2 == 0)
                ? state.processedFrontBytes!
                : (state.processedBackBytes ?? state.processedFrontBytes!));
          } else {
            cardList.add(state.processedFrontBytes!);
          }
        }
      }
      layout = LayoutEngine.calculateDragonSheetLayout(
        cardImages: cardList,
        isDuplex: state.pvcMode == PvcOutputMode.dragonSheetDuplex,
        marginMm: state.marginMm,
        spacingMm: state.gapMm,
      );
    } else {
      layout = LayoutEngine.calculateIdCardLayout(
        paperPreset: state.paperPreset,
        idPreset: state.idCardPreset,
        frontImageBytes: state.processedFrontBytes!,
        backImageBytes: state.hasBothSides ? state.processedBackBytes : null,
        swapFrontBack: state.swapFrontBack,
        gapMm: state.gapMm,
        marginMm: state.marginMm,
        orientation: state.orientation,
      );
    }

    state = state.copyWith(
      currentLayout: layout,
      l805BackLayout: backLayout,
    );
    saveDraft();
  }

  void setWorkflowType(IdCardWorkflowType type) {
    PaperPreset newPaper;
    PaperOrientation newOrientation = state.orientation;

    if (type == IdCardWorkflowType.photoPaperLamination) {
      newPaper = StandardPaperPresets.fourR;
    } else if (type == IdCardWorkflowType.epsonL805) {
      newPaper = StandardPaperPresets.a4;
      newOrientation = PaperOrientation.portrait;
    } else {
      newPaper = StandardPaperPresets.dragonSheet200x300;
    }

    state = state.copyWith(
      workflowType: type,
      paperPreset: newPaper,
      orientation: newOrientation,
    );
    _recalculateLayout();
  }

  void setPvcOutputMode(PvcOutputMode mode) {
    final newPaper = (mode == PvcOutputMode.l805Tray)
        ? StandardPaperPresets.l805PvcTray
        : StandardPaperPresets.dragonSheet200x300;

    state = state.copyWith(
      pvcMode: mode,
      paperPreset: newPaper,
    );
    _recalculateLayout();
  }

  void setL805CardQuantity(int qty) {
    if (qty < 1 || qty > 2) return;
    state = state.copyWith(l805CardQuantity: qty);
    _recalculateLayout();
  }

  void setL805PreviewFront(bool isFront) {
    state = state.copyWith(l805PreviewFront: isFront);
    _recalculateLayout();
  }

  Future<void> updateL805Calibration(L805Calibration cal) async {
    state = state.copyWith(l805Calibration: cal);
    await L805CalibrationStorage.saveCalibration(cal);
    _recalculateLayout();
  }

  Future<void> resetL805Calibration() async {
    await L805CalibrationStorage.resetToDefaults();
    state = state.copyWith(l805Calibration: L805Calibration.factoryDefault);
    _recalculateLayout();
  }

  void setCard2Bytes({Uint8List? front, Uint8List? back}) {
    state = state.copyWith(
      card2FrontBytes: front,
      card2BackBytes: back,
    );
    _recalculateLayout();
  }

  void duplicateCard1ToCard2() {
    state = state.copyWith(
      card2FrontBytes: state.processedFrontBytes,
      card2BackBytes: state.processedBackBytes,
    );
    _recalculateLayout();
  }

  void rotateCrop(int deltaDegrees) {
    final currentRot = state.frontCrop.rotationDegrees;
    final newRot = (currentRot + deltaDegrees) % 360;
    state = state.copyWith(
      frontCrop: state.frontCrop.copyWith(rotationDegrees: newRot.toDouble()),
      backCrop: state.backCrop?.copyWith(rotationDegrees: newRot.toDouble()),
    );
    _reprocess();
  }

  void undo() {
    if (!state.canUndo) return;
    final last = state.undoStack.last;
    final newUndo = List<IdCardStateSnapshot>.from(state.undoStack)..removeLast();

    final currentSnapshot = IdCardStateSnapshot(
      frontCrop: state.frontCrop,
      backCrop: state.backCrop,
      hasBothSides: state.hasBothSides,
      swapFrontBack: state.swapFrontBack,
      gapMm: state.gapMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      frontEnhancement: state.frontEnhancement,
      backEnhancement: state.backEnhancement,
      workflowType: state.workflowType,
      pvcMode: state.pvcMode,
      l805CardQuantity: state.l805CardQuantity,
      l805PreviewFront: state.l805PreviewFront,
    );

    state = state.copyWith(
      undoStack: newUndo,
      redoStack: [...state.redoStack, currentSnapshot],
      frontCrop: last.frontCrop,
      backCrop: last.backCrop,
      hasBothSides: last.hasBothSides,
      swapFrontBack: last.swapFrontBack,
      gapMm: last.gapMm,
      marginMm: last.marginMm,
      printJobCopies: last.printJobCopies,
      frontEnhancement: last.frontEnhancement,
      backEnhancement: last.backEnhancement,
      workflowType: last.workflowType,
      pvcMode: last.pvcMode,
      l805CardQuantity: last.l805CardQuantity,
      l805PreviewFront: last.l805PreviewFront,
    );

    _reprocess();
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    final newRedo = List<IdCardStateSnapshot>.from(state.redoStack)..removeLast();

    final currentSnapshot = IdCardStateSnapshot(
      frontCrop: state.frontCrop,
      backCrop: state.backCrop,
      hasBothSides: state.hasBothSides,
      swapFrontBack: state.swapFrontBack,
      gapMm: state.gapMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      frontEnhancement: state.frontEnhancement,
      backEnhancement: state.backEnhancement,
      workflowType: state.workflowType,
      pvcMode: state.pvcMode,
      l805CardQuantity: state.l805CardQuantity,
      l805PreviewFront: state.l805PreviewFront,
    );
    final newUndo = [...state.undoStack, currentSnapshot];

    state = state.copyWith(
      undoStack: newUndo,
      redoStack: newRedo,
      frontCrop: next.frontCrop,
      backCrop: next.backCrop,
      hasBothSides: next.hasBothSides,
      swapFrontBack: next.swapFrontBack,
      gapMm: next.gapMm,
      marginMm: next.marginMm,
      printJobCopies: next.printJobCopies,
      frontEnhancement: next.frontEnhancement,
      backEnhancement: next.backEnhancement,
      workflowType: next.workflowType,
      pvcMode: next.pvcMode,
      l805CardQuantity: next.l805CardQuantity,
      l805PreviewFront: next.l805PreviewFront,
    );

    _reprocess();
  }

  Future<bool> printDocument({Printer? targetPrinter}) async {
    if (state.workflowType == IdCardWorkflowType.epsonL805) {
      if (state.processedFrontBytes == null) return false;

      final front1 = state.processedFrontBytes!;
      final back1 = state.hasBothSides ? state.processedBackBytes : null;
      final front2 = state.card2FrontBytes ?? front1;
      final back2 = state.hasBothSides ? (state.card2BackBytes ?? back1) : null;

      final frontLayout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: state.swapFrontBack ? (back1 ?? front1) : front1,
        slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? (back2 ?? front2) : front2) : null,
        isFrontPage: !state.swapFrontBack,
        calibration: state.l805Calibration,
      );

      final layouts = <PrintLayout>[frontLayout];
      if (state.hasBothSides && back1 != null) {
        final backLayout = LayoutEngine.calculateL805A4TrayLayout(
          slot1ImageBytes: state.swapFrontBack ? front1 : back1,
          slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? front2 : (back2 ?? front2)) : null,
          isFrontPage: state.swapFrontBack,
          calibration: state.l805Calibration,
        );
        layouts.add(backLayout);
      }

      final printerService = _ref.read(printerServiceProvider);
      final success = await printerService.printMultiLayout(
        layouts,
        printer: targetPrinter,
        jobName: '${state.idCardPreset.name} (Epson L805 PVC Tray - ${layouts.length} A4 Pages)',
      );

      await _ref.read(historyProvider.notifier).addRecord(
            PrintHistoryItem(
              id: _uuid.v4(),
              timestamp: DateTime.now(),
              serviceName: 'Epson L805 Card Print',
              paperName: 'A4 (${layouts.length} Pages)',
              copiesCount: state.l805CardQuantity * state.printJobCopies,
              printerName: targetPrinter?.name ?? 'System Print Dialog',
              status: success ? 'Printed' : 'Print Submitted',
              dimensionsSummary: '${state.idCardPreset.formattedDimensions} (${state.l805CardQuantity} card${state.l805CardQuantity > 1 ? 's' : ''}, ${layouts.length} A4 pgs)',
              sellingPrice: state.calculatedSellingPrice,
              materialCost: state.calculatedMaterialCost,
              inkCost: state.calculatedInkCost,
              profit: state.calculatedEstimatedProfit,
              paymentStatus: 'Paid',
              paymentMethod: 'UPI',
            ),
          );

      return success;
    }

    final layout = state.currentLayout;
    if (layout == null || layout.items.isEmpty) return false;

    final printerService = _ref.read(printerServiceProvider);
    final success = await printerService.printLayout(
      layout,
      printer: targetPrinter,
      jobName: '${state.idCardPreset.name} (4R Print)',
    );

    await _ref.read(historyProvider.notifier).addRecord(
          PrintHistoryItem(
            id: _uuid.v4(),
            timestamp: DateTime.now(),
            serviceName: state.idCardPreset.name,
            paperName: layout.paperPreset.name,
            copiesCount: layout.itemCount * state.printJobCopies,
            printerName: targetPrinter?.name ?? 'System Print Dialog',
            status: success ? 'Printed' : 'Print Submitted',
            dimensionsSummary: '${state.idCardPreset.formattedDimensions} (${layout.itemCount} cards)',
            sellingPrice: state.calculatedSellingPrice,
            materialCost: state.calculatedMaterialCost,
            inkCost: state.calculatedInkCost,
            profit: state.calculatedEstimatedProfit,
            paymentStatus: 'Paid',
            paymentMethod: 'UPI',
          ),
        );

    return success;
  }

  Future<bool> exportPdf() async {
    if (state.workflowType == IdCardWorkflowType.epsonL805) {
      if (state.processedFrontBytes == null) return false;

      final front1 = state.processedFrontBytes!;
      final back1 = state.hasBothSides ? state.processedBackBytes : null;
      final front2 = state.card2FrontBytes ?? front1;
      final back2 = state.hasBothSides ? (state.card2BackBytes ?? back1) : null;

      final frontLayout = LayoutEngine.calculateL805A4TrayLayout(
        slot1ImageBytes: state.swapFrontBack ? (back1 ?? front1) : front1,
        slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? (back2 ?? front2) : front2) : null,
        isFrontPage: !state.swapFrontBack,
        calibration: state.l805Calibration,
      );

      final layouts = <PrintLayout>[frontLayout];
      if (state.hasBothSides && back1 != null) {
        final backLayout = LayoutEngine.calculateL805A4TrayLayout(
          slot1ImageBytes: state.swapFrontBack ? front1 : back1,
          slot2ImageBytes: state.l805CardQuantity == 2 ? (state.swapFrontBack ? front2 : (back2 ?? front2)) : null,
          isFrontPage: state.swapFrontBack,
          calibration: state.l805Calibration,
        );
        layouts.add(backLayout);
      }

      final printerService = _ref.read(printerServiceProvider);
      final fileName = '${state.idCardPreset.name.replaceAll(' ', '_')}_Epson_L805_A4_PVC';
      final success = await printerService.exportMultiLayoutPdf(
        layouts,
        fileName,
      );

      return success;
    }

    final layout = state.currentLayout;
    if (layout == null || layout.items.isEmpty) return false;

    final printerService = _ref.read(printerServiceProvider);
    final fileName = '${state.idCardPreset.name.replaceAll(' ', '_')}_4R_Print';

    final success = await printerService.exportPdf(
      layout,
      fileName,
    );

    return success;
  }

  /// Saves project state into local draft storage so work continues even after PC shutdown
  Future<void> saveDraft() async {
    final raw = state.rawSourceBytes;
    final fName = state.fileName;
    if (raw == null || fName == null) return;

    final metadata = {
      'isPdfSource': state.isPdfSource,
      'selectedPageIndex': state.selectedPageIndex,
      'idCardPresetId': state.idCardPreset.id,
      'workflowTypeName': state.workflowType.name,
      'paperPresetName': state.paperPreset.name,
      'orientationName': state.orientation.name,
      'hasBothSides': state.hasBothSides,
      'frontCrop': {
        'left': state.frontCrop.left,
        'top': state.frontCrop.top,
        'width': state.frontCrop.width,
        'height': state.frontCrop.height,
        'rotationDegrees': state.frontCrop.rotationDegrees,
        'fineAngleDegrees': state.frontCrop.fineAngleDegrees,
      },
      'backCrop': state.backCrop != null
          ? {
              'left': state.backCrop!.left,
              'top': state.backCrop!.top,
              'width': state.backCrop!.width,
              'height': state.backCrop!.height,
              'rotationDegrees': state.backCrop!.rotationDegrees,
              'fineAngleDegrees': state.backCrop!.fineAngleDegrees,
            }
          : null,
      'frontEnhancement': state.frontEnhancement.toJson(),
      'backEnhancement': state.backEnhancement.toJson(),
      'gapMm': state.gapMm,
      'marginMm': state.marginMm,
      'printJobCopies': state.printJobCopies,
      'swapFrontBack': state.swapFrontBack,
      'pvcModeName': state.pvcMode.name,
      'l805CardQuantity': state.l805CardQuantity,
      'l805PreviewFront': state.l805PreviewFront,
    };

    await DraftStorageService.saveIdCardDraft(
      bytes: raw,
      fileName: fName,
      metadata: metadata,
    );
  }

  /// Restores complete ID card project from saved draft or .fps file cleanly
  Future<void> restoreProjectFromData({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    final isPdf = metadata['isPdfSource'] as bool? ?? fileName.toLowerCase().endsWith('.pdf');
    await loadDocument(bytes: bytes, fileName: fileName, isPdf: isPdf, isRestoringDraft: true);

    try {
      final presetId = metadata['idCardPresetId'] as String?;
      if (presetId != null) {
        final preset = StandardIDCardPresets.all.where((p) => p.id == presetId).firstOrNull;
        if (preset != null) {
          state = state.copyWith(idCardPreset: preset);
        }
      }

      final paperPresetName = metadata['paperPresetName'] as String?;
      if (paperPresetName != null) {
        final paper = StandardPaperPresets.all.where((p) => p.name == paperPresetName).firstOrNull;
        if (paper != null) {
          state = state.copyWith(paperPreset: paper);
        }
      }

      final orientationName = metadata['orientationName'] as String?;
      if (orientationName == 'portrait') {
        state = state.copyWith(orientation: PaperOrientation.portrait);
      } else if (orientationName == 'landscape') {
        state = state.copyWith(orientation: PaperOrientation.landscape);
      }

      final wfName = metadata['workflowTypeName'] as String?;
      if (wfName != null) {
        final wf = IdCardWorkflowType.values.where((w) => w.name == wfName).firstOrNull;
        if (wf != null) {
          state = state.copyWith(workflowType: wf);
        }
      }

      final pvcName = metadata['pvcModeName'] as String?;
      if (pvcName != null) {
        final pvc = PvcOutputMode.values.where((p) => p.name == pvcName).firstOrNull;
        if (pvc != null) {
          state = state.copyWith(pvcMode: pvc);
        }
      }

      final qty = metadata['l805CardQuantity'] as int?;
      if (qty != null) {
        state = state.copyWith(l805CardQuantity: qty);
      }

      final copies = metadata['printJobCopies'] as int?;
      if (copies != null) {
        state = state.copyWith(printJobCopies: copies);
      }

      final gap = (metadata['gapMm'] as num?)?.toDouble();
      if (gap != null) {
        state = state.copyWith(gapMm: gap);
      }

      final margin = (metadata['marginMm'] as num?)?.toDouble();
      if (margin != null) {
        state = state.copyWith(marginMm: margin);
      }

      final swap = metadata['swapFrontBack'] as bool?;
      if (swap != null) {
        state = state.copyWith(swapFrontBack: swap);
      }

      final both = metadata['hasBothSides'] as bool?;
      if (both != null) {
        state = state.copyWith(hasBothSides: both);
      }

      final frontCropMap = metadata['frontCrop'] as Map<String, dynamic>?;
      if (frontCropMap != null) {
        state = state.copyWith(
          frontCrop: CropRectData(
            left: (frontCropMap['left'] as num?)?.toDouble() ?? 0.0,
            top: (frontCropMap['top'] as num?)?.toDouble() ?? 0.0,
            width: (frontCropMap['width'] as num?)?.toDouble() ?? 1.0,
            height: (frontCropMap['height'] as num?)?.toDouble() ?? 1.0,
            rotationDegrees: (frontCropMap['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
            fineAngleDegrees: (frontCropMap['fineAngleDegrees'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      final backCropMap = metadata['backCrop'] as Map<String, dynamic>?;
      if (backCropMap != null) {
        state = state.copyWith(
          backCrop: CropRectData(
            left: (backCropMap['left'] as num?)?.toDouble() ?? 0.0,
            top: (backCropMap['top'] as num?)?.toDouble() ?? 0.0,
            width: (backCropMap['width'] as num?)?.toDouble() ?? 1.0,
            height: (backCropMap['height'] as num?)?.toDouble() ?? 1.0,
            rotationDegrees: (backCropMap['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
            fineAngleDegrees: (backCropMap['fineAngleDegrees'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      final frontEnhanceJson = metadata['frontEnhancement'] as Map<String, dynamic>?;
      if (frontEnhanceJson != null) {
        state = state.copyWith(frontEnhancement: EnhancementConfig.fromJson(frontEnhanceJson));
      }
      final backEnhanceJson = metadata['backEnhancement'] as Map<String, dynamic>?;
      if (backEnhanceJson != null) {
        state = state.copyWith(backEnhancement: EnhancementConfig.fromJson(backEnhanceJson));
      }

      await _reprocess();
    } catch (e) {
      debugPrint('Error restoring ID card project data: $e');
    }
  }

  /// Automatically restores last active ID card project draft when app starts
  Future<void> restoreDraftIfExists() async {
    final draft = await DraftStorageService.loadIdCardDraft();
    if (draft == null) return;

    final bytes = draft['bytes'] as Uint8List?;
    final fName = draft['fileName'] as String?;
    final meta = draft['metadata'] as Map<String, dynamic>? ?? {};

    if (bytes != null && bytes.isNotEmpty && fName != null) {
      debugPrint('Auto-restoring last ID card project draft: $fName');
      await restoreProjectFromData(bytes: bytes, fileName: fName, metadata: meta);
    }
  }

  /// Saves current ID card project as a standalone .fps project file
  Future<String?> saveProjectAsFps() async {
    final raw = state.rawSourceBytes;
    final fName = state.fileName;
    if (raw == null || fName == null || raw.isEmpty) return null;

    final metadata = {
      'isPdfSource': state.isPdfSource,
      'idCardPresetId': state.idCardPreset.id,
      'idCardPresetName': state.idCardPreset.name,
      'paperPresetName': state.paperPreset.name,
      'orientationName': state.orientation.name,
      'workflowTypeName': state.workflowType.name,
      'gapMm': state.gapMm,
      'marginMm': state.marginMm,
      'printJobCopies': state.printJobCopies,
      'frontCrop': state.frontCrop.toJson(),
      'backCrop': state.backCrop?.toJson(),
      'frontEnhancement': state.frontEnhancement.toJson(),
      'backEnhancement': state.backEnhancement.toJson(),
      'hasBothSides': state.hasBothSides,
      'swapFrontBack': state.swapFrontBack,
      'pvcModeName': state.pvcMode.name,
      'l805CardQuantity': state.l805CardQuantity,
      'l805PreviewFront': state.l805PreviewFront,
    };

    final thumb = state.processedFrontBytes ?? state.processedBackBytes ?? state.activePageImageBytes;
    final path = await FpsProjectService.saveProjectAsFps(
      projectType: 'id_card',
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
      data = await FpsProjectService.pickAndLoadFpsFile(title: 'Open ID Card Project');
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

  /// Closes current active ID card project, saves to Recent Projects, and resets workspace
  Future<void> closeCurrentProject() async {
    if (state.hasSource) {
      try {
        final raw = state.rawSourceBytes!;
        final fName = state.fileName ?? 'Untitled ID Card';
        final thumb = state.processedFrontBytes ?? state.processedBackBytes ?? state.activePageImageBytes;
        final metadata = {
          'isPdfSource': state.isPdfSource,
          'idCardPresetId': state.idCardPreset.id,
          'idCardPresetName': state.idCardPreset.name,
          'paperPresetName': state.paperPreset.name,
          'orientationName': state.orientation.name,
          'workflowTypeName': state.workflowType.name,
          'gapMm': state.gapMm,
          'marginMm': state.marginMm,
          'printJobCopies': state.printJobCopies,
          'frontCrop': state.frontCrop.toJson(),
          'backCrop': state.backCrop?.toJson(),
          'frontEnhancement': state.frontEnhancement.toJson(),
          'backEnhancement': state.backEnhancement.toJson(),
          'hasBothSides': state.hasBothSides,
          'swapFrontBack': state.swapFrontBack,
          'pvcModeName': state.pvcMode.name,
          'l805CardQuantity': state.l805CardQuantity,
          'l805PreviewFront': state.l805PreviewFront,
        };

        await RecentProjectsService.addProject(
          RecentProjectItem(
            id: _uuid.v4(),
            projectType: 'id_card',
            fileName: fName,
            presetMode: state.idCardPreset.name,
            paperName: state.paperPreset.name,
            orientation: state.orientation.displayName,
            timestamp: DateTime.now(),
            thumbnailBytes: thumb,
            projectData: {
              'format': FpsProjectService.formatIdentifier,
              'version': FpsProjectService.currentVersion,
              'projectType': 'id_card',
              'fileName': fName,
              'savedAt': DateTime.now().toIso8601String(),
              'metadata': metadata,
              'rawImageBase64': base64Encode(raw),
            },
          ),
        );
      } catch (e) {
        debugPrint('Error saving to recents on close: $e');
      }
    }

    await DraftStorageService.clearIdCardDraft();
    state = const IdCardState();
  }

  Future<void> clearAll() async {
    await closeCurrentProject();
  }

  Future<void> reset() async {
    await closeCurrentProject();
  }
}

class _ResizeParams {
  final Uint8List bytes;
  final CropRectData? cropData;
  final double targetWidthMm;
  final double targetHeightMm;
  final EnhancementConfig enhancement;
  final int dpi;

  _ResizeParams({
    required this.bytes,
    this.cropData,
    required this.targetWidthMm,
    required this.targetHeightMm,
    required this.enhancement,
    required this.dpi,
  });
}

Uint8List _resizeCardWorker(_ResizeParams params) {
  var image = img.decodeImage(params.bytes);
  if (image == null) return params.bytes;

  if (params.cropData != null) {
    if (params.cropData!.rotationDegrees != 0) {
      image = ImageProcessor.rotate(image, params.cropData!.rotationDegrees.round());
    }
    if (params.cropData!.fineAngleDegrees.abs() > 0.01) {
      image = ImageProcessor.rotateArbitrary(image, params.cropData!.fineAngleDegrees);
    }
    image = ImageProcessor.cropNormalized(image, params.cropData!);
  }

  // 1. Resize directly to physical card dimensions (e.g. 1011x638 px)
  final resized = ImageProcessor.resizeToPhysical(
    image,
    targetWidthMm: params.targetWidthMm,
    targetHeightMm: params.targetHeightMm,
    dpi: params.dpi,
  );

  // 2. Enhance small target image (takes only 3-5ms!)
  final enhanced = ImageProcessor.adjustEnhancements(resized, params.enhancement);

  return ImageProcessor.encodePng(enhanced);
}

final idCardProvider = StateNotifierProvider<IdCardNotifier, IdCardState>((ref) {
  return IdCardNotifier(ref);
});
