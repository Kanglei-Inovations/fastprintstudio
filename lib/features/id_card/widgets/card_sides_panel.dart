import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/models/id_card_preset.dart';
import '../theme/id_card_palette.dart';

class CardSidesPanel extends StatelessWidget {
  final IdCardPalette palette;
  final IDCardPreset preset;
  final Uint8List? frontBytes;
  final Uint8List? backBytes;
  final bool hasBothSides;
  final bool swapFrontBack;
  final VoidCallback onAdjustFrontCrop;
  final VoidCallback onAdjustBackCrop;
  final ValueChanged<bool> onToggleBothSides;
  final VoidCallback onToggleSwapOrder;
  final VoidCallback? onUploadFrontFile;
  final VoidCallback? onUploadBackFile;
  final int totalPages;
  final int backPageIndex;
  final ValueChanged<int>? onSelectBackPage;

  const CardSidesPanel({
    super.key,
    required this.palette,
    required this.preset,
    required this.frontBytes,
    required this.backBytes,
    required this.hasBothSides,
    required this.swapFrontBack,
    required this.onAdjustFrontCrop,
    required this.onAdjustBackCrop,
    required this.onToggleBothSides,
    required this.onToggleSwapOrder,
    this.onUploadFrontFile,
    this.onUploadBackFile,
    this.totalPages = 1,
    this.backPageIndex = 0,
    this.onSelectBackPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title + Status badge
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
                          ? palette.teal.withValues(alpha: 0.18)
                          : palette.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.flip_rounded, size: 14, color: palette.teal),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Card Sides & Crop',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: hasBothSides
                    ? (palette.isDark ? palette.green.withValues(alpha: 0.18) : palette.greenLight)
                    : palette.pillBg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: hasBothSides
                      ? (palette.isDark ? palette.green.withValues(alpha: 0.4) : const Color(0xFFA7F3D0))
                      : palette.pillBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasBothSides ? palette.green : palette.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasBothSides ? 'Duplex (F+B)' : 'Front Only',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: hasBothSides ? palette.green : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 1. FRONT Card Item (Emerald Theme)
        _SideCardTile(
          palette: palette,
          title: 'FRONT SIDE',
          sideBadgeColor: palette.green,
          sideIcon: Icons.badge_rounded,
          dimensions: preset.formattedDimensions,
          imageBytes: frontBytes,
          onAdjustCrop: onAdjustFrontCrop,
          onUploadFile: onUploadFrontFile,
          uploadTooltip: 'Upload/Replace Front File',
        ),

        const SizedBox(height: 8),

        // 2. BACK Side Container (Violet / Purple Theme)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasBothSides
                  ? (palette.isDark ? palette.purple.withValues(alpha: 0.4) : const Color(0xFFDDD6FE))
                  : palette.cardBorder,
              width: hasBothSides ? 1.4 : 1.0,
            ),
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
              // Include Back Side Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: hasBothSides
                                ? (palette.isDark
                                    ? palette.purple.withValues(alpha: 0.25)
                                    : palette.purpleLight)
                                : palette.pillBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.flip_to_back_rounded,
                            size: 14,
                            color: hasBothSides ? palette.purple : palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Include Back Side',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: hasBothSides,
                        activeThumbColor: palette.purple,
                        activeTrackColor: palette.isDark
                            ? palette.purple.withValues(alpha: 0.4)
                            : palette.purpleLight,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: onToggleBothSides,
                      ),
                    ),
                  ),
                ],
              ),

              if (hasBothSides) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: palette.divider),
                const SizedBox(height: 8),

                // Multi-Page Back Page Selector
                if (totalPages > 1 && onSelectBackPage != null) ...[
                  Row(
                    children: [
                      Text(
                        'Back Page: ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      for (int p = 0; p < totalPages; p++) ...[
                        InkWell(
                          onTap: () => onSelectBackPage!(p),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: backPageIndex == p
                                  ? (palette.isDark ? palette.purple.withValues(alpha: 0.3) : palette.purpleLight)
                                  : palette.pillBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: backPageIndex == p ? palette.purple : palette.pillBorder,
                                width: backPageIndex == p ? 1.2 : 1.0,
                              ),
                            ),
                            child: Text(
                              'P${p + 1}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: backPageIndex == p ? FontWeight.w800 : FontWeight.w500,
                                color: backPageIndex == p ? palette.purple : palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Back Card Tile
                _SideCardTile(
                  palette: palette,
                  title: 'BACK SIDE',
                  sideBadgeColor: palette.purple,
                  sideIcon: Icons.featured_play_list_rounded,
                  dimensions: preset.formattedDimensions,
                  imageBytes: backBytes,
                  onAdjustCrop: onAdjustBackCrop,
                  onUploadFile: onUploadBackFile,
                  uploadTooltip: 'Upload/Replace Back File (Image or PDF)',
                ),

                const SizedBox(height: 8),

                // Order Toggle Button: Front on Top vs Back on Top
                InkWell(
                  onTap: onToggleSwapOrder,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? palette.orange.withValues(alpha: 0.12)
                          : palette.orangeLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: palette.isDark
                            ? palette.orange.withValues(alpha: 0.35)
                            : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_vert_rounded, size: 15, color: palette.orange),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            swapFrontBack ? 'Order: Back on Top' : 'Order: Front on Top',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: palette.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SideCardTile extends StatelessWidget {
  final IdCardPalette palette;
  final String title;
  final Color sideBadgeColor;
  final IconData sideIcon;
  final String dimensions;
  final Uint8List? imageBytes;
  final VoidCallback onAdjustCrop;
  final VoidCallback? onUploadFile;
  final String? uploadTooltip;

  const _SideCardTile({
    required this.palette,
    required this.title,
    required this.sideBadgeColor,
    required this.sideIcon,
    required this.dimensions,
    required this.imageBytes,
    required this.onAdjustCrop,
    this.onUploadFile,
    this.uploadTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail Preview with nice aspect ratio
          GestureDetector(
            onTap: onAdjustCrop,
            child: Container(
              width: 56,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: imageBytes != null
                      ? sideBadgeColor.withValues(alpha: 0.4)
                      : palette.cardBorder,
                  width: 1.2,
                ),
                color: palette.pillBg,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Center(
                      child: Icon(sideIcon, color: palette.textMuted, size: 18),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Side Label + Dimensions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: sideBadgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: sideBadgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dimensions,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Adjust Crop Action Button
          OutlinedButton(
            onPressed: onAdjustCrop,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: sideBadgeColor.withValues(alpha: 0.4),
              ),
              backgroundColor: sideBadgeColor.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.crop_rounded, size: 12, color: sideBadgeColor),
                const SizedBox(width: 3),
                Text(
                  'Crop',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sideBadgeColor,
                  ),
                ),
              ],
            ),
          ),
          if (onUploadFile != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: uploadTooltip ?? 'Upload File',
              child: OutlinedButton(
                onPressed: onUploadFile,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: sideBadgeColor.withValues(alpha: 0.4),
                  ),
                  backgroundColor: sideBadgeColor.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Icon(Icons.file_upload_outlined, size: 13, color: sideBadgeColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
