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
import 'widgets/card_format_selector.dart';
import 'widgets/card_sides_panel.dart';
import 'widgets/id_card_bottom_status_bar.dart';
import 'widgets/id_card_empty_state.dart';
import 'widgets/id_card_file_selector_card.dart';
import 'widgets/id_card_list_panel.dart';
import 'widgets/id_card_pagination_bar.dart';
import 'widgets/id_card_paper_layout_panel.dart';
import 'widgets/id_card_top_toolbar.dart';
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

  Future<void> _pickFile({
    required bool onlyPdf,
    required bool onlyImages,
    bool isAddMore = false,
  }) async {
    try {
      final extensions = onlyPdf
          ? ['pdf']
          : onlyImages
              ? ['jpg', 'jpeg', 'png', 'webp', 'bmp']
              : ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'fps'];

      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (files.isNotEmpty) {
        if (files.length == 1 && files.first.name.toLowerCase().endsWith('.fps')) {
          await ref.read(idCardProvider.notifier).loadProjectFromFps(filePath: files.first.path);
          return;
        }

        final fileDataList = <({Uint8List bytes, String fileName, bool isPdf})>[];
        for (final file in files) {
          if (!file.name.toLowerCase().endsWith('.fps')) {
            final bytes = await file.readAsBytes();
            final isPdf = file.name.toLowerCase().endsWith('.pdf');
            fileDataList.add((bytes: bytes, fileName: file.name, isPdf: isPdf));
          }
        }

        if (fileDataList.isNotEmpty) {
          if (!isAddMore && fileDataList.length == 1 && ref.read(idCardProvider).cards.isNotEmpty) {
            final f = fileDataList.first;
            await ref.read(idCardProvider.notifier).replaceActiveCard(
                  bytes: f.bytes,
                  fileName: f.fileName,
                  isPdf: f.isPdf,
                );
          } else {
            await ref.read(idCardProvider.notifier).loadMultipleDocuments(fileDataList);
          }

          if (mounted) {
            final curState = ref.read(idCardProvider);
            if (curState.hasSource) {
              await _adjustFrontCrop(context, curState, ref.read(idCardProvider.notifier));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _adjustFrontCrop(BuildContext context, IdCardState state, IdCardNotifier notifier) async {
    final activeBytes = state.activeCard?.frontSourceImageBytes ?? state.activePageImageBytes;
    if (activeBytes == null) return;

    final cropResult = await CropEditorModal.show(
      context: context,
      imageBytes: activeBytes,
      initialCrop: state.frontCrop,
      targetAspectRatio: state.idCardPreset.aspectRatio,
      title: 'Adjust FRONT Side Crop (${state.idCardPreset.formattedDimensions})',
      idCardPreset: state.idCardPreset,
    );

    if (cropResult != null) {
      await notifier.applyFrontCropResult(cropResult);
    }
  }

  Future<void> _adjustBackCrop(BuildContext context, IdCardState state, IdCardNotifier notifier) async {
    final activeBytes = state.activeCard?.backSourceImageBytes ?? state.activePageImageBytes;
    if (activeBytes == null) return;

    final cropResult = await CropEditorModal.show(
      context: context,
      imageBytes: activeBytes,
      initialCrop: state.backCrop ?? state.frontCrop,
      targetAspectRatio: state.idCardPreset.aspectRatio,
      title: 'Adjust BACK Side Crop (${state.idCardPreset.formattedDimensions})',
      idCardPreset: state.idCardPreset,
    );

    if (cropResult != null) {
      await notifier.applyBackCropResult(cropResult);
    }
  }

  Future<void> _pickCustomBackFile(IdCardNotifier notifier) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      if (files.isNotEmpty) {
        final f = files.first;
        final bytes = await f.readAsBytes();
        final isPdf = f.name.toLowerCase().endsWith('.pdf');
        await notifier.uploadCustomBackFile(
          bytes: bytes,
          fileName: f.name,
          isPdf: isPdf,
        );
        if (mounted) {
          await _adjustBackCrop(context, ref.read(idCardProvider), notifier);
        }
      }
    } catch (e) {
      debugPrint('Error picking custom back file: $e');
    }
  }

  Future<void> _pickCustomFrontFile(IdCardNotifier notifier) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      if (files.isNotEmpty) {
        final f = files.first;
        final bytes = await f.readAsBytes();
        final isPdf = f.name.toLowerCase().endsWith('.pdf');
        await notifier.uploadCustomFrontFile(
          bytes: bytes,
          fileName: f.name,
          isPdf: isPdf,
        );
        if (mounted) {
          await _adjustFrontCrop(context, ref.read(idCardProvider), notifier);
        }
      }
    } catch (e) {
      debugPrint('Error picking custom front file: $e');
    }
  }

  Future<void> _saveProject(IdCardNotifier notifier) async {
    final savedPath = await notifier.saveProjectAsFps();
    if (savedPath != null && mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Card project saved as .fps successfully.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleKeyEvent(KeyEvent event, IdCardState state, IdCardNotifier notifier) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
        // Ctrl + P : Print
        if (state.hasSource) {
          notifier.printDocument();
        }
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
        // Ctrl + S : Save Project (.fps)
        if (state.hasSource) {
          _saveProject(notifier);
        }
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyE) {
        // Ctrl + E : Export PDF
        if (state.hasSource) {
          notifier.exportPdf();
        }
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyO) {
        // Ctrl + O : Open File
        _pickFile(onlyPdf: false, onlyImages: false, isAddMore: false);
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        // Ctrl + N : Add File / Add Card
        _pickFile(onlyPdf: false, onlyImages: false, isAddMore: true);
      } else if (isCtrl && (event.logicalKey == LogicalKeyboardKey.keyY || (isShift && event.logicalKey == LogicalKeyboardKey.keyZ))) {
        // Ctrl + Y or Ctrl + Shift + Z : Redo
        if (state.canRedo) notifier.redo();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        // Ctrl + Z : Undo
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          if (state.hasSource) notifier.printDocument();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (state.hasSource) _saveProject(notifier);
        },
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () {
          if (state.hasSource) notifier.exportPdf();
        },
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
          _pickFile(onlyPdf: false, onlyImages: false, isAddMore: false);
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          _pickFile(onlyPdf: false, onlyImages: false, isAddMore: true);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (state.canUndo) notifier.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (state.canRedo) notifier.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          if (state.canRedo) notifier.redo();
        },
        // Meta (Command key) support on macOS
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true): () {
          if (state.hasSource) notifier.printDocument();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (state.hasSource) _saveProject(notifier);
        },
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true): () {
          if (state.hasSource) notifier.exportPdf();
        },
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () {
          _pickFile(onlyPdf: false, onlyImages: false, isAddMore: false);
        },
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
          _pickFile(onlyPdf: false, onlyImages: false, isAddMore: true);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (state.canUndo) notifier.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          if (state.canRedo) notifier.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          if (state.canRedo) notifier.redo();
        },
      },
      child: KeyboardListener(
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
              final fpsFile = details.files.where((f) => f.name.toLowerCase().endsWith('.fps')).firstOrNull;
              if (fpsFile != null) {
                await ref.read(idCardProvider.notifier).loadProjectFromFps(filePath: fpsFile.path);
                return;
              }

              final fileDataList = <({Uint8List bytes, String fileName, bool isPdf})>[];
              for (final file in details.files) {
                final nameLower = file.name.toLowerCase();
                if (nameLower.endsWith('.pdf') ||
                    nameLower.endsWith('.jpg') ||
                    nameLower.endsWith('.jpeg') ||
                    nameLower.endsWith('.png') ||
                    nameLower.endsWith('.webp') ||
                    nameLower.endsWith('.bmp')) {
                  final bytes = await file.readAsBytes();
                  final isPdf = nameLower.endsWith('.pdf');
                  fileDataList.add((bytes: bytes, fileName: file.name, isPdf: isPdf));
                }
              }

              if (fileDataList.isNotEmpty) {
                await ref.read(idCardProvider.notifier).loadMultipleDocuments(fileDataList);
                if (mounted && context.mounted) {
                  final curState = ref.read(idCardProvider);
                  if (curState.hasSource) {
                    await _adjustFrontCrop(context, curState, ref.read(idCardProvider.notifier));
                  }
                }
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
                  onSaveProject: () => _saveProject(notifier),
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
                              onChangeFile: () => _pickFile(onlyPdf: false, onlyImages: false, isAddMore: false),
                              onAddCard: () => _pickFile(onlyPdf: false, onlyImages: false, isAddMore: true),
                            ),
                            const SizedBox(height: 14),

                            // Multi-Card / Person List Panel
                            if (state.cards.isNotEmpty) ...[
                              IdCardListPanel(
                                palette: palette,
                                cards: state.cards,
                                activeCardId: state.activeCardId,
                                onSelectCard: (id) => notifier.setActiveCardId(id),
                                onRemoveCard: (id) => notifier.removeCard(id),
                                onAddCard: () => _pickFile(onlyPdf: false, onlyImages: false, isAddMore: true),
                                onMergeCards: (frontId, backId) => notifier.mergeCardsAsDuplex(frontId, backId),
                              ),
                              const SizedBox(height: 14),
                            ],

                                    // Multi-page PDF page selector if applicable
                                    if (state.renderedPages.length > 1) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf_rounded, size: 14, color: palette.red),
                                              const SizedBox(width: 6),
                                              Text(
                                                'PDF Pages',
                                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: palette.isDark ? palette.red.withValues(alpha: 0.15) : palette.red.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Page ${state.selectedPageIndex + 1} of ${state.renderedPages.length}',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.red),
                                            ),
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
                                                        ? (palette.isDark ? palette.red.withValues(alpha: 0.25) : const Color(0xFFFEE2E2))
                                                        : palette.pillBg,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: state.selectedPageIndex == p ? palette.red : palette.pillBorder,
                                                      width: state.selectedPageIndex == p ? 1.4 : 1.0,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'P${p + 1}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: state.selectedPageIndex == p ? FontWeight.w800 : FontWeight.w500,
                                                      color: state.selectedPageIndex == p ? palette.red : palette.textSecondary,
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

                                  // Card Sides & Cropping (Before Output Method)
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
                                    onUploadFrontFile: () => _pickCustomFrontFile(notifier),
                                    onUploadBackFile: () => _pickCustomBackFile(notifier),
                                    totalPages: state.activeCard?.backRenderedPages.isNotEmpty == true
                                        ? state.activeCard!.backRenderedPages.length
                                        : state.renderedPages.length,
                                    backPageIndex: state.activeCard?.backSelectedPageIndex ?? 0,
                                    onSelectBackPage: (p) => notifier.setBackSelectedPageIndex(p),
                                  ),

                                  const SizedBox(height: 12),

                                  // Output / Production Method
                                  CardFormatSelector(
                                    palette: palette,
                                    selectedPreset: state.idCardPreset,
                                    onSelectPreset: (preset) => notifier.setIdCardPreset(preset),
                                    workflowType: state.workflowType,
                                    onSelectWorkflow: (wf) => notifier.setWorkflowType(wf),
                                    onOpenCalibration: () => L805CalibrationDialog.show(
                                      context: context,
                                      palette: palette,
                                      initialCalibration: state.l805Calibration,
                                      onSave: (cal) => notifier.updateL805Calibration(cal),
                                      onReset: () => notifier.resetL805Calibration(),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                   // Section D: Spacing & Margins
                                   IdCardPaperLayoutPanel(
                                     palette: palette,
                                     gapMm: state.gapMm,
                                     marginMm: state.marginMm,
                                     workflowType: state.workflowType,
                                     showDragonCutLines: state.showDragonCutLines,
                                     onGapChanged: (gap) => notifier.setGapMm(gap),
                                     onMarginChanged: (margin) => notifier.setMarginMm(margin),
                                     onToggleDragonCutLines: (show) => notifier.setShowDragonCutLines(show),
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
                                    // Multi-Sheet Pagination Bar for Multi-Sheet layouts or Multi-Card layouts
                                    if (state.currentLayouts.length > (state.workflowType == IdCardWorkflowType.epsonL805 ? 2 : 1) ||
                                        (state.cards.length > 1 && state.workflowType != IdCardWorkflowType.epsonL805))
                                      IdCardPaginationBar(
                                        palette: palette,
                                        activeSheetIndex: state.activeSheetIndex,
                                        totalSheets: state.currentLayouts.isNotEmpty ? state.currentLayouts.length : 1,
                                        sheetTitle: state.currentLayout?.serviceType,
                                        activeCardName: state.cards.isNotEmpty
                                            ? () {
                                                final idx = state.cards.indexWhere((c) => c.id == state.activeCardId);
                                                return idx >= 0 ? 'Card ${idx + 1}' : null;
                                              }()
                                            : null,
                                        sheetLabelBuilder: state.workflowType == IdCardWorkflowType.epsonL805
                                            ? (i) => i.isEven ? 'Tray ${(i ~/ 2) + 1}: Front' : 'Tray ${(i ~/ 2) + 1}: Back'
                                            : null,
                                        onSelectSheet: (idx) => notifier.setActiveSheetIndex(idx),
                                        onPrevSheet: notifier.prevSheet,
                                        onNextSheet: notifier.nextSheet,
                                      )
                                    // Epson L805 Front / Back Preview Selector Bar (for single tray batch / up to 2 pages)
                                    else if (state.workflowType == IdCardWorkflowType.epsonL805)
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
                                              selectedGroupId: state.activeCardId,
                                              onSelectGroup: (cardId) => notifier.setActiveCardId(cardId),
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
                              cardsPlaced: state.cards.isNotEmpty ? state.cards.length : (state.currentLayout?.itemCount ?? 1),
                              frontCount: state.cards.isNotEmpty
                                  ? state.cards.where((c) => c.frontBytes != null).length
                                  : (state.processedFrontBytes != null ? 1 : 0),
                              backCount: state.cards.isNotEmpty
                                  ? state.cards.where((c) => c.hasBothSides && c.backBytes != null).length
                                  : (state.hasBothSides && state.processedBackBytes != null ? 1 : 0),
                              sheetsUsed: (state.currentLayouts.isNotEmpty ? state.currentLayouts.length : 1) * state.printJobCopies,
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
                // 3. BOTTOM STATUS BAR (Always visible, matching Photo & Document Printing)
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
  ),
);
}
}
