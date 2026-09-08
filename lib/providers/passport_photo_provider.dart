import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../core/utils/unit_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/paper_presets.dart';
import '../core/constants/photo_presets.dart';
import '../core/models/border_config.dart';
import '../core/models/crop_rect_data.dart';
import '../core/models/crop_result.dart';
import '../core/models/enhancement_config.dart';
import '../core/models/paper_preset.dart';
import '../core/models/photo_finish.dart';
import '../core/models/photo_group.dart';
import '../core/models/photo_preset.dart';
import '../core/models/print_history_item.dart';
import '../core/models/print_layout.dart';
import '../services/detection/face_detector.dart';
import '../services/image/background_remover_service.dart';
import '../services/image/image_processor.dart';
import '../services/layout/layout_engine.dart';
import '../services/project/fps_project_service.dart';
import '../services/storage/draft_storage_service.dart';
import '../services/storage/recent_projects_service.dart';
import 'app_providers.dart';

enum PhotoTypePresetMode {
  passportOnly,
  passportPlusStamp,
  fourRPhoto,
  a4Photo,
}

extension PhotoTypePresetModeX on PhotoTypePresetMode {
  String get displayName {
    switch (this) {
      case PhotoTypePresetMode.passportOnly:
        return 'Passport';
      case PhotoTypePresetMode.passportPlusStamp:
        return 'Pass+Stamp';
      case PhotoTypePresetMode.fourRPhoto:
        return '4R Photo';
      case PhotoTypePresetMode.a4Photo:
        return 'A4 Photo';
    }
  }
}

class PassportPhotoStateSnapshot {
  final List<PhotoGroup> groups;
  final PhotoTypePresetMode presetMode;
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final double spacingMm;
  final double marginMm;
  final int printJobCopies;
  final EnhancementConfig enhancement;
  final BorderConfig borderConfig;
  final PhotoFinish photoFinish;
  final PhotoLamination photoLamination;
  final PhotoFraming photoFraming;
  final PhotoScalingMode photoScaling;
  final String? backgroundColorHex;
  final Uint8List? originalRawImageBytes;
  final bool isBgRemoved;
  final int activeSheetIndex;

  PassportPhotoStateSnapshot({
    required this.groups,
    required this.presetMode,
    required this.paperPreset,
    required this.orientation,
    required this.spacingMm,
    required this.marginMm,
    required this.printJobCopies,
    required this.enhancement,
    required this.borderConfig,
    this.photoFinish = PhotoFinish.glossy,
    this.photoLamination = PhotoLamination.none,
    this.photoFraming = PhotoFraming.none,
    this.photoScaling = PhotoScalingMode.fit,
    this.backgroundColorHex,
    this.originalRawImageBytes,
    this.isBgRemoved = false,
    this.activeSheetIndex = 0,
  });
}

class PassportPhotoState {
  final Uint8List? rawImageBytes;
  final Uint8List? originalRawImageBytes;
  final bool isBgRemoved;
  final String? fileName;
  final PhotoTypePresetMode presetMode;
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final List<PhotoGroup> groups;
  final String? activeGroupId;
  final double spacingMm;
  final double marginMm;
  final int printJobCopies;
  final EnhancementConfig enhancement;
  final BorderConfig borderConfig;
  final PhotoFinish photoFinish;
  final PhotoLamination photoLamination;
  final PhotoFraming photoFraming;
  final PhotoScalingMode photoScaling;
  final String? backgroundColorHex;
  final bool isProcessing;
  final String processingStatusText;
  final bool isDetectingFace;
  final List<PrintLayout> currentLayouts;
  final int activeSheetIndex;
  final PrintLayout? _legacyCurrentLayout;
  final String? errorMessage;
  final List<PassportPhotoStateSnapshot> undoStack;
  final List<PassportPhotoStateSnapshot> redoStack;

  const PassportPhotoState({
    this.rawImageBytes,
    this.originalRawImageBytes,
    this.isBgRemoved = false,
    this.fileName,
    this.presetMode = PhotoTypePresetMode.passportOnly,
    this.paperPreset = StandardPaperPresets.fourR,
    this.orientation = PaperOrientation.landscape,
    this.groups = const [],
    this.activeGroupId,
    this.spacingMm = 0.0,
    this.marginMm = 0.0,
    this.printJobCopies = 1,
    this.enhancement = const EnhancementConfig(),
    this.borderConfig = const BorderConfig(outerBorderMm: 2.0, innerBorderMm: 0.15, enabled: true),
    this.photoFinish = PhotoFinish.glossy,
    this.photoLamination = PhotoLamination.none,
    this.photoFraming = PhotoFraming.none,
    this.photoScaling = PhotoScalingMode.fit,
    this.backgroundColorHex,
    this.isProcessing = false,
    this.processingStatusText = '',
    this.isDetectingFace = false,
    this.currentLayouts = const [],
    this.activeSheetIndex = 0,
    PrintLayout? currentLayout,
    this.errorMessage,
    this.undoStack = const [],
    this.redoStack = const [],
  }) : _legacyCurrentLayout = currentLayout;

  bool get hasImage => rawImageBytes != null && rawImageBytes!.isNotEmpty;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  PrintLayout? get currentLayout {
    if (currentLayouts.isNotEmpty) {
      final idx = activeSheetIndex.clamp(0, currentLayouts.length - 1);
      return currentLayouts[idx];
    }
    return _legacyCurrentLayout;
  }

  int get totalCopiesCount => groups.fold<int>(0, (sum, g) => sum + g.copiesCount);

  int get totalFilesCount {
    if (!hasImage && groups.isEmpty) return 0;
    final uniqueImages = <Uint8List>{};
    if (rawImageBytes != null && rawImageBytes!.isNotEmpty) {
      uniqueImages.add(rawImageBytes!);
    }
    for (final g in groups) {
      if (g.rawImageBytes != null && g.rawImageBytes!.isNotEmpty) {
        uniqueImages.add(g.rawImageBytes!);
      }
    }
    return uniqueImages.isNotEmpty ? uniqueImages.length : (hasImage ? 1 : 0);
  }

  int get totalSheetsRequired {
    if (currentLayouts.isNotEmpty) {
      return currentLayouts.length;
    }
    if (currentLayout != null && currentLayout!.maxCapacity > 0) {
      return (totalCopiesCount / currentLayout!.maxCapacity).ceil().clamp(1, 999);
    }
    return 1;
  }

  double get calculatedSellingPrice {
    final sheets = totalSheetsRequired;
    final isA4 = paperPreset.id == 'a4';
    final basePrice = isA4 ? 100.0 : 50.0;
    final additionalPrice = isA4 ? 60.0 : 30.0;
    final baseSheetTotal = basePrice + ((sheets - 1) * additionalPrice);

    // Matte paper premium adjustment
    final paperQualityExtra = photoFinish.extraPricePerSheet * sheets;

    // Finishing adjustments (Lamination + Framing)
    final laminationExtra = photoLamination.extraPrice * sheets;
    final framingExtra = photoFraming.extraPrice;

    return (baseSheetTotal + paperQualityExtra + laminationExtra + framingExtra) * printJobCopies;
  }

  double get calculatedMaterialCost {
    final sheets = totalSheetsRequired;
    final isA4 = paperPreset.id == 'a4';
    final basePaperCost = isA4 ? photoFinish.paperCost * 2.2 : photoFinish.paperCost;
    final totalPaperCost = basePaperCost * sheets;
    final laminationCost = photoLamination.materialCost * sheets;
    final framingCost = photoFraming.materialCost;

    return (totalPaperCost + laminationCost + framingCost) * printJobCopies;
  }

  double get calculatedInkCost {
    final sheets = totalSheetsRequired;
    final inkPerSheet = paperPreset.id == 'a4' ? 6.0 : 2.5;
    return inkPerSheet * sheets * printJobCopies;
  }

  double get calculatedProfit => calculatedSellingPrice - calculatedMaterialCost - calculatedInkCost;

  PhotoGroup? get activeGroup {
    if (groups.isEmpty) return null;
    if (activeGroupId == null) return groups.first;
    return groups.firstWhere((g) => g.id == activeGroupId, orElse: () => groups.first);
  }

  // Backward compatibility getters
  PhotoPreset get photoPreset => activeGroup?.preset ?? StandardPhotoPresets.passport;
  CropRectData get cropData => activeGroup?.cropData ?? const CropRectData();
  int? get copiesCount => activeGroup?.copiesCount;

  PassportPhotoState copyWith({
    Uint8List? rawImageBytes,
    Uint8List? originalRawImageBytes,
    bool clearOriginalRawImageBytes = false,
    bool? isBgRemoved,
    String? fileName,
    PhotoTypePresetMode? presetMode,
    PaperPreset? paperPreset,
    PaperOrientation? orientation,
    List<PhotoGroup>? groups,
    String? activeGroupId,
    double? spacingMm,
    double? marginMm,
    int? printJobCopies,
    EnhancementConfig? enhancement,
    BorderConfig? borderConfig,
    PhotoFinish? photoFinish,
    PhotoLamination? photoLamination,
    PhotoFraming? photoFraming,
    PhotoScalingMode? photoScaling,
    String? backgroundColorHex,
    bool clearBackgroundColor = false,
    bool? isProcessing,
    String? processingStatusText,
    bool? isDetectingFace,
    PrintLayout? currentLayout,
    List<PrintLayout>? currentLayouts,
    int? activeSheetIndex,
    String? errorMessage,
    bool clearError = false,
    List<PassportPhotoStateSnapshot>? undoStack,
    List<PassportPhotoStateSnapshot>? redoStack,
  }) {
    List<PrintLayout> nextLayouts = currentLayouts ?? this.currentLayouts;
    if (currentLayout != null && currentLayouts == null) {
      nextLayouts = [currentLayout];
    }
    final nextActiveIndex = activeSheetIndex ??
        (currentLayouts != null
            ? this.activeSheetIndex.clamp(0, nextLayouts.isEmpty ? 0 : nextLayouts.length - 1)
            : this.activeSheetIndex);

    return PassportPhotoState(
      rawImageBytes: rawImageBytes ?? this.rawImageBytes,
      originalRawImageBytes: clearOriginalRawImageBytes ? null : (originalRawImageBytes ?? this.originalRawImageBytes),
      isBgRemoved: isBgRemoved ?? this.isBgRemoved,
      fileName: fileName ?? this.fileName,
      presetMode: presetMode ?? this.presetMode,
      paperPreset: paperPreset ?? this.paperPreset,
      orientation: orientation ?? this.orientation,
      groups: groups ?? this.groups,
      activeGroupId: activeGroupId ?? this.activeGroupId,
      spacingMm: spacingMm ?? this.spacingMm,
      marginMm: marginMm ?? this.marginMm,
      printJobCopies: printJobCopies ?? this.printJobCopies,
      enhancement: enhancement ?? this.enhancement,
      borderConfig: borderConfig ?? this.borderConfig,
      photoFinish: photoFinish ?? this.photoFinish,
      photoLamination: photoLamination ?? this.photoLamination,
      photoFraming: photoFraming ?? this.photoFraming,
      photoScaling: photoScaling ?? this.photoScaling,
      backgroundColorHex: clearBackgroundColor ? null : (backgroundColorHex ?? this.backgroundColorHex),
      isProcessing: isProcessing ?? this.isProcessing,
      processingStatusText: processingStatusText ?? this.processingStatusText,
      isDetectingFace: isDetectingFace ?? this.isDetectingFace,
      currentLayouts: nextLayouts,
      activeSheetIndex: nextActiveIndex,
      currentLayout: currentLayout ?? this.currentLayout,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

class PassportPhotoNotifier extends StateNotifier<PassportPhotoState> {
  final Ref _ref;
  static const _uuid = Uuid();
  Timer? _draftDebounceTimer;
  int _asyncOperationGeneration = 0;
  final Map<String, Uint8List> _processedImageCache = {};

  PassportPhotoNotifier(this._ref) : super(const PassportPhotoState());

  @override
  void dispose() {
    _draftDebounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedSaveDraft() {
    _draftDebounceTimer?.cancel();
    _draftDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      saveDraft();
    });
  }

  String _buildCacheKey({
    required Uint8List rawBytes,
    required String presetId,
    required CropRectData cropData,
    required EnhancementConfig enhancement,
    required BorderConfig borderConfig,
    required double targetWidthMm,
    required double targetHeightMm,
    required int dpi,
  }) {
    int byteHash = rawBytes.length;
    final sampleLen = math.min(rawBytes.length, 32);
    for (int i = 0; i < sampleLen; i++) {
      byteHash = (byteHash * 31 + rawBytes[i]) & 0x7FFFFFFF;
      byteHash = (byteHash * 31 + rawBytes[rawBytes.length - 1 - i]) & 0x7FFFFFFF;
    }

    return '$byteHash:$presetId:'
        '${cropData.left.toStringAsFixed(4)},${cropData.top.toStringAsFixed(4)},'
        '${cropData.width.toStringAsFixed(4)},${cropData.height.toStringAsFixed(4)},'
        'rot=${cropData.rotationDegrees},fine=${cropData.fineAngleDegrees.toStringAsFixed(2)},quad=${cropData.isQuad}:'
        '${enhancement.brightness.toStringAsFixed(2)},${enhancement.contrast.toStringAsFixed(2)},'
        '${enhancement.saturation.toStringAsFixed(2)},${enhancement.sharpness.toStringAsFixed(2)},'
        '${enhancement.smoothSkin.toStringAsFixed(2)}:'
        '${borderConfig.enabled},${borderConfig.outerBorderMm.toStringAsFixed(2)},${borderConfig.innerBorderMm.toStringAsFixed(2)}:'
        '${targetWidthMm.toStringAsFixed(1)}x${targetHeightMm.toStringAsFixed(1)}@$dpi';
  }

  void _cacheProcessedImage(String key, Uint8List bytes) {
    if (_processedImageCache.length >= 30) {
      _processedImageCache.remove(_processedImageCache.keys.first);
    }
    _processedImageCache[key] = bytes;
  }

  void _pushUndo() {
    final snapshot = PassportPhotoStateSnapshot(
      groups: state.groups.map((g) => g.copyWith()).toList(),
      presetMode: state.presetMode,
      paperPreset: state.paperPreset,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      enhancement: state.enhancement,
      borderConfig: state.borderConfig,
      photoFinish: state.photoFinish,
      photoLamination: state.photoLamination,
      photoFraming: state.photoFraming,
      photoScaling: state.photoScaling,
      backgroundColorHex: state.backgroundColorHex,
      originalRawImageBytes: state.originalRawImageBytes,
      isBgRemoved: state.isBgRemoved,
      activeSheetIndex: state.activeSheetIndex,
    );
    final newUndo = [...state.undoStack, snapshot];
    if (newUndo.length > 20) newUndo.removeAt(0);
    state = state.copyWith(undoStack: newUndo, redoStack: []);
  }

  /// Prewarms presets in a lightweight background microtask (<150ms total)
  void _prewarmPresetCache(Uint8List imageBytes) {
    Future.microtask(() async {
      try {
        final presets = [
          StandardPhotoPresets.stamp,
          StandardPhotoPresets.fourR,
          StandardPhotoPresets.a4,
        ];
        for (final preset in presets) {
          final crop = CropRectData.centeredWithAspectRatio(preset.aspectRatio);
          final cacheKey = _buildCacheKey(
            rawBytes: imageBytes,
            presetId: preset.id,
            cropData: crop,
            enhancement: state.enhancement,
            borderConfig: state.borderConfig,
            targetWidthMm: preset.widthMm,
            targetHeightMm: preset.heightMm,
            dpi: 300,
          );
          if (_processedImageCache.containsKey(cacheKey)) continue;

          final processed = await compute(
            _processGroupPhotoWorker,
            _GroupResizeParams(
              rawBytes: imageBytes,
              cropData: crop,
              targetWidthMm: preset.widthMm,
              targetHeightMm: preset.heightMm,
              enhancement: state.enhancement,
              borderConfig: state.borderConfig,
              dpi: 300,
            ),
          );
          _cacheProcessedImage(cacheKey, processed);
        }
      } catch (e) {
        debugPrint('Prewarm cache error: $e');
      }
    });
  }

  /// Retrieves an already processed photo group from cache in 0ms, or builds it deterministically
  Future<PhotoGroup> _getOrBuildPresetGroup(PhotoPreset preset, int copies) async {
    // 1. If active groups already has this preset, preserve its exact user edits
    final existing = state.groups.where((g) => g.preset.id == preset.id).firstOrNull;
    if (existing != null && existing.processedBytes != null) {
      return existing.copyWith(copiesCount: copies);
    }

    // 2. Canonical crop for this preset
    final crop = CropRectData.centeredWithAspectRatio(preset.aspectRatio);
    final cacheKey = _buildCacheKey(
      rawBytes: state.rawImageBytes!,
      presetId: preset.id,
      cropData: crop,
      enhancement: state.enhancement,
      borderConfig: state.borderConfig,
      targetWidthMm: preset.widthMm,
      targetHeightMm: preset.heightMm,
      dpi: 300,
    );

    Uint8List? processed = _processedImageCache[cacheKey];
    if (processed == null) {
      final gen = _asyncOperationGeneration;
      processed = await compute(
        _processGroupPhotoWorker,
        _GroupResizeParams(
          rawBytes: state.rawImageBytes!,
          cropData: crop,
          targetWidthMm: preset.widthMm,
          targetHeightMm: preset.heightMm,
          enhancement: state.enhancement,
          borderConfig: state.borderConfig,
          dpi: 300,
        ),
      );
      if (gen == _asyncOperationGeneration && processed != null) {
        _cacheProcessedImage(cacheKey, processed);
      }
    }

    return PhotoGroup(
      id: _uuid.v4(),
      name: preset.name,
      preset: preset,
      rawImageBytes: state.rawImageBytes!,
      cropData: crop,
      copiesCount: copies,
      borderConfig: state.borderConfig,
      enhancement: state.enhancement,
      processedBytes: processed,
    );
  }

  /// Loads customer image and creates initial Passport photo layout with auto 8 copies
  Future<void> loadImage(
    Uint8List imageBytes,
    String fileName, {
    bool isRestoringDraft = false,
    CropResult? initialCropResult,
  }) async {
    final generation = ++_asyncOperationGeneration;
    state = state.copyWith(
      rawImageBytes: imageBytes,
      originalRawImageBytes: imageBytes,
      isBgRemoved: false,
      fileName: fileName,
      presetMode: PhotoTypePresetMode.passportOnly,
      isProcessing: true,
      isDetectingFace: initialCropResult == null,
      clearError: true,
    );

    _processedImageCache.clear();

    try {
      final CropRectData crop;
      final EnhancementConfig enhancement;
      final Uint8List processedBytes;

      if (initialCropResult != null) {
        enhancement = initialCropResult.enhancement ?? state.enhancement;
        final normRect = initialCropResult.normalizedRect;
        crop = CropRectData(
          left: normRect.left,
          top: normRect.top,
          width: normRect.width,
          height: normRect.height,
          rotationDegrees: initialCropResult.rotationDegrees.toDouble(),
          fineAngleDegrees: initialCropResult.fineAngleDegrees,
          quadPoints: initialCropResult.quadPoints != null &&
                  initialCropResult.sourceWidth > 0 &&
                  initialCropResult.sourceHeight > 0
              ? initialCropResult.quadPoints!.scale(
                  1.0 / initialCropResult.sourceWidth,
                  1.0 / initialCropResult.sourceHeight,
                )
              : null,
        );

        processedBytes = await compute(
          _processGroupPhotoWorker,
          _GroupResizeParams(
            rawBytes: imageBytes,
            cropData: crop,
            targetWidthMm: StandardPhotoPresets.passport.widthMm,
            targetHeightMm: StandardPhotoPresets.passport.heightMm,
            enhancement: enhancement,
            borderConfig: state.borderConfig,
            dpi: 300,
          ),
        );
      } else {
        final faceRes = await FaceDetectorService.detectAndSuggestCrop(
          imageBytes: imageBytes,
          preset: StandardPhotoPresets.passport,
        );

        crop = faceRes.suggestedCrop;
        enhancement = state.enhancement;

        processedBytes = await ImageProcessor.processPhotoAsync(
          sourceBytes: imageBytes,
          cropData: crop,
          enhancement: enhancement,
          targetWidthMm: StandardPhotoPresets.passport.widthMm,
          targetHeightMm: StandardPhotoPresets.passport.heightMm,
          borderConfig: state.borderConfig,
        );
      }

      if (generation != _asyncOperationGeneration) return;

      final initialPassport = PhotoGroup(
        id: _uuid.v4(),
        name: 'Passport Photo',
        preset: StandardPhotoPresets.passport,
        rawImageBytes: imageBytes,
        cropData: crop,
        copiesCount: 8, // Auto 8 copies for Passport Only
        borderConfig: state.borderConfig,
        enhancement: enhancement,
        processedBytes: processedBytes,
      );

      final cacheKey = _buildCacheKey(
        rawBytes: imageBytes,
        presetId: StandardPhotoPresets.passport.id,
        cropData: crop,
        enhancement: enhancement,
        borderConfig: state.borderConfig,
        targetWidthMm: StandardPhotoPresets.passport.widthMm,
        targetHeightMm: StandardPhotoPresets.passport.heightMm,
        dpi: 300,
      );
      _cacheProcessedImage(cacheKey, processedBytes);

      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: [initialPassport],
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );

      state = state.copyWith(
        groups: [initialPassport],
        presetMode: PhotoTypePresetMode.passportOnly,
        activeGroupId: initialPassport.id,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        activeSheetIndex: 0,
        enhancement: enhancement,
        isProcessing: false,
        isDetectingFace: false,
      );

      // Prewarm background cache so switching modes is always instant (0ms)
      _prewarmPresetCache(imageBytes);

      // Automatically persist draft so image survives app restart / refresh
      if (!isRestoringDraft) {
        await saveDraft();
      }
    } catch (e) {
      debugPrint('Error loading customer photo: $e');
      state = state.copyWith(
        isProcessing: false,
        isDetectingFace: false,
        errorMessage: 'Failed to process image: $e',
      );
    }
  }

  /// Switches between "Passport" (8 copies), "Passport + Stamp" (6 Passport + 4 Stamp), "4R Photo", and "A4 Photo"
  Future<void> setPresetMode(PhotoTypePresetMode mode) async {
    if (!state.hasImage) return;
    if (state.presetMode == mode) return;
    final generation = ++_asyncOperationGeneration;
    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 🔀 setPresetMode: Switching photo mode to ${mode.name}...');
    _pushUndo();

    final modeLabel = mode == PhotoTypePresetMode.passportOnly
        ? 'Passport'
        : (mode == PhotoTypePresetMode.passportPlusStamp
            ? 'Pass+Stamp'
            : (mode == PhotoTypePresetMode.fourRPhoto ? '4R Photo' : 'A4 Photo'));

    // Immediately reflect active mode in UI and mark processing
    state = state.copyWith(
      presetMode: mode,
      isProcessing: true,
      processingStatusText: 'Switching to $modeLabel layout...',
    );

    try {
      if (mode == PhotoTypePresetMode.passportOnly) {
        // 1. Passport Default: 4R, Glossy, Landscape, 8 copies, No Lamination, No Frame (Instant from cache)
        final passportGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.passport, 8);
        if (generation != _asyncOperationGeneration) return;
        final updatedGroups = [passportGroup];
        final targetPaper = StandardPaperPresets.fourR;
        const targetOrientation = PaperOrientation.landscape;
        const targetFinish = PhotoFinish.glossy;
        const targetLamination = PhotoLamination.none;
        const targetFraming = PhotoFraming.none;

        final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
          paperPreset: targetPaper,
          groups: updatedGroups,
          orientation: targetOrientation,
          spacingMm: state.spacingMm,
          marginMm: state.marginMm,
        );

        state = state.copyWith(
          presetMode: mode,
          paperPreset: targetPaper,
          orientation: targetOrientation,
          photoFinish: targetFinish,
          photoLamination: targetLamination,
          photoFraming: targetFraming,
          groups: updatedGroups,
          activeGroupId: passportGroup.id,
          currentLayouts: layouts,
          currentLayout: layouts.firstOrNull,
          activeSheetIndex: 0,
          isProcessing: false,
          clearError: true,
        );
      } else if (mode == PhotoTypePresetMode.fourRPhoto) {
        // 3. 4R Photo Default: 4R, Matte, Portrait, 1 copy, No Lamination, No Frame (Instant from cache)
        final fourRGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.fourR, 1);
        if (generation != _asyncOperationGeneration) return;
        final updatedGroups = [fourRGroup];
        final targetPaper = StandardPaperPresets.fourR;
        const targetOrientation = PaperOrientation.portrait;
        const targetFinish = PhotoFinish.matte;
        const targetLamination = PhotoLamination.none;
        const targetFraming = PhotoFraming.none;

        final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
          paperPreset: targetPaper,
          groups: updatedGroups,
          orientation: targetOrientation,
          spacingMm: 0.0,
          marginMm: state.marginMm,
          scaling: state.photoScaling,
        );

        state = state.copyWith(
          presetMode: mode,
          paperPreset: targetPaper,
          orientation: targetOrientation,
          photoFinish: targetFinish,
          photoLamination: targetLamination,
          photoFraming: targetFraming,
          groups: updatedGroups,
          activeGroupId: fourRGroup.id,
          currentLayouts: layouts,
          currentLayout: layouts.firstOrNull,
          activeSheetIndex: 0,
          isProcessing: false,
          clearError: true,
        );
      } else if (mode == PhotoTypePresetMode.a4Photo) {
        // 4. A4 Photo Default: A4, Matte, Portrait, 1 copy, No Lamination, No Frame (Instant from cache)
        final a4Group = await _getOrBuildPresetGroup(StandardPhotoPresets.a4, 1);
        if (generation != _asyncOperationGeneration) return;
        final updatedGroups = [a4Group];
        final targetPaper = StandardPaperPresets.a4;
        const targetOrientation = PaperOrientation.portrait;
        const targetFinish = PhotoFinish.matte;
        const targetLamination = PhotoLamination.none;
        const targetFraming = PhotoFraming.none;

        final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
          paperPreset: targetPaper,
          groups: updatedGroups,
          orientation: targetOrientation,
          spacingMm: 0.0,
          marginMm: state.marginMm,
          scaling: state.photoScaling,
        );

        state = state.copyWith(
          presetMode: mode,
          paperPreset: targetPaper,
          orientation: targetOrientation,
          photoFinish: targetFinish,
          photoLamination: targetLamination,
          photoFraming: targetFraming,
          groups: updatedGroups,
          activeGroupId: a4Group.id,
          currentLayouts: layouts,
          currentLayout: layouts.firstOrNull,
          activeSheetIndex: 0,
          isProcessing: false,
          clearError: true,
        );
      } else {
        // 2. Pass+Stamp Default: 6 Passport copies + 4 Stamp copies on 4R Portrait Glossy (Instant from cache)
        final passportGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.passport, 6);
        final stampGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.stamp, 4);
        if (generation != _asyncOperationGeneration) return;

        final updatedGroups = [passportGroup, stampGroup];
        final targetPaper = StandardPaperPresets.fourR;
        const targetOrientation = PaperOrientation.portrait;
        const targetFinish = PhotoFinish.glossy;
        const targetLamination = PhotoLamination.none;
        const targetFraming = PhotoFraming.none;

        final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
          paperPreset: targetPaper,
          groups: updatedGroups,
          orientation: targetOrientation,
          spacingMm: state.spacingMm,
          marginMm: state.marginMm,
        );

        state = state.copyWith(
          presetMode: mode,
          paperPreset: targetPaper,
          orientation: targetOrientation,
          photoFinish: targetFinish,
          photoLamination: targetLamination,
          photoFraming: targetFraming,
          groups: updatedGroups,
          activeGroupId: passportGroup.id,
          currentLayouts: layouts,
          currentLayout: layouts.firstOrNull,
          activeSheetIndex: 0,
          isProcessing: false,
          processingStatusText: '',
          clearError: true,
        );
      }

      _debouncedSaveDraft();
      debugPrint('[FastPrint Photo] ✅ setPresetMode: Switched to $modeLabel (took ${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('[FastPrint Photo] ❌ Error switching photo type mode: $e');
      state = state.copyWith(
        isProcessing: false,
        processingStatusText: '',
        errorMessage: 'Failed to switch mode: $e',
      );
    }
  }

  /// Adds an additional photo group (e.g. Stamp Photo, Visa, etc.) on the same 4R sheet
  Future<void> addPhotoGroup(PhotoPreset preset, {Uint8List? customBytes}) async {
    if (!state.hasImage) return;
    final generation = ++_asyncOperationGeneration;
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final imageBytes = customBytes ?? state.rawImageBytes!;
      final crop = CropRectData.centeredWithAspectRatio(preset.aspectRatio);
      final defaultCopies = preset.id == 'stamp' ? 4 : (preset.id == 'passport' ? 8 : 4);

      final processedBytes = await ImageProcessor.processPhotoAsync(
        sourceBytes: imageBytes,
        cropData: crop,
        enhancement: state.enhancement,
        targetWidthMm: preset.widthMm,
        targetHeightMm: preset.heightMm,
        borderConfig: state.borderConfig,
      );

      if (generation != _asyncOperationGeneration) return;

      final cacheKey = _buildCacheKey(
        rawBytes: imageBytes,
        presetId: preset.id,
        cropData: crop,
        enhancement: state.enhancement,
        borderConfig: state.borderConfig,
        targetWidthMm: preset.widthMm,
        targetHeightMm: preset.heightMm,
        dpi: 300,
      );
      _cacheProcessedImage(cacheKey, processedBytes);

      final newGroup = PhotoGroup(
        id: _uuid.v4(),
        name: preset.name,
        preset: preset,
        rawImageBytes: imageBytes,
        cropData: crop,
        copiesCount: defaultCopies,
        borderConfig: state.borderConfig,
        enhancement: state.enhancement,
        processedBytes: processedBytes,
      );

      final updatedGroups = [...state.groups, newGroup];

      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: updatedGroups,
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );

      state = state.copyWith(
        groups: updatedGroups,
        activeGroupId: newGroup.id,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        isProcessing: false,
      );
    } catch (e) {
      debugPrint('Error adding photo group: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to add photo group: $e');
    }
  }

  /// Adds a new person's photo to the workspace with their own cropped image and copies
  Future<void> addPersonPhoto({
    required Uint8List bytes,
    required String fileName,
    required CropResult cropResult,
    PhotoPreset? preset,
    int copies = 4,
  }) async {
    final generation = ++_asyncOperationGeneration;
    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 👤 addPersonPhoto: Adding person photo "$fileName"...');
    _pushUndo();
    state = state.copyWith(
      isProcessing: true,
      processingStatusText: 'Processing person photo ($fileName)...',
      clearError: true,
    );

    try {
      final activePreset = preset ??
          (state.groups.isNotEmpty
              ? state.groups.first.preset
              : StandardPhotoPresets.passport);

      final norm = cropResult.normalizedRect;
      final cropData = CropRectData(
        left: norm.left,
        top: norm.top,
        width: norm.width,
        height: norm.height,
        rotationDegrees: cropResult.rotationDegrees.toDouble(),
        fineAngleDegrees: cropResult.fineAngleDegrees,
        quadPoints: cropResult.quadPoints != null && cropResult.sourceWidth > 0 && cropResult.sourceHeight > 0
            ? cropResult.quadPoints!.scale(1.0 / cropResult.sourceWidth, 1.0 / cropResult.sourceHeight)
            : null,
      );

      final resizeSw = Stopwatch()..start();
      final processed = await compute(
        _processGroupPhotoWorker,
        _GroupResizeParams(
          rawBytes: bytes,
          cropData: cropData,
          targetWidthMm: activePreset.widthMm,
          targetHeightMm: activePreset.heightMm,
          enhancement: cropResult.enhancement ?? state.enhancement,
          borderConfig: state.borderConfig,
          dpi: 300,
        ),
      );
      debugPrint('[FastPrint Photo] 🖼️ addPersonPhoto: Image resized and enhanced in ${resizeSw.elapsedMilliseconds}ms');

      if (generation != _asyncOperationGeneration) return;

      final cacheKey = _buildCacheKey(
        rawBytes: bytes,
        presetId: activePreset.id,
        cropData: cropData,
        enhancement: cropResult.enhancement ?? state.enhancement,
        borderConfig: state.borderConfig,
        targetWidthMm: activePreset.widthMm,
        targetHeightMm: activePreset.heightMm,
        dpi: 300,
      );
      _cacheProcessedImage(cacheKey, processed);

      int personNumber = state.groups.length + 1;
      final existingNumbers = state.groups.map((g) {
        final match = RegExp(r'Person\s+(\d+)').firstMatch(g.name);
        return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      }).toSet();
      while (existingNumbers.contains(personNumber)) {
        personNumber++;
      }

      final newGroup = PhotoGroup(
        id: _uuid.v4(),
        name: 'Person $personNumber (${p.basename(fileName)})',
        preset: activePreset,
        rawImageBytes: bytes,
        cropData: cropData,
        copiesCount: copies,
        borderConfig: state.borderConfig,
        enhancement: cropResult.enhancement ?? state.enhancement,
        processedBytes: processed,
      );

      final updatedGroups = [...state.groups, newGroup];

      final layoutSw = Stopwatch()..start();
      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: updatedGroups,
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );
      debugPrint('[FastPrint Photo] 📐 addPersonPhoto: Multi-sheet layout generated in ${layoutSw.elapsedMilliseconds}ms');

      state = state.copyWith(
        groups: updatedGroups,
        activeGroupId: newGroup.id,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        isProcessing: false,
        processingStatusText: '',
      );

      _debouncedSaveDraft();
      debugPrint('[FastPrint Photo] ✅ addPersonPhoto: Completed for "$fileName" with $copies copies (total: ${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('[FastPrint Photo] ❌ Error adding person photo: $e');
      state = state.copyWith(
        isProcessing: false,
        processingStatusText: '',
        errorMessage: 'Failed to add person photo: $e',
      );
    }
  }

  /// Removes a photo group from the workspace
  void removePhotoGroup(String groupId) {
    if (state.groups.length <= 1) {
      closeCurrentProject();
      return;
    }
    _pushUndo();

    final updatedGroups = state.groups.where((g) => g.id != groupId).toList();
    final newActiveId = updatedGroups.isNotEmpty ? updatedGroups.first.id : null;

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: state.paperPreset,
      groups: updatedGroups,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      scaling: state.photoScaling,
    );

    final newMode = updatedGroups.length == 1 && updatedGroups.first.preset.id == 'passport'
        ? PhotoTypePresetMode.passportOnly
        : PhotoTypePresetMode.passportPlusStamp;

    state = state.copyWith(
      groups: updatedGroups,
      presetMode: newMode,
      activeGroupId: newActiveId,
      currentLayouts: layouts,
      currentLayout: layouts.firstOrNull,
      activeSheetIndex: 0,
    );
  }

  /// Selects the active group for editing
  void setActiveGroup(String groupId) {
    state = state.copyWith(activeGroupId: groupId);
  }

  /// Sheet pagination controls for multi-sheet viewing
  void setActiveSheetIndex(int index) {
    if (index >= 0 && index < state.currentLayouts.length) {
      state = state.copyWith(activeSheetIndex: index);
    }
  }

  void nextSheet() {
    if (state.activeSheetIndex < state.currentLayouts.length - 1) {
      state = state.copyWith(activeSheetIndex: state.activeSheetIndex + 1);
    }
  }

  void prevSheet() {
    if (state.activeSheetIndex > 0) {
      state = state.copyWith(activeSheetIndex: state.activeSheetIndex - 1);
    }
  }

  /// Updates copies count for a specific group
  void updateGroupCopies(String groupId, int copies) {
    final clamped = copies.clamp(1, 100);
    final current = state.groups.where((g) => g.id == groupId).firstOrNull?.copiesCount;
    if (current == clamped) return;

    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 🔢 updateGroupCopies: Copies changed to $clamped for group $groupId...');
    _pushUndo();
    final updatedGroups = state.groups.map((g) {
      if (g.id == groupId) {
        return g.copyWith(copiesCount: clamped);
      }
      return g;
    }).toList();

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: state.paperPreset,
      groups: updatedGroups,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      scaling: state.photoScaling,
    );

    state = state.copyWith(
      groups: updatedGroups,
      currentLayouts: layouts,
      currentLayout: layouts.firstOrNull,
      activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.length - 1),
    );
    debugPrint('[FastPrint Photo] ⚡ updateGroupCopies: Layout updated to $clamped copies across ${layouts.length} sheet(s) (took ${sw.elapsedMilliseconds}ms)');
  }

  /// Applies definitive CropResult from CropEditorModal for a specific group
  Future<void> applyGroupCropResult(String groupId, CropResult cropResult) async {
    final generation = ++_asyncOperationGeneration;
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final targetGroup = state.groups.firstWhere((g) => g.id == groupId);
      final activeEnhancement = cropResult.enhancement ?? state.enhancement;
      final rawBytes = targetGroup.rawImageBytes ?? state.rawImageBytes!;

      final normRect = cropResult.normalizedRect;
      final cropData = CropRectData(
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

      final processedBytes = await compute(
        _processGroupPhotoWorker,
        _GroupResizeParams(
          rawBytes: rawBytes,
          cropData: cropData,
          targetWidthMm: targetGroup.widthMm,
          targetHeightMm: targetGroup.heightMm,
          enhancement: activeEnhancement,
          borderConfig: state.borderConfig,
          dpi: 300,
        ),
      );

      if (generation != _asyncOperationGeneration) return;

      final cacheKey = _buildCacheKey(
        rawBytes: rawBytes,
        presetId: targetGroup.preset.id,
        cropData: cropData,
        enhancement: activeEnhancement,
        borderConfig: state.borderConfig,
        targetWidthMm: targetGroup.widthMm,
        targetHeightMm: targetGroup.heightMm,
        dpi: 300,
      );
      _cacheProcessedImage(cacheKey, processedBytes);

      final updatedGroups = state.groups.map((g) {
        if (g.id == groupId) {
          final updated = g.copyWith(
            cropData: cropData,
            enhancement: activeEnhancement,
            processedBytes: processedBytes,
          );
          return updated;
        }
        return g;
      }).toList();

      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: updatedGroups,
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );

      state = state.copyWith(
        groups: updatedGroups,
        enhancement: activeEnhancement,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.length - 1),
        isProcessing: false,
      );
      _debouncedSaveDraft();

      // Prewarm background cache for other photo presets with new crop/enhancement
      _prewarmPresetCache(rawBytes);
    } catch (e) {
      debugPrint('Error applying group crop: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to apply crop: $e');
    }
  }

  /// Updates global image enhancement (Brightness, Contrast, Sharpness)
  Future<void> updateEnhancements({
    double? brightness,
    double? contrast,
    double? sharpness,
  }) async {
    _pushUndo();
    final newEnh = state.enhancement.copyWith(
      brightness: brightness,
      contrast: contrast,
      sharpness: sharpness,
    );

    state = state.copyWith(enhancement: newEnh);
    await _reprocessAllGroups();
  }

  /// Resets all image enhancements back to 0%
  Future<void> resetEnhancements() async {
    _pushUndo();
    state = state.copyWith(enhancement: const EnhancementConfig());
    await _reprocessAllGroups();
  }

  /// Updates global border settings (Outer white margin, Inner black stroke)
  Future<void> updateBorder({
    double? outerBorderMm,
    double? innerBorderMm,
    bool? enabled,
  }) async {
    _pushUndo();
    final newBorder = state.borderConfig.copyWith(
      outerBorderMm: outerBorderMm,
      innerBorderMm: innerBorderMm,
      enabled: enabled,
    );

    state = state.copyWith(borderConfig: newBorder);
    await _reprocessAllGroups();
  }

  Future<void> _reprocessAllGroups() async {
    if (!state.hasImage) return;
    final generation = ++_asyncOperationGeneration;
    _processedImageCache.clear();

    final updatedGroups = <PhotoGroup>[];
    for (final group in state.groups) {
      final rawBytes = group.rawImageBytes ?? state.rawImageBytes!;
      final processedBytes = await ImageProcessor.processPhotoAsync(
        sourceBytes: rawBytes,
        cropData: group.cropData,
        enhancement: state.enhancement,
        targetWidthMm: group.widthMm,
        targetHeightMm: group.heightMm,
        borderConfig: state.borderConfig,
      );

      if (generation != _asyncOperationGeneration) return;

      final cacheKey = _buildCacheKey(
        rawBytes: rawBytes,
        presetId: group.preset.id,
        cropData: group.cropData,
        enhancement: state.enhancement,
        borderConfig: state.borderConfig,
        targetWidthMm: group.widthMm,
        targetHeightMm: group.heightMm,
        dpi: 300,
      );
      _cacheProcessedImage(cacheKey, processedBytes);

      updatedGroups.add(
        group.copyWith(
          enhancement: state.enhancement,
          borderConfig: state.borderConfig,
          processedBytes: processedBytes,
        ),
      );
    }

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: state.paperPreset,
      groups: updatedGroups,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      scaling: state.photoScaling,
    );

    state = state.copyWith(
      groups: updatedGroups,
      currentLayouts: layouts,
      currentLayout: layouts.firstOrNull,
      activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.isEmpty ? 0 : layouts.length - 1),
    );
  }

  void setSpacingMm(double spacing) {
    _pushUndo();
    state = state.copyWith(spacingMm: spacing.clamp(0.0, 15.0));
    _recalculateLayout();
  }

  void setMarginMm(double margin) {
    _pushUndo();
    state = state.copyWith(marginMm: margin.clamp(0.0, 20.0));
    _recalculateLayout();
  }

  void setPrintJobCopies(int copies) {
    state = state.copyWith(printJobCopies: copies.clamp(1, 100));
  }

  void setPaperPreset(PaperPreset paper) {
    if (state.paperPreset.id == paper.id) return;
    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 🚀 setPaperPreset: Switching paper from ${state.paperPreset.name} to ${paper.name}...');
    state = state.copyWith(
      paperPreset: paper,
      isProcessing: true,
      processingStatusText: 'Switching paper to ${paper.name}...',
    );
    _recalculateLayout();
    state = state.copyWith(isProcessing: false, processingStatusText: '');
    debugPrint('[FastPrint Photo] ✅ setPaperPreset: Switched to ${paper.name} (took ${sw.elapsedMilliseconds}ms)');
  }

  void setOrientation(PaperOrientation orientation) {
    if (state.orientation == orientation) return;
    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 🚀 setOrientation: Changing orientation to ${orientation.displayName}...');
    state = state.copyWith(
      orientation: orientation,
      isProcessing: true,
      processingStatusText: 'Rotating sheet to ${orientation.displayName}...',
    );
    _recalculateLayout();
    state = state.copyWith(isProcessing: false, processingStatusText: '');
    debugPrint('[FastPrint Photo] ✅ setOrientation: Changed to ${orientation.displayName} (took ${sw.elapsedMilliseconds}ms)');
  }

  void _recalculateLayout() {
    if (state.groups.isEmpty) return;
    final sw = Stopwatch()..start();
    debugPrint('[FastPrint Photo] 📐 Recalculating layout for ${state.groups.length} photo group(s) on ${state.paperPreset.name} (${state.orientation.displayName})...');

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: state.paperPreset,
      groups: state.groups,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      scaling: state.photoScaling,
    );

    state = state.copyWith(
      currentLayouts: layouts,
      currentLayout: layouts.firstOrNull,
      activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.length - 1),
    );
    _debouncedSaveDraft();
    debugPrint('[FastPrint Photo] ⚡ Layout complete: ${layouts.length} sheet(s) generated with ${state.totalCopiesCount} photos (took ${sw.elapsedMilliseconds}ms)');
  }

  // Backward-compatible delegators
  Future<void> applyCropResult(CropResult cropResult) async {
    if (state.activeGroup != null) {
      await applyGroupCropResult(state.activeGroup!.id, cropResult);
    }
  }

  void undo() {
    if (!state.canUndo) return;
    final last = state.undoStack.last;
    final newUndo = List<PassportPhotoStateSnapshot>.from(state.undoStack)..removeLast();

    final currentSnapshot = PassportPhotoStateSnapshot(
      groups: state.groups.map((g) => g.copyWith()).toList(),
      presetMode: state.presetMode,
      paperPreset: state.paperPreset,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      enhancement: state.enhancement,
      borderConfig: state.borderConfig,
      photoFinish: state.photoFinish,
      photoLamination: state.photoLamination,
      photoFraming: state.photoFraming,
      photoScaling: state.photoScaling,
      backgroundColorHex: state.backgroundColorHex,
      originalRawImageBytes: state.originalRawImageBytes,
      isBgRemoved: state.isBgRemoved,
      activeSheetIndex: state.activeSheetIndex,
    );
    final newRedo = [...state.redoStack, currentSnapshot];

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: last.paperPreset,
      groups: last.groups,
      orientation: last.orientation,
      spacingMm: last.spacingMm,
      marginMm: last.marginMm,
      scaling: last.photoScaling,
    );

    final restoredActiveIndex = last.activeSheetIndex.clamp(0, layouts.isEmpty ? 0 : layouts.length - 1);

    state = state.copyWith(
      undoStack: newUndo,
      redoStack: newRedo,
      groups: last.groups,
      presetMode: last.presetMode,
      paperPreset: last.paperPreset,
      orientation: last.orientation,
      spacingMm: last.spacingMm,
      marginMm: last.marginMm,
      printJobCopies: last.printJobCopies,
      enhancement: last.enhancement,
      borderConfig: last.borderConfig,
      photoFinish: last.photoFinish,
      photoLamination: last.photoLamination,
      photoFraming: last.photoFraming,
      photoScaling: last.photoScaling,
      backgroundColorHex: last.backgroundColorHex,
      clearBackgroundColor: last.backgroundColorHex == null,
      originalRawImageBytes: last.originalRawImageBytes,
      isBgRemoved: last.isBgRemoved,
      currentLayouts: layouts,
      currentLayout: layouts.isNotEmpty ? layouts[restoredActiveIndex] : null,
      activeSheetIndex: restoredActiveIndex,
    );
    _debouncedSaveDraft();
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    final newRedo = List<PassportPhotoStateSnapshot>.from(state.redoStack)..removeLast();

    final currentSnapshot = PassportPhotoStateSnapshot(
      groups: state.groups.map((g) => g.copyWith()).toList(),
      presetMode: state.presetMode,
      paperPreset: state.paperPreset,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      printJobCopies: state.printJobCopies,
      enhancement: state.enhancement,
      borderConfig: state.borderConfig,
      photoFinish: state.photoFinish,
      photoLamination: state.photoLamination,
      photoFraming: state.photoFraming,
      photoScaling: state.photoScaling,
      backgroundColorHex: state.backgroundColorHex,
      originalRawImageBytes: state.originalRawImageBytes,
      isBgRemoved: state.isBgRemoved,
      activeSheetIndex: state.activeSheetIndex,
    );
    final newUndo = [...state.undoStack, currentSnapshot];

    final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: next.paperPreset,
      groups: next.groups,
      orientation: next.orientation,
      spacingMm: next.spacingMm,
      marginMm: next.marginMm,
      scaling: next.photoScaling,
    );

    final restoredActiveIndex = next.activeSheetIndex.clamp(0, layouts.isEmpty ? 0 : layouts.length - 1);

    state = state.copyWith(
      undoStack: newUndo,
      redoStack: newRedo,
      groups: next.groups,
      presetMode: next.presetMode,
      paperPreset: next.paperPreset,
      orientation: next.orientation,
      spacingMm: next.spacingMm,
      marginMm: next.marginMm,
      printJobCopies: next.printJobCopies,
      enhancement: next.enhancement,
      borderConfig: next.borderConfig,
      photoFinish: next.photoFinish,
      photoLamination: next.photoLamination,
      photoFraming: next.photoFraming,
      photoScaling: next.photoScaling,
      backgroundColorHex: next.backgroundColorHex,
      clearBackgroundColor: next.backgroundColorHex == null,
      originalRawImageBytes: next.originalRawImageBytes,
      isBgRemoved: next.isBgRemoved,
      currentLayouts: layouts,
      currentLayout: layouts.isNotEmpty ? layouts[restoredActiveIndex] : null,
      activeSheetIndex: restoredActiveIndex,
    );
    _debouncedSaveDraft();
  }

  void setPhotoFinish(PhotoFinish finish) {
    _pushUndo();
    state = state.copyWith(photoFinish: finish);
    _debouncedSaveDraft();
  }

  void setPhotoLamination(PhotoLamination lamination) {
    _pushUndo();
    state = state.copyWith(photoLamination: lamination);
    _debouncedSaveDraft();
  }

  void setPhotoFraming(PhotoFraming framing) {
    _pushUndo();
    state = state.copyWith(photoFraming: framing);
    _debouncedSaveDraft();
  }

  void setPhotoScaling(PhotoScalingMode scaling) {
    _pushUndo();
    state = state.copyWith(photoScaling: scaling);
    _recalculateLayout();
  }

  /// Removes background and optionally replaces it with a background tint color
  Future<void> removeBackground({
    String? replaceColorHex,
    double tolerance = 0.22,
    int featherRadius = 2,
  }) async {
    final baseImage = state.originalRawImageBytes ?? state.rawImageBytes;
    if (baseImage == null || baseImage.isEmpty) return;

    final generation = ++_asyncOperationGeneration;
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      int? replColorValue;
      if (replaceColorHex != null && replaceColorHex.toLowerCase() != 'transparent') {
        final hexClean = replaceColorHex.replaceAll('#', '');
        if (hexClean.length == 6) {
          replColorValue = int.tryParse('FF$hexClean', radix: 16);
        } else if (hexClean.length == 8) {
          replColorValue = int.tryParse(hexClean, radix: 16);
        }
      }

      final cutoutBytes = await BackgroundRemoverService.removeBackgroundAsync(
        sourceBytes: baseImage,
        config: BackgroundRemoverConfig(
          tolerance: tolerance,
          featherRadius: featherRadius,
          replacementColorValue: replColorValue,
        ),
      );

      if (generation != _asyncOperationGeneration) return;
      _processedImageCache.clear();

      final updatedGroups = <PhotoGroup>[];
      for (final g in state.groups) {
        final activeEnh = g.enhancement.isDefault ? state.enhancement : g.enhancement;
        final processed = await ImageProcessor.processPhotoAsync(
          sourceBytes: cutoutBytes,
          cropData: g.cropData,
          enhancement: activeEnh,
          targetWidthMm: g.widthMm,
          targetHeightMm: g.heightMm,
          borderConfig: state.borderConfig,
        );

        if (generation != _asyncOperationGeneration) return;

        final cacheKey = _buildCacheKey(
          rawBytes: cutoutBytes,
          presetId: g.preset.id,
          cropData: g.cropData,
          enhancement: activeEnh,
          borderConfig: state.borderConfig,
          targetWidthMm: g.widthMm,
          targetHeightMm: g.heightMm,
          dpi: 300,
        );
        _cacheProcessedImage(cacheKey, processed);

        final updated = g.copyWith(
          rawImageBytes: cutoutBytes,
          processedBytes: processed,
        );
        updatedGroups.add(updated);
      }

      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: updatedGroups,
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );

      state = state.copyWith(
        rawImageBytes: cutoutBytes,
        originalRawImageBytes: state.originalRawImageBytes ?? baseImage,
        isBgRemoved: true,
        backgroundColorHex: replaceColorHex,
        clearBackgroundColor: replaceColorHex == null,
        groups: updatedGroups,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.isEmpty ? 0 : layouts.length - 1),
        isProcessing: false,
      );
      _debouncedSaveDraft();
    } catch (e) {
      debugPrint('Error removing background: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to remove background: $e',
      );
    }
  }

  /// Restores original untouched photo background
  Future<void> restoreOriginalBackground() async {
    final original = state.originalRawImageBytes;
    if (original == null || !state.isBgRemoved) return;

    final generation = ++_asyncOperationGeneration;
    _pushUndo();
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      _processedImageCache.clear();
      final updatedGroups = <PhotoGroup>[];
      for (final g in state.groups) {
        final activeEnh = g.enhancement.isDefault ? state.enhancement : g.enhancement;
        final processed = await ImageProcessor.processPhotoAsync(
          sourceBytes: original,
          cropData: g.cropData,
          enhancement: activeEnh,
          targetWidthMm: g.widthMm,
          targetHeightMm: g.heightMm,
          borderConfig: state.borderConfig,
        );

        if (generation != _asyncOperationGeneration) return;

        final cacheKey = _buildCacheKey(
          rawBytes: original,
          presetId: g.preset.id,
          cropData: g.cropData,
          enhancement: activeEnh,
          borderConfig: state.borderConfig,
          targetWidthMm: g.widthMm,
          targetHeightMm: g.heightMm,
          dpi: 300,
        );
        _cacheProcessedImage(cacheKey, processed);

        final updated = g.copyWith(
          rawImageBytes: original,
          processedBytes: processed,
        );
        updatedGroups.add(updated);
      }

      final layouts = LayoutEngine.calculateMultiPhotoLayoutPages(
        paperPreset: state.paperPreset,
        groups: updatedGroups,
        orientation: state.orientation,
        spacingMm: state.spacingMm,
        marginMm: state.marginMm,
        scaling: state.photoScaling,
      );

      state = state.copyWith(
        rawImageBytes: original,
        isBgRemoved: false,
        clearBackgroundColor: true,
        groups: updatedGroups,
        currentLayouts: layouts,
        currentLayout: layouts.firstOrNull,
        activeSheetIndex: state.activeSheetIndex.clamp(0, layouts.isEmpty ? 0 : layouts.length - 1),
        isProcessing: false,
      );
      _debouncedSaveDraft();
    } catch (e) {
      debugPrint('Error restoring background: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to restore background: $e',
      );
    }
  }

  void setBackgroundColor(String? colorHex) {
    _pushUndo();
    if (colorHex == null) {
      state = state.copyWith(clearBackgroundColor: true);
    } else {
      state = state.copyWith(backgroundColorHex: colorHex);
    }
    _debouncedSaveDraft();
  }

  Future<void> updateSmoothSkin(double val) async {
    _pushUndo();
    state = state.copyWith(
      enhancement: state.enhancement.copyWith(smoothSkin: val),
    );
    await _reprocessAllGroups();
  }

  Future<List<PrintLayout>> _buildPrintReadyLayouts() async {
    final layouts = state.currentLayouts.isNotEmpty
        ? state.currentLayouts
        : (state.currentLayout != null ? [state.currentLayout!] : <PrintLayout>[]);
    if (layouts.isEmpty) return layouts;

    final hasLargePhoto = state.groups.any((g) => math.max(g.widthMm, g.heightMm) > 100);
    if (!hasLargePhoto) return layouts;

    final highResGroups = <PhotoGroup>[];
    for (final g in state.groups) {
      if (math.max(g.widthMm, g.heightMm) > 100) {
        final highResBytes = await ImageProcessor.processPhotoAsync(
          sourceBytes: g.rawImageBytes ?? state.rawImageBytes!,
          cropData: g.cropData,
          enhancement: g.enhancement.isDefault ? state.enhancement : g.enhancement,
          targetWidthMm: g.widthMm,
          targetHeightMm: g.heightMm,
          borderConfig: state.borderConfig,
          dpi: 300,
        );
        highResGroups.add(g.copyWith(processedBytes: highResBytes));
      } else {
        highResGroups.add(g);
      }
    }

    return LayoutEngine.calculateMultiPhotoLayoutPages(
      paperPreset: state.paperPreset,
      groups: highResGroups,
      orientation: state.orientation,
      spacingMm: state.spacingMm,
      marginMm: state.marginMm,
      scaling: state.photoScaling,
      dpi: 300,
    );
  }

  Future<bool> printDocument({Printer? targetPrinter}) async {
    final layouts = await _buildPrintReadyLayouts();
    if (layouts.isEmpty || layouts.every((l) => l.items.isEmpty)) return false;

    final printerService = _ref.read(printerServiceProvider);
    final success = layouts.length > 1
        ? await printerService.printMultiLayout(
            layouts,
            printer: targetPrinter,
            jobName: 'Photo Print (${layouts.length} Sheets)',
          )
        : await printerService.printLayout(
            layouts.first,
            printer: targetPrinter,
            jobName: 'Photo Print (${layouts.first.paperPreset.name} Sheet)',
          );

    final summary = state.groups.map((g) => '${g.name}: ${g.copiesCount}').join(', ');
    final totalPlaced = layouts.fold<int>(0, (sum, l) => sum + l.items.length);

    await _ref.read(historyProvider.notifier).addRecord(
          PrintHistoryItem(
            id: _uuid.v4(),
            timestamp: DateTime.now(),
            serviceName: 'Passport / Photo Print',
            paperName: layouts.first.paperPreset.name,
            copiesCount: totalPlaced * state.printJobCopies,
            printerName: targetPrinter?.name ?? 'System Print Dialog',
            status: success ? 'Printed' : 'Print Submitted',
            dimensionsSummary: '$summary ($totalPlaced photos across ${layouts.length} sheets)',
            sellingPrice: state.calculatedSellingPrice,
            materialCost: state.calculatedMaterialCost,
            inkCost: state.calculatedInkCost,
            profit: state.calculatedProfit,
            paymentStatus: 'Paid',
            paymentMethod: 'Cash',
          ),
        );

    return success;
  }

  Future<bool> exportPdf() async {
    final layouts = await _buildPrintReadyLayouts();
    if (layouts.isEmpty || layouts.every((l) => l.items.isEmpty)) return false;

    final printerService = _ref.read(printerServiceProvider);
    final fileName = layouts.length > 1
        ? 'Photo_Print_${layouts.length}_Sheets'
        : 'Photo_Print_${layouts.first.paperPreset.name}_Sheet';
    final success = layouts.length > 1
        ? await printerService.exportMultiLayoutPdf(layouts, fileName)
        : await printerService.exportPdf(layouts.first, fileName);

    return success;
  }

  /// Saves project state into local draft storage so work continues even after PC shutdown
  Future<void> saveDraft() async {
    final raw = state.rawImageBytes;
    final fName = state.fileName;
    if (raw == null || fName == null || raw.isEmpty) return;

    final metadata = {
      'presetModeName': state.presetMode.name,
      'paperPresetName': state.paperPreset.name,
      'paperPresetId': state.paperPreset.id,
      'orientationName': state.orientation.name,
      'spacingMm': state.spacingMm,
      'marginMm': state.marginMm,
      'printJobCopies': state.printJobCopies,
      'photoFinishName': state.photoFinish.name,
      'photoLaminationName': state.photoLamination.name,
      'photoFramingName': state.photoFraming.name,
      'photoScalingName': state.photoScaling.name,
      'backgroundColorHex': state.backgroundColorHex,
      'outerBorderMm': state.borderConfig.outerBorderMm,
      'innerBorderMm': state.borderConfig.innerBorderMm,
      'borderEnabled': state.borderConfig.enabled,
      'enhancement': state.enhancement.toJson(),
    };

    await DraftStorageService.savePhotoDraft(
      bytes: raw,
      fileName: fName,
      metadata: metadata,
    );
  }

  /// Immediately restores full project from saved draft or .fps file with ZERO lag and NO intermediate 4R flash
  Future<void> restoreProjectFromData({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    _processedImageCache.clear();

    final pmName = metadata['presetModeName'] as String?;
    PhotoTypePresetMode mode = PhotoTypePresetMode.passportOnly;
    if (pmName != null) {
      final found = PhotoTypePresetMode.values.where((m) => m.name == pmName).firstOrNull;
      if (found != null) mode = found;
    }

    final pId = metadata['paperPresetId'] as String? ?? metadata['paperPresetName'] as String?;
    PaperPreset paper = mode == PhotoTypePresetMode.a4Photo ? StandardPaperPresets.a4 : StandardPaperPresets.fourR;
    if (pId != null) {
      final found = StandardPaperPresets.all.where((p) => p.id == pId || p.name == pId).firstOrNull;
      if (found != null) paper = found;
    }

    PaperOrientation orientation = PaperOrientation.portrait;
    if (metadata['orientationName'] == 'landscape') {
      orientation = PaperOrientation.landscape;
    } else if (metadata['orientationName'] == 'portrait') {
      orientation = PaperOrientation.portrait;
    } else if (mode == PhotoTypePresetMode.passportOnly) {
      orientation = PaperOrientation.landscape;
    }

    PhotoFinish finish = (mode == PhotoTypePresetMode.fourRPhoto || mode == PhotoTypePresetMode.a4Photo)
        ? PhotoFinish.matte
        : PhotoFinish.glossy;
    final fnName = metadata['photoFinishName'] as String?;
    if (fnName != null) {
      final found = PhotoFinish.values.where((f) => f.name == fnName).firstOrNull;
      if (found != null) finish = found;
    }

    PhotoLamination lamination = PhotoLamination.none;
    final lamName = metadata['photoLaminationName'] as String?;
    if (lamName != null) {
      final found = PhotoLamination.values.where((l) => l.name == lamName).firstOrNull;
      if (found != null) lamination = found;
    }

    PhotoFraming framing = PhotoFraming.none;
    final frmName = metadata['photoFramingName'] as String?;
    if (frmName != null) {
      final found = PhotoFraming.values.where((f) => f.name == frmName).firstOrNull;
      if (found != null) framing = found;
    }

    PhotoScalingMode scaling = PhotoScalingMode.fit;
    final scName = metadata['photoScalingName'] as String?;
    if (scName != null) {
      final found = PhotoScalingMode.values.where((s) => s.name == scName).firstOrNull;
      if (found != null) scaling = found;
    }

    final copies = metadata['printJobCopies'] as int? ?? 1;
    final spacing = (metadata['spacingMm'] as num?)?.toDouble() ?? (mode == PhotoTypePresetMode.fourRPhoto || mode == PhotoTypePresetMode.a4Photo ? 0.0 : 2.0);
    final margin = (metadata['marginMm'] as num?)?.toDouble() ?? 2.0;

    final outerB = (metadata['outerBorderMm'] as num?)?.toDouble() ?? 0.0;
    final innerB = (metadata['innerBorderMm'] as num?)?.toDouble() ?? 0.0;
    final bEnabled = metadata['borderEnabled'] as bool? ?? false;
    final borderConfig = BorderConfig(
      outerBorderMm: outerB,
      innerBorderMm: innerB,
      enabled: bEnabled,
    );

    final enhanceJson = metadata['enhancement'] as Map<String, dynamic>?;
    final enhancement = enhanceJson != null ? EnhancementConfig.fromJson(enhanceJson) : const EnhancementConfig();

    state = state.copyWith(
      rawImageBytes: bytes,
      fileName: fileName,
      presetMode: mode,
      paperPreset: paper,
      orientation: orientation,
      photoFinish: finish,
      photoLamination: lamination,
      photoFraming: framing,
      photoScaling: scaling,
      printJobCopies: copies,
      spacingMm: spacing,
      marginMm: margin,
      borderConfig: borderConfig,
      enhancement: enhancement,
      backgroundColorHex: metadata['backgroundColorHex'] as String?,
      isProcessing: true,
      clearError: true,
    );

    try {
      final List<PhotoGroup> targetGroups = [];
      if (mode == PhotoTypePresetMode.a4Photo) {
        final a4Group = await _getOrBuildPresetGroup(StandardPhotoPresets.a4, 1);
        targetGroups.add(a4Group);
      } else if (mode == PhotoTypePresetMode.fourRPhoto) {
        final fourRGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.fourR, 1);
        targetGroups.add(fourRGroup);
      } else if (mode == PhotoTypePresetMode.passportPlusStamp) {
        final passportGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.passport, 6);
        final stampGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.stamp, 4);
        targetGroups.addAll([passportGroup, stampGroup]);
      } else {
        final passportGroup = await _getOrBuildPresetGroup(StandardPhotoPresets.passport, 8);
        targetGroups.add(passportGroup);
      }

      final layout = LayoutEngine.calculateMultiPhotoLayout(
        paperPreset: paper,
        groups: targetGroups,
        orientation: orientation,
        spacingMm: spacing,
        marginMm: margin,
        scaling: scaling,
      );

      state = state.copyWith(
        groups: targetGroups,
        activeGroupId: targetGroups.firstOrNull?.id,
        currentLayout: layout,
        isProcessing: false,
      );
    } catch (e) {
      debugPrint('Error restoring project layout: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to restore project: $e');
    }
  }

  /// Automatically restores last active photo project draft when app starts
  Future<void> restoreDraftIfExists() async {
    final draft = await DraftStorageService.loadPhotoDraft();
    if (draft == null) return;

    final bytes = draft['bytes'] as Uint8List?;
    final fName = draft['fileName'] as String?;
    final meta = draft['metadata'] as Map<String, dynamic>? ?? {};

    if (bytes != null && bytes.isNotEmpty && fName != null) {
      debugPrint('Auto-restoring last photo project draft: $fName');
      await restoreProjectFromData(
        bytes: bytes,
        fileName: fName,
        metadata: meta,
      );
    }
  }

  /// Saves current project as a standalone .fps project file
  Future<String?> saveProjectAsFps() async {
    if (!state.hasImage) return null;

    final raw = state.rawImageBytes!;
    final fName = state.fileName ?? 'photo_project';
    final thumb = state.currentLayout?.items.firstOrNull?.imageBytes;
    final metadata = {
      'presetModeName': state.presetMode.name,
      'paperPresetName': state.paperPreset.name,
      'paperPresetId': state.paperPreset.id,
      'orientationName': state.orientation.name,
      'spacingMm': state.spacingMm,
      'marginMm': state.marginMm,
      'printJobCopies': state.printJobCopies,
      'photoFinishName': state.photoFinish.name,
      'photoLaminationName': state.photoLamination.name,
      'photoFramingName': state.photoFraming.name,
      'photoScalingName': state.photoScaling.name,
      'backgroundColorHex': state.backgroundColorHex,
      'outerBorderMm': state.borderConfig.outerBorderMm,
      'innerBorderMm': state.borderConfig.innerBorderMm,
      'borderEnabled': state.borderConfig.enabled,
      'enhancement': state.enhancement.toJson(),
    };

    final path = await FpsProjectService.saveProjectAsFps(
      rawImageBytes: raw,
      fileName: fName,
      metadata: metadata,
      thumbnailBytes: thumb,
    );

    if (path != null) {
      await saveDraft();
    }
    return path;
  }

  /// Opens and loads a .fps project file from dialog or file path
  Future<bool> loadProjectFromFps({String? filePath}) async {
    Map<String, dynamic>? data;
    if (filePath != null) {
      data = await FpsProjectService.loadFpsFromFile(filePath);
    } else {
      data = await FpsProjectService.pickAndLoadFpsFile();
    }

    if (data == null) return false;

    final bytes = data['bytes'] as Uint8List?;
    final fName = data['fileName'] as String?;
    final meta = data['metadata'] as Map<String, dynamic>? ?? {};

    if (bytes == null || bytes.isEmpty || fName == null) return false;

    await restoreProjectFromData(
      bytes: bytes,
      fileName: fName,
      metadata: meta,
    );

    await saveDraft();
    return true;
  }

  /// Closes current active photo project, saves to Recent Projects, and resets workspace
  Future<void> closeCurrentProject() async {
    if (state.hasImage) {
      try {
        final raw = state.rawImageBytes!;
        final fName = state.fileName ?? 'Untitled Photo';
        final thumb = state.currentLayout?.items.firstOrNull?.imageBytes;
        final metadata = {
          'presetModeName': state.presetMode.name,
          'paperPresetName': state.paperPreset.name,
          'paperPresetId': state.paperPreset.id,
          'orientationName': state.orientation.name,
          'spacingMm': state.spacingMm,
          'marginMm': state.marginMm,
          'printJobCopies': state.printJobCopies,
          'photoFinishName': state.photoFinish.name,
          'photoLaminationName': state.photoLamination.name,
          'photoFramingName': state.photoFraming.name,
          'photoScalingName': state.photoScaling.name,
          'backgroundColorHex': state.backgroundColorHex,
          'outerBorderMm': state.borderConfig.outerBorderMm,
          'innerBorderMm': state.borderConfig.innerBorderMm,
          'borderEnabled': state.borderConfig.enabled,
          'enhancement': state.enhancement.toJson(),
        };

        await RecentProjectsService.addProject(
          RecentProjectItem(
            id: _uuid.v4(),
            fileName: fName,
            presetMode: state.presetMode.displayName,
            paperName: state.paperPreset.name,
            orientation: state.orientation.displayName,
            timestamp: DateTime.now(),
            thumbnailBytes: thumb,
            projectData: {
              'format': FpsProjectService.formatIdentifier,
              'version': FpsProjectService.currentVersion,
              'projectType': 'photo',
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

    _processedImageCache.clear();
    _draftDebounceTimer?.cancel();
    await DraftStorageService.clearPhotoDraft();
    state = const PassportPhotoState();
  }

  Future<void> clearAll() async {
    await closeCurrentProject();
  }

  Future<void> reset() async {
    await closeCurrentProject();
  }
}

class _GroupResizeParams {
  final Uint8List rawBytes;
  final CropRectData cropData;
  final double targetWidthMm;
  final double targetHeightMm;
  final EnhancementConfig enhancement;
  final BorderConfig borderConfig;
  final int dpi;

  _GroupResizeParams({
    required this.rawBytes,
    required this.cropData,
    required this.targetWidthMm,
    required this.targetHeightMm,
    required this.enhancement,
    required this.borderConfig,
    required this.dpi,
  });
}

Uint8List _processGroupPhotoWorker(_GroupResizeParams params) {
  // Cap effective DPI for large sheets (e.g. A4) so preview rendering is instantaneous (<50ms)
  int effectiveDpi = params.dpi;
  final longestMm = math.max(params.targetWidthMm, params.targetHeightMm);
  if (UnitConverter.mmToPixels(longestMm, effectiveDpi) > 1600) {
    effectiveDpi = (1600 * 25.4 / longestMm).round();
  }

  return ImageProcessor.processPhoto(
    sourceBytes: params.rawBytes,
    cropData: params.cropData,
    enhancement: params.enhancement,
    targetWidthMm: params.targetWidthMm,
    targetHeightMm: params.targetHeightMm,
    borderConfig: params.borderConfig,
    dpi: effectiveDpi,
  );
}

final passportPhotoProvider = StateNotifierProvider<PassportPhotoNotifier, PassportPhotoState>((ref) {
  return PassportPhotoNotifier(ref);
});
