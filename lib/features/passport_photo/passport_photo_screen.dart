import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/paper_presets.dart';
import '../../core/constants/photo_presets.dart';
import '../../core/models/crop_rect_data.dart';
import '../../core/models/crop_result.dart';
import '../../core/models/enhancement_config.dart';
import '../../core/models/paper_preset.dart';
import '../../core/models/photo_finish.dart';
import '../../core/models/photo_group.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/app_providers.dart';
import '../../providers/passport_photo_provider.dart';
import '../../shared/widgets/crop_editor_modal.dart';
import '../../shared/widgets/print_preview_canvas.dart';
import 'widgets/passport_photo_empty_state.dart';
import 'widgets/passport_photo_file_selector_card.dart';
import 'widgets/photo_bottom_status_bar.dart';
import 'widgets/photo_paper_layout_panel.dart';

class PassportPhotoScreen extends ConsumerStatefulWidget {
  const PassportPhotoScreen({super.key});

  @override
  ConsumerState<PassportPhotoScreen> createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends ConsumerState<PassportPhotoScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _isDraggingOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(pendingPhotoImportProvider);
      if (pending != null && mounted) {
        ref.read(pendingPhotoImportProvider.notifier).state = null;
        _handleNewPhotoSelected(pending.bytes, pending.fileName);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickNewPhoto() async {
    try {
      debugPrint('[FastPrint Photo] 📂 Opening file picker for new photo...');
      final sw = Stopwatch()..start();
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      if (files.isEmpty) {
        debugPrint('[FastPrint Photo] ℹ️ File picker canceled by user.');
        return;
      }

      final first = files.first;
      final firstBytes = await first.readAsBytes();
      debugPrint('[FastPrint Photo] 📄 Selected file: "${first.name}" (${(firstBytes.length / 1024).toStringAsFixed(1)} KB) in ${sw.elapsedMilliseconds}ms');

      if (mounted) {
        await _handleNewPhotoSelected(firstBytes, first.name);
      }

      // If user selected multiple files, legitimately prompt crop for each subsequent person
      if (files.length > 1 && mounted) {
        debugPrint('[FastPrint Photo] 👥 User selected ${files.length} photos. Prompting crop for additional photos...');
        for (int i = 1; i < files.length; i++) {
          if (!mounted) break;
          final file = files[i];
          final bytes = await file.readAsBytes();
          await _promptAndAddPersonPhoto(bytes: bytes, fileName: file.name);
        }
      }
    } catch (e) {
      debugPrint('[FastPrint Photo] ❌ Error picking file: $e');
    }
  }

  Future<void> _pickAdditionalPersonPhoto() async {
    try {
      debugPrint('[FastPrint Photo] 👤 Opening file picker to add another person...');
      final sw = Stopwatch()..start();
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );
      if (files.isEmpty || !mounted) {
        debugPrint('[FastPrint Photo] ℹ️ Add person canceled.');
        return;
      }

      for (final file in files) {
        if (!mounted) break;
        final readSw = Stopwatch()..start();
        final bytes = await file.readAsBytes();
        debugPrint('[FastPrint Photo] 📥 Read "${file.name}" (${(bytes.length / 1024).toStringAsFixed(1)} KB) in ${readSw.elapsedMilliseconds}ms');
        await _promptAndAddPersonPhoto(bytes: bytes, fileName: file.name);
      }
      debugPrint('[FastPrint Photo] ✅ _pickAdditionalPersonPhoto finished in ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('[FastPrint Photo] ❌ Error adding additional person photo: $e');
    }
  }

  /// Prompts CropEditorModal with actual image dimensions and aspect ratio, then adds person photo
  Future<void> _promptAndAddPersonPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!mounted) return;
    final state = ref.read(passportPhotoProvider);
    final notifier = ref.read(passportPhotoProvider.notifier);
    final activePreset = state.groups.isNotEmpty
        ? state.groups.first.preset
        : (state.presetMode == PhotoTypePresetMode.fourRPhoto
            ? StandardPhotoPresets.fourR
            : (state.presetMode == PhotoTypePresetMode.a4Photo
                ? StandardPhotoPresets.a4
                : StandardPhotoPresets.passport));

    final personIdx = state.groups.length + 1;
    debugPrint('[FastPrint Photo] ✂️ Opening CropEditorModal for Person $personIdx ($fileName)...');

    final cropRes = await CropEditorModal.show(
      context: context,
      imageBytes: bytes,
      initialCrop: CropRectData.centeredWithAspectRatio(activePreset.aspectRatio),
      initialEnhancement: const EnhancementConfig(),
      targetAspectRatio: activePreset.aspectRatio,
      title: 'Edit Image - Person $personIdx (${activePreset.formattedDimensions})',
    );

    if (cropRes != null && mounted) {
      debugPrint('[FastPrint Photo] ✂️ Crop applied for Person $personIdx. Adding to canvas...');
      await notifier.addPersonPhoto(
        bytes: bytes,
        fileName: fileName,
        cropResult: cropRes,
        preset: activePreset,
        copies: 4,
      );
    } else {
      debugPrint('[FastPrint Photo] ℹ️ Crop canceled for "$fileName".');
    }
  }


  Future<void> _handleNewPhotoSelected(Uint8List bytes, String fileName) async {
    if (!mounted) return;

    // Immediately open Edit Image modal directly without pre-building passport layout
    final cropRes = await CropEditorModal.show(
      context: context,
      imageBytes: bytes,
      initialCrop: CropRectData.centeredWithAspectRatio(StandardPhotoPresets.passport.aspectRatio),
      initialEnhancement: const EnhancementConfig(),
      targetAspectRatio: StandardPhotoPresets.passport.aspectRatio,
      title: 'Edit Image - Passport Photo (${StandardPhotoPresets.passport.formattedDimensions})',
    );

    // Only load and generate passport layout after the user clicks "Apply Crop"
    if (cropRes != null && mounted) {
      await ref.read(passportPhotoProvider.notifier).loadImage(
            bytes,
            fileName,
            initialCropResult: cropRes,
          );
    }
  }

  Future<void> _openMasterEdit() async {
    if (!mounted) return;
    final state = ref.read(passportPhotoProvider);
    final notifier = ref.read(passportPhotoProvider.notifier);
    if (state.groups.isEmpty) return;
    final group = state.activeGroup ?? state.groups.first;
    final bytes = group.rawImageBytes ?? state.rawImageBytes;
    if (bytes == null || bytes.isEmpty) return;

    final cropRes = await CropEditorModal.show(
      context: context,
      imageBytes: bytes,
      initialCrop: group.cropData,
      initialEnhancement: group.enhancement.isDefault ? state.enhancement : group.enhancement,
      targetAspectRatio: group.aspectRatio,
      title: 'Edit Image - ${group.name} (${group.preset.formattedDimensions})',
    );

    if (cropRes != null) {
      await notifier.applyGroupCropResult(group.id, cropRes);
    }
  }

  void _handleKeyEvent(KeyEvent event, PassportPhotoState state, PassportPhotoNotifier notifier) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
        if (state.hasImage) {
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
    final state = ref.watch(passportPhotoProvider);
    final notifier = ref.read(passportPhotoProvider.notifier);
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

    final palette = AppPalette.of(context);

    ref.listen(shouldAutoOpenPhotoEditProvider, (prev, next) {
      if (next && mounted) {
        ref.read(shouldAutoOpenPhotoEditProvider.notifier).state = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(passportPhotoProvider).hasImage) {
            _openMasterEdit();
          }
        });
      }
    });

    ref.listen(pendingPhotoImportProvider, (prev, next) {
      if (next != null && mounted) {
        ref.read(pendingPhotoImportProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleNewPhotoSelected(next.bytes, next.fileName);
          }
        });
      }
    });

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
            if (details.files.isEmpty) return;

            final state = ref.read(passportPhotoProvider);

            if (!state.hasImage) {
              final first = details.files.first;
              final bytes = await first.readAsBytes();
              if (mounted) {
                await _handleNewPhotoSelected(bytes, first.name);
              }
              if (details.files.length > 1 && mounted) {
                for (int i = 1; i < details.files.length; i++) {
                  if (!mounted) break;
                  final f = details.files[i];
                  final b = await f.readAsBytes();
                  await _promptAndAddPersonPhoto(bytes: b, fileName: f.name);
                }
              }
            } else {
              for (final f in details.files) {
                if (!mounted) break;
                final b = await f.readAsBytes();
                await _promptAndAddPersonPhoto(bytes: b, fileName: f.name);
              }
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. Top Header Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      border: Border(bottom: BorderSide(color: palette.divider)),
                      boxShadow: [
                        BoxShadow(
                          color: palette.cardShadow,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: palette.blue,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: palette.blue.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.portrait_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Photo Printing',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: palette.isDark ? palette.blue.withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Text(
                                      '${state.paperPreset.name} (${state.orientation == PaperOrientation.portrait ? "Portrait" : "Landscape"})',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.blue,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => notifier.setPaperPreset(StandardPaperPresets.fourR),
                                    borderRadius: BorderRadius.circular(5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: state.paperPreset.id == '4r'
                                            ? palette.blue
                                            : (palette.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: state.paperPreset.id == '4r' ? palette.blue : palette.cardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        '4R Photo',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: state.paperPreset.id == '4r' ? Colors.white : palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => notifier.setPaperPreset(StandardPaperPresets.a4),
                                    borderRadius: BorderRadius.circular(5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: state.paperPreset.id == 'a4'
                                            ? palette.blue
                                            : (palette.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: state.paperPreset.id == 'a4' ? palette.blue : palette.cardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        'A4 Photo',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: state.paperPreset.id == 'a4' ? Colors.white : palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Auto face framing, multi-photo packing, high-definition 4R & A4 layout',
                                style: TextStyle(fontSize: 11, color: palette.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Center/Right Tool Actions
                        // 1. Undo
                        IconButton(
                          onPressed: state.canUndo ? () => notifier.undo() : null,
                          icon: Icon(
                            Icons.undo_rounded,
                            size: 19,
                            color: state.canUndo ? palette.textPrimary : palette.textMuted,
                          ),
                          tooltip: 'Undo (Ctrl+Z)',
                          visualDensity: VisualDensity.compact,
                        ),

                        // 2. Redo
                        IconButton(
                          onPressed: state.canRedo ? () => notifier.redo() : null,
                          icon: Icon(
                            Icons.redo_rounded,
                            size: 19,
                            color: state.canRedo ? palette.textPrimary : palette.textMuted,
                          ),
                          tooltip: 'Redo (Ctrl+Shift+Z / Ctrl+Y)',
                          visualDensity: VisualDensity.compact,
                        ),

                        const SizedBox(width: 8),

                        // 3. New Photo
                        OutlinedButton.icon(
                          onPressed: _pickNewPhoto,
                          icon: Icon(Icons.camera_alt_outlined, size: 15, color: palette.textPrimary),
                          label: Text(
                            'New',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 4. Open (Photo or .fps Project)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final file = await FilePicker.pickFile(
                              dialogTitle: 'Open Photo or FastPrint Studio Project',
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'fps'],
                            );
                            if (file != null) {
                              final path = file.path;
                              if (path != null && path.toLowerCase().endsWith('.fps')) {
                                await notifier.loadProjectFromFps(filePath: path);
                              } else {
                                final bytes = await file.readAsBytes();
                                if (mounted) {
                                  await _handleNewPhotoSelected(bytes, file.name);
                                }
                              }
                            }
                          },
                          icon: Icon(Icons.folder_open_outlined, size: 15, color: palette.textPrimary),
                          label: Text(
                            'Open',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 5. Save (.fps Project)
                        OutlinedButton.icon(
                          onPressed: state.hasImage
                              ? () async {
                                  final savedPath = await notifier.saveProjectAsFps();
                                  if (savedPath != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text('Saved project: ${p.basename(savedPath)}'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(Icons.save_outlined, size: 15, color: state.hasImage ? palette.textPrimary : palette.textMuted),
                          label: Text(
                            'Save .fps',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: state.hasImage ? palette.textPrimary : palette.textMuted),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 6. Export PDF
                        OutlinedButton.icon(
                          onPressed: state.hasImage ? () => notifier.exportPdf() : null,
                          icon: Icon(Icons.picture_as_pdf_outlined, size: 15, color: state.hasImage ? palette.textPrimary : palette.textMuted),
                          label: Text(
                            'Export PDF',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: state.hasImage ? palette.textPrimary : palette.textMuted),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 7. Close / Reset Project (Returns to Photoshop-style Recents)
                        IconButton(
                          onPressed: state.hasImage ? () => notifier.closeCurrentProject() : null,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: state.hasImage ? palette.textPrimary : palette.textMuted,
                          ),
                          tooltip: 'Close Project (Return to Recents)',
                          visualDensity: VisualDensity.compact,
                        ),

                        const SizedBox(width: 8),

                        // 8. Primary PRINT Action Button
                        ElevatedButton.icon(
                          onPressed: state.hasImage ? () => notifier.printDocument() : null,
                          icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
                          label: const Text('Print (Ctrl+P)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Main Body Content (Always 3-Zone Studio Workspace)
                  Expanded(
                    child: Row(
                      children: [
                        // Left Sidebar Controls (350px wide)
                        Container(
                          width: 350,
                          decoration: BoxDecoration(
                            color: palette.cardBg,
                            border: Border(right: BorderSide(color: palette.divider)),
                          ),
                          child: _LeftControlsSidebar(
                            state: state,
                            notifier: notifier,
                            palette: palette,
                            onChoosePhoto: _pickNewPhoto,
                            onAddPersonPhoto: _pickAdditionalPersonPhoto,
                          ),
                        ),

                        // Center Workspace Canvas Area
                        Expanded(
                          child: Container(
                            color: palette.canvasBg,
                            child: !state.hasImage
                                ? PassportPhotoEmptyState(
                                    palette: palette,
                                    onChoosePhoto: _pickNewPhoto,
                                    onOpenFpsProject: () => notifier.loadProjectFromFps(),
                                    onOpenRecentProject: (recent) async {
                                      final projectData = recent.projectData;
                                      final rawBase64 = projectData['rawImageBase64'] as String?;
                                      if (rawBase64 != null && rawBase64.isNotEmpty) {
                                        final bytes = base64Decode(rawBase64);
                                        final meta = projectData['metadata'] as Map<String, dynamic>? ?? {};
                                        await notifier.restoreProjectFromData(
                                          bytes: bytes,
                                          fileName: recent.fileName,
                                          metadata: meta,
                                        );
                                      }
                                    },
                                  )
                                : Stack(
                                    children: [
                                      Column(
                                        children: [
                                          if (state.currentLayouts.length > 1)
                                            _SheetPaginationBar(
                                              state: state,
                                              notifier: notifier,
                                              palette: palette,
                                            ),
                                          Expanded(
                                            child: state.currentLayout != null
                                                ? PrintPreviewCanvas(
                                                    layout: state.currentLayout!,
                                                    photoFinish: state.photoFinish,
                                                    onClearAll: () => notifier.closeCurrentProject(),
                                                  )
                                                : const Center(child: CircularProgressIndicator()),
                                          ),
                                        ],
                                      ),

                                      // Top animated indeterminate progress indicator
                                      if (state.isProcessing)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: LinearProgressIndicator(
                                            minHeight: 3,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(palette.blue),
                                          ),
                                        ),

                                      // Beautiful floating glassmorphic task animation badge
                                      if (state.isProcessing)
                                        Positioned(
                                          top: state.currentLayouts.length > 1 ? 52 : 14,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              duration: const Duration(milliseconds: 200),
                                              builder: (context, val, child) {
                                                return Transform.scale(
                                                  scale: 0.95 + (0.05 * val),
                                                  child: Opacity(
                                                    opacity: val,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: palette.isDark
                                                      ? const Color(0xF20F172A)
                                                      : const Color(0xF2FFFFFF),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: palette.blue.withValues(alpha: 0.4),
                                                    width: 1.2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.15),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(palette.blue),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 9),
                                                    Text(
                                                      state.processingStatusText.isNotEmpty
                                                          ? state.processingStatusText
                                                          : 'Updating photo layout...',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: palette.textPrimary,
                                                      ),
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

                        // Right Job Summary & Financial Panel (270px wide)
                        Container(
                          width: 270,
                          decoration: BoxDecoration(
                            color: palette.cardBg,
                            border: Border(left: BorderSide(color: palette.divider)),
                          ),
                          child: _PhotoJobSummaryPanel(
                            state: state,
                            notifier: notifier,
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BOTTOM STATUS BAR (Always visible, matching Document Printing)
                  PhotoBottomStatusBar(
                    state: state,
                    currentPrinter: currentPrinter,
                  ),
                ],
              ),

              // Drag Overlay
              if (_isDraggingOver)
                Positioned.fill(
                  child: Container(
                    color: palette.blue.withValues(alpha: 0.85),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.file_download_outlined, size: 48, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Drop photo here to load',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
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

class _LeftControlsSidebar extends StatelessWidget {
  final PassportPhotoState state;
  final PassportPhotoNotifier notifier;
  final AppPalette palette;
  final VoidCallback onChoosePhoto;
  final VoidCallback onAddPersonPhoto;

  const _LeftControlsSidebar({
    required this.state,
    required this.notifier,
    required this.palette,
    required this.onChoosePhoto,
    required this.onAddPersonPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Section 1: Select Photo
        PassportPhotoFileSelectorCard(
          palette: palette,
          fileName: state.fileName,
          imageBytes: state.rawImageBytes,
          hasImage: state.hasImage,
          onChoosePhoto: onChoosePhoto,
        ),
        const SizedBox(height: 14),

        // Section 2: Photo Type(s)
        Text(
          '2. SELECT PHOTO TYPE(S)',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),

        // Photo Type Toggle Buttons (Passport / Passport + Stamp / 4R Photo / A4 Photo)
        Row(
          children: [
            Expanded(
              child: _PhotoTypePill(
                palette: palette,
                icon: Icons.person_outline,
                label: 'Passport',
                isSelected: state.presetMode == PhotoTypePresetMode.passportOnly,
                onTap: () => notifier.setPresetMode(PhotoTypePresetMode.passportOnly),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PhotoTypePill(
                palette: palette,
                icon: Icons.people_outline_rounded,
                label: 'Pass+Stamp',
                isSelected: state.presetMode == PhotoTypePresetMode.passportPlusStamp,
                onTap: () => notifier.setPresetMode(PhotoTypePresetMode.passportPlusStamp),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _PhotoTypePill(
                palette: palette,
                icon: Icons.photo_size_select_actual_outlined,
                label: '4R Photo',
                isSelected: state.presetMode == PhotoTypePresetMode.fourRPhoto,
                onTap: () => notifier.setPresetMode(PhotoTypePresetMode.fourRPhoto),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PhotoTypePill(
                palette: palette,
                icon: Icons.picture_in_picture_outlined,
                label: 'A4 Photo',
                isSelected: state.presetMode == PhotoTypePresetMode.a4Photo,
                onTap: () => notifier.setPresetMode(PhotoTypePresetMode.a4Photo),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Header with Edit Image action above Active Photo Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 14, color: palette.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'PHOTO CARDS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (state.groups.isNotEmpty)
              InkWell(
                onTap: () => _openMasterEdit(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: palette.blueLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 13, color: palette.blue),
                      const SizedBox(width: 5),
                      Text(
                        'Edit Image',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // List of Active Photo Type Cards
        for (final group in state.groups) ...[
          _AddedPhotoTypeCard(
            palette: palette,
            group: group,
            masterImageBytes: state.rawImageBytes ?? Uint8List(0),
            enhancement: state.enhancement,
            showCopiesStepper: state.presetMode != PhotoTypePresetMode.fourRPhoto &&
                state.presetMode != PhotoTypePresetMode.a4Photo,
            onCopiesChanged: (copies) => notifier.updateGroupCopies(group.id, copies),
            onCropResult: (cropRes) => notifier.applyGroupCropResult(group.id, cropRes),
            onRemove: () => notifier.removePhotoGroup(group.id),
          ),
          const SizedBox(height: 8),
        ],

        // + Add Person / Photo Button (Available when in Passport / Pass+Stamp modes)
        if (state.presetMode != PhotoTypePresetMode.fourRPhoto &&
            state.presetMode != PhotoTypePresetMode.a4Photo) ...[
          OutlinedButton.icon(
            onPressed: onAddPersonPhoto,
            icon: Icon(Icons.person_add_alt_1_rounded, size: 14, color: palette.blue),
            label: Text(
              '+ Add Person / Photo',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.blue),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: BorderSide(color: palette.blue.withValues(alpha: 0.4)),
              backgroundColor: palette.blueLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),
        Divider(height: 1, color: palette.divider),
        const SizedBox(height: 14),

        // Section 3: Paper & Layout (Matching Documents Printing page)
        PhotoPaperLayoutPanel(
          state: state,
          notifier: notifier,
          palette: palette,
        ),

        const SizedBox(height: 16),
        Divider(height: 1, color: palette.divider),
        const SizedBox(height: 14),



        // Section 4: Cut Borders
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '4. CUT BORDERS',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.textSecondary, letterSpacing: 0.5),
            ),
            Switch(
              value: state.borderConfig.enabled,
              activeThumbColor: palette.blue,
              onChanged: (val) => notifier.updateBorder(enabled: val),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Outer White Margin
        _BorderSettingDropdown(
          palette: palette,
          label: 'Outer White Margin (mm)',
          value: state.borderConfig.outerBorderMm,
          options: const [0.0, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0],
          onChanged: (val) => notifier.updateBorder(outerBorderMm: val),
        ),
        const SizedBox(height: 8),

        // Stroke after Outer White Margin
        _BorderSettingDropdown(
          palette: palette,
          label: 'Cut Stroke (mm)',
          value: state.borderConfig.innerBorderMm,
          options: const [0.0, 0.15, 0.25, 0.5, 0.8],
          onChanged: (val) => notifier.updateBorder(innerBorderMm: val),
        ),
      ],
    );
  }





  void _openMasterEdit(BuildContext context) async {
    if (state.groups.isEmpty) return;
    final group = state.activeGroup ?? state.groups.first;
    final bytes = group.rawImageBytes ?? state.rawImageBytes;
    if (bytes == null || bytes.isEmpty) return;

    final cropRes = await CropEditorModal.show(
      context: context,
      imageBytes: bytes,
      initialCrop: group.cropData,
      initialEnhancement: group.enhancement.isDefault ? state.enhancement : group.enhancement,
      targetAspectRatio: group.aspectRatio,
      title: 'Edit Image - ${group.name} (${group.preset.formattedDimensions})',
    );

    if (cropRes != null) {
      await notifier.applyGroupCropResult(group.id, cropRes);
    }
  }
}

class _PhotoJobSummaryPanel extends StatelessWidget {
  final PassportPhotoState state;
  final PassportPhotoNotifier notifier;
  final AppPalette palette;

  const _PhotoJobSummaryPanel({
    required this.state,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final copies = state.printJobCopies;
    final totalPhotos = state.totalCopiesCount;
    final sheetsUsed = state.totalSheetsRequired * copies;
    final selling = state.calculatedSellingPrice;
    final material = state.calculatedMaterialCost;
    final ink = state.calculatedInkCost;
    final profit = state.calculatedProfit;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: palette.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Photo Job Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                _specRow('Paper Size', state.paperPreset.name),
                _specRow('Paper Quality', state.photoFinish.label),
                if (state.photoLamination != PhotoLamination.none)
                  _specRow('Lamination', state.photoLamination.label),
                if (state.photoFraming != PhotoFraming.none)
                  _specRow('Frame & Mount', state.photoFraming.label),
                _specRow('Orientation', state.orientation == PaperOrientation.portrait ? 'Portrait' : 'Landscape'),
                _specRow('Total Photos', '$totalPhotos photos / sheet'),
                _specRow('Sheets Used', '$sheetsUsed ${sheetsUsed == 1 ? 'Sheet' : 'Sheets'}'),
                _specRow('Resolution', '300 DPI High-Def'),

                const SizedBox(height: 10),
                Divider(height: 1, color: palette.divider),
                const SizedBox(height: 10),

                // Copies Stepper Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Job Copies',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: copies > 1 ? () => notifier.setPrintJobCopies(copies - 1) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.remove, size: 13, color: copies > 1 ? palette.textPrimary : palette.textMuted),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$copies',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                            ),
                          ),
                          InkWell(
                            onTap: () => notifier.setPrintJobCopies(copies + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.add, size: 13, color: palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Financial Breakdown Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _financialRow('Selling Price', '₹${selling.toStringAsFixed(0)}', isBold: true, color: palette.blue),
                      const SizedBox(height: 4),
                      _financialRow('Material Cost (${state.photoFinish.label.split(' ')[0]} + Finish)', '-₹${material.toStringAsFixed(1)}', color: palette.textSecondary),
                      const SizedBox(height: 4),
                      _financialRow('Estimated Ink', '-₹${ink.toStringAsFixed(1)}', color: palette.textSecondary),
                      const SizedBox(height: 6),
                      Divider(height: 1, color: palette.divider),
                      const SizedBox(height: 6),
                      _financialRow('Estimated Profit', '₹${profit.toStringAsFixed(1)}', isBold: true, color: palette.green, fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Primary Print Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: state.hasImage ? () => notifier.printDocument() : null,
              icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
              label: const Text(
                'PRINT NOW (Ctrl+P)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.green,
                disabledBackgroundColor: palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary)),
        ],
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 11}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: fontSize, color: palette.textSecondary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: color ?? palette.textPrimary)),
      ],
    );
  }
}

class _PhotoTypePill extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PhotoTypePill({
    required this.palette,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.blueLight : palette.cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? palette.blue : palette.cardBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? palette.blue : palette.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? palette.blue : palette.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddedPhotoTypeCard extends StatelessWidget {
  final AppPalette palette;
  final PhotoGroup group;
  final Uint8List masterImageBytes;
  final EnhancementConfig? enhancement;
  final bool showCopiesStepper;
  final ValueChanged<int> onCopiesChanged;
  final ValueChanged<CropResult> onCropResult;
  final VoidCallback onRemove;

  const _AddedPhotoTypeCard({
    required this.palette,
    required this.group,
    required this.masterImageBytes,
    this.enhancement,
    this.showCopiesStepper = true,
    required this.onCopiesChanged,
    required this.onCropResult,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail Preview
          GestureDetector(
            onTap: () => _openCrop(context),
            child: Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: palette.cardBorder),
                color: palette.canvasBg,
              ),
              clipBehavior: Clip.antiAlias,
              child: group.processedBytes != null
                  ? Image.memory(group.processedBytes!, fit: BoxFit.cover)
                  : Icon(Icons.person, color: palette.textMuted),
            ),
          ),
          const SizedBox(width: 10),

          // Details & Copies Counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
                Text(
                  'Size: ${group.preset.formattedDimensions}',
                  style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                ),
                if (showCopiesStepper) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text('Copies', style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      _CounterWidget(
                        palette: palette,
                        value: group.copiesCount,
                        onMinus: () => onCopiesChanged(group.copiesCount - 1),
                        onPlus: () => onCopiesChanged(group.copiesCount + 1),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Single Sheet Full Photo',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: palette.blue),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quick Edit Image Icon
          IconButton(
            onPressed: () => _openCrop(context),
            icon: Icon(Icons.edit_rounded, size: 16, color: palette.blue),
            tooltip: 'Edit Image (Crop & Adjustments)',
            visualDensity: VisualDensity.compact,
          ),

          // Direct Remove Photo Icon
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded, size: 17, color: palette.red),
            tooltip: 'Remove Photo',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _openCrop(BuildContext context) async {
    final bytes = group.rawImageBytes ?? masterImageBytes;
    if (bytes.isEmpty) return;
    final cropRes = await CropEditorModal.show(
      context: context,
      imageBytes: bytes,
      initialCrop: group.cropData,
      initialEnhancement: group.enhancement.isDefault ? (enhancement ?? const EnhancementConfig()) : group.enhancement,
      targetAspectRatio: group.aspectRatio,
      title: 'Edit Image - ${group.name} (${group.preset.formattedDimensions})',
    );
    if (cropRes != null) {
      onCropResult(cropRes);
    }
  }
}

class _CounterWidget extends StatelessWidget {
  final AppPalette palette;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CounterWidget({
    required this.palette,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > 1 ? onMinus : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Icon(Icons.remove, size: 12, color: value > 1 ? palette.textPrimary : palette.textMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: palette.divider)),
            ),
            child: Text(
              '$value',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: palette.textPrimary),
            ),
          ),
          InkWell(
            onTap: onPlus,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Icon(Icons.add, size: 12, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}


class _BorderSettingDropdown extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final double value;
  final List<double> options;
  final ValueChanged<double> onChanged;

  const _BorderSettingDropdown({
    required this.palette,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.textPrimary, fontWeight: FontWeight.w500)),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: options.contains(value) ? value : options.first,
              items: options.map((opt) {
                return DropdownMenuItem<double>(
                  value: opt,
                  child: Text(opt.toStringAsFixed(2), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) onChanged(newVal);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetPaginationBar extends StatelessWidget {
  final PassportPhotoState state;
  final PassportPhotoNotifier notifier;
  final AppPalette palette;

  const _SheetPaginationBar({
    required this.state,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final totalSheets = state.currentLayouts.length;
    final currentIndex = state.activeSheetIndex;
    final currentLayout = state.currentLayout;
    final currentItemCount = currentLayout?.items.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: palette.blueLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_rounded, size: 14, color: palette.blue),
                const SizedBox(width: 6),
                Text(
                  'Sheet ${currentIndex + 1} of $totalSheets',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '($currentItemCount photos on this sheet • ${state.totalCopiesCount} total across sheets)',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: currentIndex > 0 ? () => notifier.prevSheet() : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            tooltip: 'Previous Sheet',
            visualDensity: VisualDensity.compact,
            color: currentIndex > 0 ? palette.textPrimary : palette.textMuted,
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalSheets, (idx) {
              final isSelected = idx == currentIndex;
              final sheetItems = state.currentLayouts[idx].items.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => notifier.setActiveSheetIndex(idx),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.blue : palette.cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? palette.blue : palette.cardBorder,
                      ),
                    ),
                    child: Text(
                      'Sheet ${idx + 1} ($sheetItems)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: currentIndex < totalSheets - 1 ? () => notifier.nextSheet() : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            tooltip: 'Next Sheet',
            visualDensity: VisualDensity.compact,
            color: currentIndex < totalSheets - 1 ? palette.textPrimary : palette.textMuted,
          ),
        ],
      ),
    );
  }
}

