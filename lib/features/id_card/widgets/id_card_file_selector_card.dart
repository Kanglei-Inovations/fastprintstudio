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
        // Section Title: "1. Select File"
        Text(
          '1. Select File',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        if (!hasSource)
          // Empty Upload Drop Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.blue.withValues(alpha: 0.15) : palette.blueLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Icon(Icons.badge_outlined, color: palette.blue, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'Drag & drop ID card here',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supports Aadhaar, PAN, or ID card in PDF, JPG, PNG, WEBP',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onUploadPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Colors.white),
                      label: const Text(
                        'Upload PDF',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 1,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onUploadImage,
                      icon: Icon(Icons.image_outlined, size: 14, color: palette.textPrimary),
                      label: Text(
                        'Upload Image',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(color: palette.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        backgroundColor: palette.cardBg,
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
                      child: Text(
                        isPdf ? 'PDF' : 'IMAGE',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: palette.isDark ? palette.green.withValues(alpha: 0.2) : palette.greenLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Change File Button
                    InkWell(
                      onTap: onChangeFile,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 12, color: palette.blue),
                            const SizedBox(width: 3),
                            Text(
                              'Change',
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
              ],
            ),
          ),
      ],
    );
  }
}
