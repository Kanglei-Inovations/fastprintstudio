import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/id_card_provider.dart';
import '../../shared/widgets/crop_editor_modal.dart';
import '../../shared/widgets/print_preview_canvas.dart';
import 'theme/id_card_palette.dart';
import 'widgets/auto_detect_card.dart';
import 'widgets/card_format_selector.dart';
import 'widgets/card_sides_panel.dart';
import 'widgets/id_card_bottom_bar.dart';
import 'widgets/id_card_bottom_status_bar.dart';
import 'widgets/id_card_empty_state.dart';
import 'widgets/id_card_file_selector_card.dart';
import 'widgets/id_card_top_toolbar.dart';
import 'widgets/image_adjustment_panel.dart';
import 'widgets/pdf_password_dialog.dart';
import '../../core/models/id_card_workflow_type.dart';
import 'widgets/l805_calibration_dialog.dart';
import 'widgets/print_job_summary_panel.dart';

class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _isDraggingOver = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool onlyPdf, required bool onlyImages}) async {
    try {
      final extensions = onlyPdf
          ? ['pdf']
          : onlyImages
              ? ['jpg', 'jpeg', 'png', 'webp', 'bmp']
              : ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'fps'];

      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (file != null) {
        if (file.name.toLowerCase().endsWith('.fps')) {
          await ref.read(idCardProvider.notifier).loadProjectFromFps(filePath: file.path);
        } else {
          final bytes = await file.readAsBytes();
          final isPdf = file.name.toLowerCase().endsWith('.pdf');
          ref.read(idCardProvider.notifier).loadDocument(
                bytes: bytes,
                fileName: file.name,
                isPdf: isPdf,
              );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _adjustFrontCrop(BuildContext context, IdCardState state, IdCardNotifier notifier) async {
    final activeBytes = state.activePageImageBytes;
    if (activeBytes == null) return;

    final cropResult = await CropEditorModal.show(
      context: context,
      imageBytes: activeBytes,
      initialCrop: state.frontCrop,
      targetAspectRatio: state.idCardPreset.aspectRatio,
      title: 'Adjust FRONT Side Crop (${state.idCardPreset.formattedDimensions})',
    );

    if (cropResult != null) {
      await notifier.applyFrontCropResult(cropResult);
    }
  }

  Future<void> _adjustBackCrop(BuildContext context, IdCardState state, IdCardNotifier notifier) async {
    final activeBytes = state.activePageImageBytes;
    if (activeBytes == null) return;

    final cropResult = await CropEditorModal.show(
      context: context,
      imageBytes: activeBytes,
      initialCrop: state.backCrop ?? state.frontCrop,
      targetAspectRatio: state.idCardPreset.aspectRatio,
      title: 'Adjust BACK Side Crop (${state.idCardPreset.formattedDimensions})',
    );

    if (cropResult != null) {
      await notifier.applyBackCropResult(cropResult);
    }
  }

  void _handleKeyEvent(KeyEvent event, IdCardState state, IdCardNotifier notifier) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (state.hasSource) {
          notifier.printDocument();
        }
      } else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (state.canRedo) notifier.redo();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (state.canUndo) notifier.undo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(idCardProvider);
    final notifier = ref.read(idCardProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final availablePrintersAsync = ref.watch(availablePrintersProvider);
    final currentPrinter = availablePrintersAsync.when(
      data: (printers) {
        if (printers.isEmpty) return null;
        if (settings.defaultPrinterName != null) {
          return printers.firstWhere(
            (p) => p.name == settings.defaultPrinterName,
            orElse: () => printers.first,
          );
        }
        return printers.firstWhere((p) => p.isDefault, orElse: () => printers.first);
      },
      loading: () => null,
      error: (_, _) => null,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = IdCardPalette.of(context, isDark: isDark);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, state, notifier),
      child: Scaffold(
        backgroundColor: palette.bg,
        body: DropTarget(
          onDragEntered: (_) => setState(() => _isDraggingOver = true),
          onDragExited: (_) => setState(() => _isDraggingOver = false),
          onDragDone: (details) async {
            setState(() => _isDraggingOver = false);
            if (details.files.isNotEmpty) {
              final file = details.files.first;
              if (file.name.toLowerCase().endsWith('.fps')) {
                await ref.read(idCardProvider.notifier).loadProjectFromFps(filePath: file.path);
              } else {
                final bytes = await file.readAsBytes();
                final isPdf = file.name.toLowerCase().endsWith('.pdf');
                ref.read(idCardProvider.notifier).loadDocument(
                      bytes: bytes,
                      fileName: file.name,
                      isPdf: isPdf,
                    );
              }
            }
          },
          child: Stack(
            children: [
              Column(
              children: [
                // 1. TOP TOOLBAR
                IdCardTopToolbar(
                  palette: palette,
                  preset: state.idCardPreset,
                  hasSource: state.hasSource,
                  canUndo: state.canUndo,
                  canRedo: state.canRedo,
                  onUndo: notifier.undo,
                  onRedo: notifier.redo,
                  onNewDocument: () => notifier.clearAll(),
                  onOpen: () => _pickFile(onlyPdf: false, onlyImages: false),
                  onSaveProject: () async {
                    final savedPath = await notifier.saveProjectAsFps();
                    if (savedPath != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Card project saved as .fps successfully.'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onCloseProject: () => notifier.closeCurrentProject(),
                  onExportPdf: () => notifier.exportPdf(),
                  onPrint: () => notifier.printDocument(),
                ),

                // Error Notification Banner
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: palette.isDark ? palette.red.withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 16, color: palette.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. MAIN WORKSPACE (Always 3-Zone Workspace)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT SIDEBAR (Width: 330px)
                      Container(
                        width: 330,
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          border: Border(right: BorderSide(color: palette.divider)),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            // Section 1: Select File
                            IdCardFileSelectorCard(
                              palette: palette,
                              fileName: state.fileName,
                              fileBytes: state.rawSourceBytes,
                              isPdf: state.isPdfSource,
                              hasSource: state.hasSource,
                              onUploadPdf: () => _pickFile(onlyPdf: true, onlyImages: false),
                              onUploadImage: () => _pickFile(onlyPdf: false, onlyImages: true),
                              onChangeFile: () => _pickFile(onlyPdf: false, onlyImages: false),
                            ),
                            const SizedBox(height: 14),

                            // Multi-page PDF page selector if applicable
                                  if (state.renderedPages.length > 1) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'PDF Pages',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                        ),
                                        Text(
                                          'Page ${state.selectedPageIndex + 1} of ${state.renderedPages.length}',
                                          style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        for (int p = 0; p < state.renderedPages.length; p++) ...[
                                          if (p > 0) const SizedBox(width: 6),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => notifier.selectPage(p),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 6),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: state.selectedPageIndex == p
                                                      ? (palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight)
                                                      : palette.pillBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: state.selectedPageIndex == p ? palette.blue : palette.pillBorder,
                                                    width: state.selectedPageIndex == p ? 1.4 : 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  'P${p + 1}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: state.selectedPageIndex == p ? FontWeight.w800 : FontWeight.w500,
                                                    color: state.selectedPageIndex == p ? palette.blue : palette.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Section A: Card Format & Workflow Selector
                                  CardFormatSelector(
                                    palette: palette,
                                    selectedPreset: state.idCardPreset,
                                    onSelectPreset: (preset) => notifier.setIdCardPreset(preset),
                                    workflowType: state.workflowType,
                                    onSelectWorkflow: (wf) => notifier.setWorkflowType(wf),
                                    pvcMode: state.pvcMode,
                                    onSelectPvcMode: (mode) => notifier.setPvcOutputMode(mode),
                                    l805CardQuantity: state.l805CardQuantity,
                                    onSelectL805CardQuantity: (q) => notifier.setL805CardQuantity(q),
                                    onOpenCalibration: () => L805CalibrationDialog.show(
                                      context: context,
                                      palette: palette,
                                      initialCalibration: state.l805Calibration,
                                      onSave: (cal) => notifier.updateL805Calibration(cal),
                                      onReset: () => notifier.resetL805Calibration(),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Section C: Auto Detect Card (When source loaded)
                                  if (state.hasSource) ...[
                                    AutoDetectCard(
                                      palette: palette,
                                      isDetecting: state.isDetecting,
                                      detectionResult: state.detectionResult,
                                      frontDetected: state.processedFrontBytes != null,
                                      backDetected: state.processedBackBytes != null,
                                      onRunAutoDetect: () => notifier.runAutoDetect(),
                                      onSelectFrontCandidate: (cand) => notifier.setCandidateAsFront(cand),
                                      onSelectBackCandidate: (cand) => notifier.setCandidateAsBack(cand),
                                      onAdjustCrop: () => _adjustFrontCrop(context, state, notifier),
                                      onRotate: () => notifier.rotateCrop(90),
                                      onReset: () => notifier.resetEnhancements(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Section B: Card Sides & Cropping
                                  CardSidesPanel(
                                    palette: palette,
                                    preset: state.idCardPreset,
                                    frontBytes: state.processedFrontBytes,
                                    backBytes: state.processedBackBytes,
                                    hasBothSides: state.hasBothSides,
                                    swapFrontBack: state.swapFrontBack,
                                    onAdjustFrontCrop: () => _adjustFrontCrop(context, state, notifier),
                                    onAdjustBackCrop: () => _adjustBackCrop(context, state, notifier),
                                    onToggleBothSides: (val) => notifier.toggleHasBothSides(val),
                                    onToggleSwapOrder: () => notifier.setSwapFrontBack(!state.swapFrontBack),
                                  ),

                                  const SizedBox(height: 12),

                                  // Section D: Image Adjustments
                                  ImageAdjustmentPanel(
                                    palette: palette,
                                    config: state.frontEnhancement,
                                    onBrightnessChanged: (val) => notifier.updateEnhancements(brightness: val),
                                    onContrastChanged: (val) => notifier.updateEnhancements(contrast: 1.0 + val),
                                    onSharpnessChanged: (val) => notifier.updateEnhancements(sharpness: val),
                                    onReset: () => notifier.resetEnhancements(),
                                  ),
                                ],
                              ),
                            ),

                            // CENTER PREVIEW WORKSPACE
                            Expanded(
                              child: !state.hasSource
                                  ? IdCardEmptyState(
                                      palette: palette,
                                      onUploadPdf: () => _pickFile(onlyPdf: true, onlyImages: false),
                                      onUploadImage: () => _pickFile(onlyPdf: false, onlyImages: true),
                                      onOpenFpsProject: () => notifier.loadProjectFromFps(),
                                      onOpenRecentProject: (item) {
                                        final rawBase64 = item.projectData['rawImageBase64'] as String?;
                                        if (rawBase64 != null) {
                                          final bytes = base64Decode(rawBase64);
                                          final meta = item.projectData['metadata'] as Map<String, dynamic>? ?? {};
                                          notifier.restoreProjectFromData(
                                            bytes: bytes,
                                            fileName: item.fileName,
                                            metadata: meta,
                                          );
                                        }
                                      },
                                    )
                                  : Container(
                                      color: palette.canvasBg,
                                      child: Column(
                                        children: [
                                          // Epson L805 Front / Back Preview Selector Bar
                                    if (state.workflowType == IdCardWorkflowType.epsonL805)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: palette.cardBg,
                                          border: Border(bottom: BorderSide(color: palette.divider)),
                                        ),
                                        child: Row(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.layers_rounded, size: 15, color: palette.blue),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'A4 Tray Preview:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: palette.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            // Front Page Button
                                            InkWell(
                                              onTap: () => notifier.setL805PreviewFront(true),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: state.l805PreviewFront ? palette.blue : palette.pillBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: state.l805PreviewFront ? palette.blue : palette.pillBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.filter_1_rounded,
                                                      size: 13,
                                                      color: state.l805PreviewFront ? Colors.white : palette.textSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'PAGE 1: FRONT SIDE',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                        color: state.l805PreviewFront ? Colors.white : palette.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Back Page Button (only if hasBothSides)
                                            InkWell(
                                              onTap: state.hasBothSides ? () => notifier.setL805PreviewFront(false) : null,
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: (!state.l805PreviewFront)
                                                      ? palette.blue
                                                      : (state.hasBothSides ? palette.pillBg : palette.pillBg.withValues(alpha: 0.5)),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: (!state.l805PreviewFront) ? palette.blue : palette.pillBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.filter_2_rounded,
                                                      size: 13,
                                                      color: (!state.l805PreviewFront)
                                                          ? Colors.white
                                                          : (state.hasBothSides ? palette.textSecondary : palette.textMuted),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'PAGE 2: BACK SIDE',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                        color: (!state.l805PreviewFront)
                                                            ? Colors.white
                                                            : (state.hasBothSides ? palette.textSecondary : palette.textMuted),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: palette.pillBorder),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.straighten_rounded, size: 12, color: palette.blue),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Scale: 100% Actual Size',
                                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.blue),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    Expanded(
                                      child: state.currentLayout != null
                                          ? PrintPreviewCanvas(
                                              layout: state.currentLayout!,
                                              onClearAll: () => notifier.clearAll(),
                                            )
                                          : const Center(child: CircularProgressIndicator()),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // RIGHT JOB SUMMARY PANEL
                            PrintJobSummaryPanel(
                              palette: palette,
                              preset: state.idCardPreset,
                              paper: state.paperPreset,
                              orientation: state.orientation,
                              hasBothSides: state.hasBothSides,
                              copies: state.printJobCopies,
                              workflowType: state.workflowType,
                              pvcMode: state.pvcMode,
                              l805CardQuantity: state.l805CardQuantity,
                              cardsPlaced: state.currentLayout?.itemCount ?? 1,
                              frontCount: state.processedFrontBytes != null ? 1 : 0,
                              backCount: state.hasBothSides && state.processedBackBytes != null ? 1 : 0,
                              sheetsUsed: state.printJobCopies,
                              sellingPrice: state.calculatedSellingPrice,
                              materialCost: state.calculatedMaterialCost,
                              inkCost: state.calculatedInkCost,
                              profit: state.calculatedEstimatedProfit,
                              hasSource: state.hasSource,
                              onCopiesChanged: (c) => notifier.setPrintJobCopies(c),
                              onPrint: () => notifier.printDocument(),
                              onExportPdf: () => notifier.exportPdf(),
                            ),
                          ],
                        ),
                ),

                // 3. BOTTOM PRINT / PAPER / LAYOUT CONTROL BAR (When Card is loaded)
                if (state.hasSource)
                  IdCardBottomBar(
                    palette: palette,
                    gapMm: state.gapMm,
                    marginMm: state.marginMm,
                    paperPreset: state.paperPreset,
                    orientation: state.orientation,
                    copies: state.printJobCopies,
                    onGapChanged: (g) => notifier.setGapMm(g),
                    onMarginChanged: (m) => notifier.setMarginMm(m),
                    onPaperPresetChanged: (p) => notifier.setPaperPreset(p),
                    onOrientationChanged: (o) => notifier.setOrientation(o),
                    onCopiesChanged: (c) => notifier.setPrintJobCopies(c),
                    onOpenPrinterSettings: () {
                      ref.read(navIndexProvider.notifier).state = 6;
                    },
                  ),

                // 4. BOTTOM STATUS BAR (Always visible, matching Document Printing)
                IdCardBottomStatusBar(
                  state: state,
                  currentPrinter: currentPrinter,
                ),
              ],
            ),

            // Password Modal Overlay when password-protected PDF is chosen
            if (state.isPasswordRequired)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: PdfPasswordDialog(
                      palette: palette,
                      fileName: state.pendingEncryptedFileName ?? 'Encrypted Document.pdf',
                      errorMessage: state.passwordError,
                      isProcessing: state.isProcessing,
                      onUnlock: (pwd) => notifier.unlockPasswordProtectedPdf(pwd),
                      onCancel: () => notifier.cancelPasswordPrompt(),
                    ),
                  ),
                ),
              ),

            // Drag-and-Drop Visual Overlay from Desktop
            if (_isDraggingOver)
              Positioned.fill(
                child: Container(
                  color: palette.blue.withValues(alpha: 0.12),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: palette.cardBg.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.blue, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: palette.blue.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: palette.blueLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.blue.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Icon(Icons.file_download_outlined, size: 36, color: palette.blue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Drop ID card file here to open',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: palette.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Supports PDF, JPG, JPEG, PNG, WEBP',
                            style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}
