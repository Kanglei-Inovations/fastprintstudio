import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/id_card_palette.dart';

class IdCardFileSelectorCard extends StatelessWidget {
  final IdCardPalette palette;
  final String? fileName;
  final Uint8List? fileBytes;
  final bool isPdf;
  final bool hasSource;
  final VoidCallback onUploadPdf;
  final VoidCallback onUploadImage;
  final VoidCallback onChangeFile;
  final VoidCallback? onAddCard;

  const IdCardFileSelectorCard({
    super.key,
    required this.palette,
    required this.fileName,
    required this.fileBytes,
    required this.isPdf,
    required this.hasSource,
    required this.onUploadPdf,
    required this.onUploadImage,
    required this.onChangeFile,
    this.onAddCard,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "1. Select ID Document"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? palette.blue.withValues(alpha: 0.18)
                          : palette.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.file_present_rounded, size: 14, color: palette.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1. SELECT ID DOCUMENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onAddCard != null)
              Tooltip(
                message: 'Add more ID card / person',
                child: InkWell(
                  onTap: onAddCard,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? palette.blue.withValues(alpha: 0.18)
                          : palette.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: palette.blue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: palette.blue),
                        const SizedBox(width: 3),
                        Text(
                          '+ Add Card',
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
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (!hasSource)
          // Empty Upload Drop Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.blue.withValues(alpha: 0.2),
                        palette.purple.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.isDark ? palette.blue.withValues(alpha: 0.35) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Icon(Icons.badge_rounded, color: palette.blue, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'Drag & drop ID card here',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Supports Aadhaar, PAN, Voter ID, or License (PDF, JPG, PNG)',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onUploadPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.white),
                        label: const Text(
                          'Upload PDF',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onUploadImage,
                        icon: Icon(Icons.image_rounded, size: 14, color: palette.blue),
                        label: Text(
                          'Upload Image',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.blue),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: BorderSide(color: palette.blue.withValues(alpha: 0.4)),
                          backgroundColor: palette.blue.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          // File Loaded Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge (PDF or Image)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPdf ? 'PDF' : 'IMAGE',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // File Name
                    Expanded(
                      child: Text(
                        fileName ?? 'ID_Card_Document',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // File Size & Status Pill
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fileBytes != null) ...[
                            Text(
                              _formatSize(fileBytes!.length),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: palette.isDark ? palette.green.withValues(alpha: 0.2) : palette.greenLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: palette.isDark ? palette.green.withValues(alpha: 0.35) : const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 10, color: palette.green),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Ready to Print',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.green,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Change File Button
                        InkWell(
                          onTap: onChangeFile,
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: palette.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_rounded, size: 12, color: palette.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
