import 'package:flutter/material.dart';
import '../../../core/models/id_card_workflow_type.dart';
import '../../../core/models/paper_preset.dart';
import '../theme/id_card_palette.dart';

/// Paper & Layout sidebar panel for ID Card Printing with colorful, intuitive controls
class IdCardPaperLayoutPanel extends StatelessWidget {
  final IdCardPalette palette;
  final PaperPreset? paperPreset;
  final double gapMm;
  final double marginMm;
  final IdCardWorkflowType workflowType;
  final bool showDragonCutLines;
  final ValueChanged<PaperPreset>? onPaperPresetChanged;
  final ValueChanged<double> onGapChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<bool>? onToggleDragonCutLines;

  const IdCardPaperLayoutPanel({
    super.key,
    required this.palette,
    this.paperPreset,
    required this.gapMm,
    required this.marginMm,
    required this.workflowType,
    this.showDragonCutLines = true,
    this.onPaperPresetChanged,
    required this.onGapChanged,
    required this.onMarginChanged,
    this.onToggleDragonCutLines,
  });

  @override
  Widget build(BuildContext context) {
    final isL805 = workflowType == IdCardWorkflowType.epsonL805;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "SPACING & MARGINS"
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.isDark
                    ? palette.teal.withValues(alpha: 0.18)
                    : palette.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.tune_rounded, size: 14, color: palette.teal),
            ),
            const SizedBox(width: 8),
            Text(
              'SPACING & MARGINS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: palette.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
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
              if (isL805) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.blue.withValues(alpha: 0.12) : palette.blueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: palette.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A4 PVC Tray Carrier automatically aligns cards to physical slots with 0 margins.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Spacing & Margin
                Row(
                  children: [
                    Expanded(
                      child: _buildStepperField(
                        icon: Icons.format_line_spacing_rounded,
                        accentColor: palette.teal,
                        label: 'Spacing',
                        value: gapMm,
                        step: 0.5,
                        min: 0.0,
                        max: 20.0,
                        onChanged: onGapChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStepperField(
                        icon: Icons.border_outer_rounded,
                        accentColor: palette.purple,
                        label: 'Margin',
                        value: marginMm,
                        step: 0.5,
                        min: 0.0,
                        max: 25.0,
                        onChanged: onMarginChanged,
                      ),
                    ),
                  ],
                ),

                // Red Dotted Cut Lines Toggle (Dragon Sheet & Lamination)
                if (workflowType == IdCardWorkflowType.dragonSheet ||
                    workflowType == IdCardWorkflowType.photoPaperLamination) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: palette.divider),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: showDragonCutLines
                          ? (palette.isDark ? palette.red.withValues(alpha: 0.14) : const Color(0xFFFEF2F2))
                          : palette.pillBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: showDragonCutLines
                            ? (palette.isDark ? palette.red.withValues(alpha: 0.4) : const Color(0xFFFECACA))
                            : palette.pillBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: showDragonCutLines
                                      ? (palette.isDark ? palette.red.withValues(alpha: 0.25) : const Color(0xFFFEE2E2))
                                      : palette.pillBg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.content_cut_rounded,
                                  size: 14,
                                  color: showDragonCutLines ? palette.red : palette.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Red Dotted Cut Lines',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      workflowType == IdCardWorkflowType.dragonSheet
                                          ? 'Center, Left & Right cutting guides'
                                          : 'Top, Bottom, Left & Right guides',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 24,
                          child: Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: showDragonCutLines,
                              activeThumbColor: palette.red,
                              activeTrackColor: palette.isDark
                                  ? palette.red.withValues(alpha: 0.4)
                                  : const Color(0xFFFEE2E2),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: onToggleDragonCutLines,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperField({
    required IconData icon,
    required Color accentColor,
    required String label,
    required double value,
    required double step,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Text(
              '$label (mm)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  child: Icon(
                    Icons.remove,
                    size: 14,
                    color: value > min ? accentColor : palette.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'mm',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: value < max ? accentColor : palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
