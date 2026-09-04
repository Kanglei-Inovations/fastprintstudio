import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';

class PassportPhotoFileSelectorCard extends StatelessWidget {
  final AppPalette palette;
  final String? fileName;
  final Uint8List? imageBytes;
  final bool hasImage;
  final VoidCallback onChoosePhoto;

  const PassportPhotoFileSelectorCard({
    super.key,
    required this.palette,
    required this.fileName,
    required this.imageBytes,
    required this.hasImage,
    required this.onChoosePhoto,
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
        // Section Title: "1. Select Photo"
        Text(
          '1. Select Photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        if (!hasImage)
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
                  child: Icon(Icons.add_a_photo_outlined, color: palette.blue, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'Drag & drop customer photo here',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supports JPG, PNG, WEBP, BMP (Face auto-framed)',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onChoosePhoto,
                  icon: const Icon(Icons.file_open_rounded, size: 14, color: Colors.white),
                  label: const Text(
                    'Choose Photo',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          )
        else
          // Photo Loaded Card
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
                    // Badge (PHOTO)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA), // Purple Photo
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'PHOTO',
                        style: TextStyle(
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
                        fileName ?? 'Customer_Photo.jpg',
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
                    Row(
                      children: [
                        if (imageBytes != null)
                          Text(
                            _formatSize(imageBytes!.length),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
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
                          ),
                        ),
                      ],
                    ),

                    // Change Photo Button
                    InkWell(
                      onTap: onChoosePhoto,
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
