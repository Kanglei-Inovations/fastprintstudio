import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/id_card/theme/id_card_palette.dart';
import '../../features/id_card/widgets/pdf_password_dialog.dart';
import '../../providers/app_providers.dart';
import '../../providers/pricing_provider.dart';
import '../../services/document/models/printable_document.dart';
import 'models/document_print_state.dart';
import 'providers/document_provider.dart';
import 'widgets/document_bottom_status_bar.dart';
import 'widgets/document_empty_state.dart';
import 'widgets/document_file_selector_card.dart';
import 'widgets/document_job_summary_card.dart';
import 'widgets/document_paper_layout_panel.dart';
import 'widgets/document_preview_canvas.dart';
import 'widgets/document_print_options_panel.dart';
import 'widgets/document_top_header.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key});

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _isDraggingOver = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile({bool onlyPdf = false}) async {
    try {
      final allowedExtensions = onlyPdf
          ? ['pdf']
          : ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'tif', 'tiff', 'fps'];

      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (file != null) {
        if (file.name.toLowerCase().endsWith('.fps')) {
          await ref.read(documentPrintProvider.notifier).loadProjectFromFps(filePath: file.path);
        } else {
          final bytes = await file.readAsBytes();
          await ref.read(documentPrintProvider.notifier).loadDocument(
                bytes: bytes,
                fileName: file.name,
              );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _handleKeyEvent(KeyEvent event, DocumentPrintState state, DocumentNotifier notifier) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (state.hasDocument) {
          notifier.printDocument();
        }
      } else if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (state.canRedo) notifier.redo();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
        if (state.canRedo) notifier.redo();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (state.canUndo) notifier.undo();
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
        if (state.hasDocument) {
          _saveProjectWithFeedback(notifier);
        }
      } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyO) {
        _pickFile(onlyPdf: false);
      }
    }
  }

  Future<void> _saveProjectWithFeedback(DocumentNotifier notifier) async {
    final savedPath = await notifier.saveProjectAsFps();
    if (savedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document project saved as .fps successfully.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFullscreenPreview(BuildContext context, DocumentPrintState state) {
    if (!state.hasDocument || state.activePageImageBytes == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 24, spreadRadius: 4),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: RotatedBox(
                  quarterTurns: state.rotationAngle ~/ 90,
                  child: Image.memory(
                    state.activePageImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: 'Close Preview',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentPrintProvider);
    final notifier = ref.read(documentPrintProvider.notifier);
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

    final pricingNotifier = ref.read(pricingProvider.notifier);
    final bwPricing = pricingNotifier.getPriceForService('doc_print_bw');
    final colorPricing = pricingNotifier.getPriceForService('doc_print_color');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = IdCardPalette.of(context, isDark: isDark);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, state, notifier),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: DropTarget(
          onDragEntered: (_) => setState(() => _isDraggingOver = true),
          onDragExited: (_) => setState(() => _isDraggingOver = false),
          onDragDone: (details) async {
            setState(() => _isDraggingOver = false);
            if (details.files.isNotEmpty) {
              final file = details.files.first;
              if (file.name.toLowerCase().endsWith('.fps')) {
                await ref.read(documentPrintProvider.notifier).loadProjectFromFps(filePath: file.path);
              } else {
                final bytes = await file.readAsBytes();
                await ref.read(documentPrintProvider.notifier).loadDocument(
                      bytes: bytes,
                      fileName: file.name,
                    );
              }
            }
          },
          child: Stack(
            children: [
              Column(
              children: [
                // 1. TOP HEADER & ACTION TOOLBAR
                DocumentTopHeader(
                  state: state,
                  canUndo: state.canUndo,
                  canRedo: state.canRedo,
                  onUndo: () => notifier.undo(),
                  onRedo: () => notifier.redo(),
                  onNewDocument: () => notifier.clearAll(),
                  onOpenFile: () => _pickFile(onlyPdf: false),
                  onSaveProject: () => _saveProjectWithFeedback(notifier),
                  onCloseProject: () => notifier.closeCurrentProject(),
                  onExportPdf: () => notifier.exportPdf(),
                  onFirstPage: () => notifier.firstPage(),
                  onPreviousPage: () => notifier.previousPage(),
                  onNextPage: () => notifier.nextPage(),
                  onLastPage: () => notifier.lastPage(),
                  onPrint: () => notifier.printDocument(),
                ),

                // Error Notification Banner
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty && state.hasDocument)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: const Color(0xFFFEF2F2),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. MAIN 3-ZONE WORKSPACE
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT CONTROL PANEL (Width: 325px)
                      Container(
                        width: 325,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            // Section 1: Select File
                            DocumentFileSelectorCard(
                              state: state,
                              onChooseFile: () => _pickFile(onlyPdf: false),
                            ),
                            const SizedBox(height: 16),

                            // Section 2: Print Options
                            DocumentPrintOptionsPanel(
                              state: state,
                              onCopiesChanged: (c) => notifier.setCopies(c),
                              onColorModeChanged: (m) => notifier.setColorMode(m),
                              onPageRangeModeChanged: (r) => notifier.setPageRangeMode(r),
                              onCustomRangeChanged: (t) => notifier.setCustomRangeText(t),
                              onPrintSidesChanged: (s) => notifier.setPrintSides(s),
                              onCollateChanged: (c) => notifier.setCollateCopies(c),
                              onReverseOrderChanged: (r) => notifier.setReverseOrder(r),
                              onSelectAll: () => notifier.selectAllPages(),
                              onClearSelection: () => notifier.clearPageSelection(),
                              onSelectOdd: () => notifier.selectOddPages(),
                              onSelectEven: () => notifier.selectEvenPages(),
                            ),
                            const SizedBox(height: 16),

                            // Section 3: Paper & Layout
                            DocumentPaperLayoutPanel(
                              state: state,
                              onPaperPresetChanged: (p) => notifier.setPaperPreset(p),
                              onPaperTypeChanged: (t) => notifier.setPaperType(t),
                              onBindingTypeChanged: (b) => notifier.setBindingType(b),
                              onOrientationChanged: (o) => notifier.setOrientation(o),
                              onScalingChanged: (s) => notifier.setScaling(s),
                              onCustomScaleChanged: (scale) => notifier.setCustomScalePercent(scale),
                              onAutoRotateChanged: (ar) => notifier.setAutoRotatePages(ar),
                              onPagesPerSheetChanged: (nUp) => notifier.setPagesPerSheet(nUp),
                              onMarginChanged: (m) => notifier.setMarginMm(m),
                              onBorderChanged: (b) => notifier.setBorderAroundPages(b),
                            ),
                          ],
                        ),
                      ),

                      // CENTER WORKSPACE (Preview Canvas or Empty State)
                      Expanded(
                        child: (state.hasDocument ||
                                state.renderStatus == DocumentRenderStatus.preparing ||
                                state.renderStatus == DocumentRenderStatus.error)
                            ? DocumentPreviewCanvas(
                                state: state,
                                onSelectPage: (idx) => notifier.setActivePage(idx),
                                onZoomIn: () => notifier.zoomIn(),
                                onZoomOut: () => notifier.zoomOut(),
                                onResetZoom: () => notifier.resetZoom(),
                                onRetry: () => notifier.retryConversion(),
                                onChooseAnother: () => _pickFile(onlyPdf: false),
                              )
                            : DocumentEmptyState(
                                onChooseFile: () => _pickFile(onlyPdf: false),
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
                              ),
                      ),

                      // RIGHT PANEL (Job Summary & Quick Actions, Width: 290px)
                      DocumentJobSummaryCard(
                        state: state,
                        bwPricing: bwPricing,
                        colorPricing: colorPricing,
                        onCopiesChanged: (c) => notifier.setCopies(c),
                        onPrintNow: () => notifier.printDocument(),
                        onPreviewFullscreen: () => _showFullscreenPreview(context, state),
                        onPrintCurrentPage: () => notifier.printCurrentPage(),
                        onExportPdf: () => notifier.exportPdf(),
                        onClearAll: () => notifier.clearAll(),
                      ),
                    ],
                  ),
                ),

                // 3. BOTTOM STATUS BAR
                DocumentBottomStatusBar(
                  state: state,
                  currentPrinter: currentPrinter,
                ),
              ],
            ),

            // Password Prompt Dialog Overlay if password protected PDF loaded
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                            ),
                            child: const Icon(Icons.file_download_outlined, size: 36, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Drop document here to open',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Supports PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
