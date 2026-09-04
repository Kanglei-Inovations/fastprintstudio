import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/id_card_provider.dart';
import '../../services/pdf/pdf_rasterizer.dart';
import '../documents/providers/document_provider.dart';

class OpenWithLandingScreen extends ConsumerStatefulWidget {
  const OpenWithLandingScreen({super.key});

  @override
  ConsumerState<OpenWithLandingScreen> createState() => _OpenWithLandingScreenState();
}

class _OpenWithLandingScreenState extends ConsumerState<OpenWithLandingScreen> {
  bool _isDragging = false;

  Future<void> _pickAnotherFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'webp', 'bmp', 'tif', 'tiff',
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
        ],
      );

      if (result != null && result.path != null) {
        final path = result.path!;
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final stat = await file.stat();
          final ext = p.extension(path).toLowerCase();
          ref.read(landingFileProvider.notifier).state = LandingFileData(
            filePath: path,
            fileName: p.basename(path),
            bytes: bytes,
            fileSizeBytes: stat.size,
            extension: ext,
            modifiedAt: stat.modified,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking replacement file: $e');
    }
  }

  Future<void> _continueToPhoto(LandingFileData file) async {
    Uint8List? imageBytes;
    if (file.isImage) {
      imageBytes = file.bytes;
    } else if (file.isPdf) {
      try {
        imageBytes = await PdfRasterizer.rasterizePdfPage(pdfBytes: file.bytes);
      } catch (e) {
        debugPrint('Error rasterizing PDF for photo printing: $e');
      }
    }

    if (imageBytes != null) {
      ref.read(pendingPhotoImportProvider.notifier).state = (bytes: imageBytes, fileName: file.fileName);
      ref.read(landingFileProvider.notifier).state = null;
      ref.read(navIndexProvider.notifier).state = 2; // Photo Printing Screen
    }
  }

  Future<void> _continueToIdCard(LandingFileData file) async {
    await ref.read(idCardProvider.notifier).loadDocument(
          bytes: file.bytes,
          fileName: file.fileName,
          isPdf: file.isPdf,
        );
    ref.read(landingFileProvider.notifier).state = null;
    ref.read(navIndexProvider.notifier).state = 1; // ID Card Screen
  }

  Future<void> _continueToDocument(LandingFileData file) async {
    await ref.read(documentPrintProvider.notifier).loadDocument(
          bytes: file.bytes,
          fileName: file.fileName,
        );
    ref.read(landingFileProvider.notifier).state = null;
    ref.read(navIndexProvider.notifier).state = 3; // Document Screen
  }

  void _cancelToDashboard() {
    ref.read(landingFileProvider.notifier).state = null;
    ref.read(navIndexProvider.notifier).state = 0; // Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final landingFile = ref.watch(landingFileProvider);

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          final path = file.path;
          final bytes = await file.readAsBytes();
          final ext = p.extension(path).toLowerCase();
          ref.read(landingFileProvider.notifier).state = LandingFileData(
            filePath: path,
            fileName: file.name,
            bytes: bytes,
            fileSizeBytes: bytes.length,
            extension: ext,
            modifiedAt: DateTime.now(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Top Badges & Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                const Text(
                                  'OPEN WITH FASTPRINT STUDIO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Where would you like to continue?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Select the studio matching your printing goal. We will load your file and prepare all tools and presets automatically.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // 2. Landed File Details Hero Card
                      if (landingFile != null)
                        _buildFileHeroCard(context, landingFile, cardBg, cardBorder, textPrimary, textSecondary)
                      else
                        _buildNoFileCard(context, cardBg, cardBorder, textPrimary, textSecondary),

                      const SizedBox(height: 32),

                      // 3. The 3 Target Studios Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 780;
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _StudioOptionCard(
                                        title: 'Photo Printing',
                                        badge: 'PASSPORT & 4R',
                                        accentColor: const Color(0xFF0284C7), // Blue / Sky
                                        icon: Icons.portrait_rounded,
                                        description:
                                            'Face detection & crop, 4R/A4 photo sheets, Glossy/Matte finishes, and mixed Passport + Stamp size layouts.',
                                        recommendedFor: 'Photos, Passports, Portraits & Albums',
                                        buttonLabel: 'Open in Photo Studio',
                                        onSelect: landingFile != null ? () => _continueToPhoto(landingFile) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StudioOptionCard(
                                        title: 'Aadhaar / ID Card',
                                        badge: 'PVC & SMART CARD',
                                        accentColor: const Color(0xFF059669), // Emerald
                                        icon: Icons.badge_rounded,
                                        description:
                                            'Auto-split front & back, 1-click CR80 resizing, dual-card Epson L805 PVC tray, and lamination border margins.',
                                        recommendedFor: 'Aadhaar, PAN, Voter, Student & Staff Cards',
                                        buttonLabel: 'Open in ID Card Studio',
                                        onSelect: landingFile != null ? () => _continueToIdCard(landingFile) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StudioOptionCard(
                                        title: 'Document Printing',
                                        badge: 'PDF, DOCX & XEROX',
                                        accentColor: const Color(0xFF4F46E5), // Indigo
                                        icon: Icons.description_rounded,
                                        description:
                                            'Multi-page preview, booklet & 2-sided duplex printing, N-up page layouts, and instant B&W / Color rate calculations.',
                                        recommendedFor: 'PDFs, Word Docs, Reports & Receipts',
                                        buttonLabel: 'Open in Document Studio',
                                        onSelect: landingFile != null ? () => _continueToDocument(landingFile) : null,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _StudioOptionCard(
                                      title: 'Photo Printing',
                                      badge: 'PASSPORT & 4R',
                                      accentColor: const Color(0xFF0284C7),
                                      icon: Icons.portrait_rounded,
                                      description:
                                          'Face detection & crop, 4R/A4 photo sheets, Glossy/Matte finishes, and mixed Passport + Stamp size layouts.',
                                      recommendedFor: 'Photos, Passports, Portraits & Albums',
                                      buttonLabel: 'Open in Photo Studio',
                                      onSelect: landingFile != null ? () => _continueToPhoto(landingFile) : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StudioOptionCard(
                                      title: 'Aadhaar / ID Card',
                                      badge: 'PVC & SMART CARD',
                                      accentColor: const Color(0xFF059669),
                                      icon: Icons.badge_rounded,
                                      description:
                                          'Auto-split front & back, 1-click CR80 resizing, dual-card Epson L805 PVC tray, and lamination border margins.',
                                      recommendedFor: 'Aadhaar, PAN, Voter, Student & Staff Cards',
                                      buttonLabel: 'Open in ID Card Studio',
                                      onSelect: landingFile != null ? () => _continueToIdCard(landingFile) : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StudioOptionCard(
                                      title: 'Document Printing',
                                      badge: 'PDF, DOCX & XEROX',
                                      accentColor: const Color(0xFF4F46E5),
                                      icon: Icons.description_rounded,
                                      description:
                                          'Multi-page preview, booklet & 2-sided duplex printing, N-up page layouts, and instant B&W / Color rate calculations.',
                                      recommendedFor: 'PDFs, Word Docs, Reports & Receipts',
                                      buttonLabel: 'Open in Document Studio',
                                      onSelect: landingFile != null ? () => _continueToDocument(landingFile) : null,
                                    ),
                                  ],
                                );
                        },
                      ),

                      const SizedBox(height: 32),

                      // 4. Bottom Cancel & Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _cancelToDashboard,
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Return to Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _pickAnotherFile,
                            icon: const Icon(Icons.folder_open_rounded, size: 16),
                            label: const Text('Choose Different File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: BorderSide(color: cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Drag & drop overlay
            if (_isDragging)
              Container(
                color: AppColors.primary.withValues(alpha: 0.85),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_rounded, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Drop your file here to open in FastPrint Studio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeroCard(
    BuildContext context,
    LandingFileData file,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 860),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left File Thumbnail Preview
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: file.isImage
                ? Image.memory(
                    file.bytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.image_rounded, size: 36, color: textSecondary),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          file.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                          size: 38,
                          color: file.isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.formatBadge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: file.isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 18),

          // Center File Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: file.isImage
                            ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                            : (file.isPdf ? const Color(0xFFEF4444).withValues(alpha: 0.12) : const Color(0xFF3B82F6).withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        file.formatBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: file.isImage
                              ? const Color(0xFF0284C7)
                              : (file.isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      file.formattedFileSize,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: textSecondary)),
                    const SizedBox(width: 8),
                    Text(
                      file.formattedDate,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.filePath,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Change File Button
          OutlinedButton.icon(
            onPressed: _pickAnotherFile,
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              side: BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFileCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 860),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.file_upload_outlined, size: 28, color: AppColors.primary),
          const SizedBox(width: 14),
          Text(
            'No file currently selected. Drag a file here or browse to start.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
          ),
          const SizedBox(width: 18),
          ElevatedButton.icon(
            onPressed: _pickAnotherFile,
            icon: const Icon(Icons.folder_open_rounded, size: 16, color: Colors.white),
            label: const Text('Browse File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioOptionCard extends StatefulWidget {
  final String title;
  final String badge;
  final Color accentColor;
  final IconData icon;
  final String description;
  final String recommendedFor;
  final String buttonLabel;
  final VoidCallback? onSelect;

  const _StudioOptionCard({
    required this.title,
    required this.badge,
    required this.accentColor,
    required this.icon,
    required this.description,
    required this.recommendedFor,
    required this.buttonLabel,
    required this.onSelect,
  });

  @override
  State<_StudioOptionCard> createState() => _StudioOptionCardState();
}

class _StudioOptionCardState extends State<_StudioOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onSelect != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? widget.accentColor : cardBorder,
              width: _isHovered ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.accentColor.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon & Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Icon(widget.icon, size: 28, color: widget.accentColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _isHovered ? widget.accentColor : textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 12.5,
                  color: textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Recommended Tag
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: widget.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.recommendedFor,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onSelect,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  label: Text(
                    widget.buttonLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: _isHovered ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
