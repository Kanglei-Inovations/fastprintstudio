import 'package:flutter/material.dart';
import '../../../core/constants/paper_presets.dart';
import '../../../core/models/paper_preset.dart';
import '../theme/id_card_palette.dart';

class IdCardBottomBar extends StatelessWidget {
  final IdCardPalette palette;
  final double gapMm;
  final double marginMm;
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final int copies;
  final ValueChanged<double> onGapChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<PaperPreset> onPaperPresetChanged;
  final ValueChanged<PaperOrientation> onOrientationChanged;
  final ValueChanged<int> onCopiesChanged;
  final VoidCallback onOpenPrinterSettings;

  const IdCardBottomBar({
    super.key,
    required this.palette,
    required this.gapMm,
    required this.marginMm,
    required this.paperPreset,
    required this.orientation,
    required this.copies,
    required this.onGapChanged,
    required this.onMarginChanged,
    required this.onPaperPresetChanged,
    required this.onOrientationChanged,
    required this.onCopiesChanged,
    required this.onOpenPrinterSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border(top: BorderSide(color: palette.divider)),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Group 1: Layout Options (Card Gap & Margin)
          _BottomGroupCard(
            palette: palette,
            title: 'Layout Spacing',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperLabel(
                  palette: palette,
                  label: 'Gap',
                  valueStr: '${gapMm.toStringAsFixed(1)} mm',
                  onMinus: () => onGapChanged((gapMm - 0.5).clamp(0.0, 30.0)),
                  onPlus: () => onGapChanged((gapMm + 0.5).clamp(0.0, 30.0)),
                ),
                const SizedBox(width: 14),
                _StepperLabel(
                  palette: palette,
                  label: 'Margin',
                  valueStr: '${marginMm.toStringAsFixed(1)} mm',
                  onMinus: () => onMarginChanged((marginMm - 0.5).clamp(0.0, 30.0)),
                  onPlus: () => onMarginChanged((marginMm + 0.5).clamp(0.0, 30.0)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Group 2: Paper Preset & Orientation
          _BottomGroupCard(
            palette: palette,
            title: 'Paper Sheet',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: palette.pillBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: palette.pillBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaperPreset>(
                      value: paperPreset,
                      isDense: true,
                      icon: Icon(Icons.arrow_drop_down, size: 16, color: palette.textSecondary),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      dropdownColor: palette.cardBg,
                      items: StandardPaperPresets.all.map((p) {
                        return DropdownMenuItem<PaperPreset>(
                          value: p,
                          child: Text('${p.name} (${p.formattedDimensions})'),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) onPaperPresetChanged(p);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Orientation toggle
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.pillBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: palette.pillBorder),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => onOrientationChanged(PaperOrientation.portrait),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: orientation == PaperOrientation.portrait
                                ? (palette.isDark ? palette.blue.withValues(alpha: 0.25) : palette.blueLight)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                          ),
                          child: Icon(
                            Icons.portrait_rounded,
                            size: 16,
                            color: orientation == PaperOrientation.portrait ? palette.blue : palette.textMuted,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onOrientationChanged(PaperOrientation.landscape),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: orientation == PaperOrientation.landscape
                                ? (palette.isDark ? palette.blue.withValues(alpha: 0.25) : palette.blueLight)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                          ),
                          child: Icon(
                            Icons.landscape_rounded,
                            size: 16,
                            color: orientation == PaperOrientation.landscape ? palette.blue : palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Group 3: Copies
          _BottomGroupCard(
            palette: palette,
            title: 'Copies',
            child: _StepperLabel(
              palette: palette,
              label: 'Copies',
              valueStr: '$copies',
              onMinus: copies > 1 ? () => onCopiesChanged(copies - 1) : null,
              onPlus: () => onCopiesChanged(copies + 1),
            ),
          ),

          const Spacer(),

          // Group 4: Printer Status Pill
          InkWell(
            onTap: onOpenPrinterSettings,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.pillBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.pillBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_outlined, size: 14, color: palette.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Printer: EPSON L3210',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ready',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomGroupCard extends StatelessWidget {
  final IdCardPalette palette;
  final String title;
  final Widget child;

  const _BottomGroupCard({
    required this.palette,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardBgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _StepperLabel extends StatelessWidget {
  final IdCardPalette palette;
  final String label;
  final String valueStr;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _StepperLabel({
    required this.palette,
    required this.label,
    required this.valueStr,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
        ),
        Container(
          height: 26,
          decoration: BoxDecoration(
            color: palette.pillBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.pillBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onMinus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.remove, size: 12, color: onMinus != null ? palette.textPrimary : palette.textMuted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  valueStr,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
              ),
              InkWell(
                onTap: onPlus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.add, size: 12, color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
