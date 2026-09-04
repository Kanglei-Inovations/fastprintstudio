import 'package:flutter/material.dart';
import '../../../core/models/enhancement_config.dart';
import '../theme/id_card_palette.dart';

class ImageAdjustmentPanel extends StatelessWidget {
  final IdCardPalette palette;
  final EnhancementConfig config;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onSharpnessChanged;
  final VoidCallback onReset;

  const ImageAdjustmentPanel({
    super.key,
    required this.palette,
    required this.config,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSharpnessChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomized = config.brightness != 0.0 || (config.contrast - 1.0).abs() > 0.01 || config.sharpness != 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Reset Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 15, color: palette.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Image Adjustments',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCustomized)
                InkWell(
                  onTap: onReset,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: palette.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Brightness Slider
          _AdjustmentSlider(
            palette: palette,
            label: 'Brightness',
            value: config.brightness,
            min: -1.0,
            max: 1.0,
            displayValue: '${(config.brightness * 100).toInt()}%',
            onChanged: onBrightnessChanged,
          ),
          const SizedBox(height: 8),

          // Contrast Slider
          _AdjustmentSlider(
            palette: palette,
            label: 'Contrast',
            value: (config.contrast - 1.0).clamp(-1.0, 1.0),
            min: -1.0,
            max: 1.0,
            displayValue: '${((config.contrast - 1.0) * 100).toInt()}%',
            onChanged: onContrastChanged,
          ),
          const SizedBox(height: 8),

          // Sharpness Slider
          _AdjustmentSlider(
            palette: palette,
            label: 'Sharpness',
            value: config.sharpness,
            min: 0.0,
            max: 1.0,
            displayValue: '${(config.sharpness * 100).toInt()}%',
            onChanged: onSharpnessChanged,
          ),
        ],
      ),
    );
  }
}

class _AdjustmentSlider extends StatelessWidget {
  final IdCardPalette palette;
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _AdjustmentSlider({
    required this.palette,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: palette.blue,
              inactiveTrackColor: palette.pillBorder,
              thumbColor: palette.blue,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
