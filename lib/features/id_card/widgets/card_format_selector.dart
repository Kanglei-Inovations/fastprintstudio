import 'package:flutter/material.dart';
import '../../../core/models/id_card_preset.dart';
import '../../../core/models/id_card_workflow_type.dart';
import '../theme/id_card_palette.dart';

class CardFormatSelector extends StatelessWidget {
  final IdCardPalette palette;
  final IDCardPreset? selectedPreset;
  final ValueChanged<IDCardPreset>? onSelectPreset;
  final IdCardWorkflowType workflowType;
  final ValueChanged<IdCardWorkflowType> onSelectWorkflow;
  final VoidCallback? onOpenCalibration;

  const CardFormatSelector({
    super.key,
    required this.palette,
    this.selectedPreset,
    this.onSelectPreset,
    required this.workflowType,
    required this.onSelectWorkflow,
    this.onOpenCalibration,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. WORKFLOW MODE SELECTION (3 Distinct Output Modes with Unique Colors)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.isDark
                    ? palette.blue.withValues(alpha: 0.18)
                    : palette.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.precision_manufacturing_rounded, size: 14, color: palette.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OUTPUT / PRODUCTION METHOD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.textSecondary,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // Mode 1: Lamination Card (Emerald Theme)
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.photoPaperLamination,
                title: 'Lamination Card',
                price: '₹50',
                subtitle: 'Fold & Laminate',
                icon: Icons.photo_library_rounded,
                accentColor: palette.green,
                isSelected: workflowType == IdCardWorkflowType.photoPaperLamination,
              ),
            ),
            const SizedBox(width: 6),

            // Mode 2: Epson L805 Card (Royal Blue Theme)
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.epsonL805,
                title: 'Epson L805 Card',
                price: '₹100',
                subtitle: 'A4 PVC Tray',
                icon: Icons.badge_rounded,
                accentColor: palette.blue,
                isSelected: workflowType == IdCardWorkflowType.epsonL805,
              ),
            ),
            const SizedBox(width: 6),

            // Mode 3: Dragon Sheet (Vibrant Amber Theme)
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.dragonSheet,
                title: 'Dragon Sheet',
                price: '₹100',
                subtitle: '200×300mm Sheet',
                icon: Icons.grid_view_rounded,
                accentColor: palette.orange,
                isSelected: workflowType == IdCardWorkflowType.dragonSheet,
              ),
            ),
          ],
        ),

        // 2. EPSON L805 TRAY CALIBRATION (Setup popup removed, calibration preserved)
        if (workflowType == IdCardWorkflowType.epsonL805 && onOpenCalibration != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onOpenCalibration,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: palette.isDark ? palette.cardBgElevated : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: palette.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(Icons.tune_rounded, size: 14, color: palette.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tray Output Calibration',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          'Fine-tune physical slot print alignment (mm)',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Calibrate',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

      ],
    );
  }

  Widget _buildWorkflowCard({
    required IdCardWorkflowType type,
    required String title,
    required String price,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSelectWorkflow(type),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (palette.isDark ? accentColor.withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.08))
              : palette.cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? accentColor : palette.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : (palette.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(icon, size: 14, color: isSelected ? accentColor : palette.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? accentColor : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? (palette.isDark ? Colors.white : accentColor) : palette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
