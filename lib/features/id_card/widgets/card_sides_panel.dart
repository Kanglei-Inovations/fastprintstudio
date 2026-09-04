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
              child: Text(
                'Card Sides',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasBothSides
                    ? (palette.isDark ? palette.green.withValues(alpha: 0.15) : palette.greenLight)
                    : palette.pillBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasBothSides ? palette.green : palette.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasBothSides ? 'Front + Back' : 'Front Only',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: hasBothSides ? palette.green : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. FRONT Card Item
        _SideCardTile(
          palette: palette,
          title: 'FRONT SIDE',
          dimensions: preset.formattedDimensions,
          imageBytes: frontBytes,
          onAdjustCrop: onAdjustFrontCrop,
        ),

        const SizedBox(height: 8),

        // 2. BACK Side Container
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasBothSides ? palette.cardBorder : palette.cardBorder.withValues(alpha: 0.5),
            ),
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
                        Icon(
                          Icons.flip_to_back_rounded,
                          size: 15,
                          color: hasBothSides ? palette.blue : palette.textMuted,
                        ),
                        const SizedBox(width: 6),
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
                        activeThumbColor: palette.blue,
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

                // Back Card Tile
                _SideCardTile(
                  palette: palette,
                  title: 'BACK SIDE',
                  dimensions: preset.formattedDimensions,
                  imageBytes: backBytes,
                  onAdjustCrop: onAdjustBackCrop,
                ),

                const SizedBox(height: 8),

                // Order Toggle Button: Front on Top vs Back on Top
                InkWell(
                  onTap: onToggleSwapOrder,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.pillBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.pillBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_vert_rounded, size: 14, color: palette.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          swapFrontBack ? 'Order: Back on Top' : 'Order: Front on Top',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
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
  final String dimensions;
  final Uint8List? imageBytes;
  final VoidCallback onAdjustCrop;

  const _SideCardTile({
    required this.palette,
    required this.title,
    required this.dimensions,
    required this.imageBytes,
    required this.onAdjustCrop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          // Thumbnail Preview
          GestureDetector(
            onTap: onAdjustCrop,
            child: Container(
              width: 64,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.cardBorder),
                color: palette.pillBg,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Icon(Icons.badge_outlined, color: palette.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Side Label + Dimensions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dimensions,
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Adjust Crop Action Button
          OutlinedButton.icon(
            onPressed: onAdjustCrop,
            icon: Icon(Icons.crop_rounded, size: 13, color: palette.blue),
            label: Text(
              'Adjust Crop',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: palette.blue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              side: BorderSide(
                color: palette.isDark ? palette.blue.withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
              ),
              backgroundColor: palette.isDark ? palette.blue.withValues(alpha: 0.12) : palette.blueLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ],
      ),
    );
  }
}
