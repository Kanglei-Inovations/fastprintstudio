import 'package:flutter/material.dart';
import '../../../core/constants/paper_presets.dart';
import '../../../core/models/paper_preset.dart';
import '../../../core/models/photo_finish.dart';
import '../../../core/theme/app_palette.dart';
import '../../../providers/passport_photo_provider.dart';

class PhotoPaperLayoutPanel extends StatelessWidget {
  final PassportPhotoState state;
  final PassportPhotoNotifier notifier;
  final AppPalette palette;

  const PhotoPaperLayoutPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final isSinglePhoto = state.presetMode == PhotoTypePresetMode.fourRPhoto ||
        state.presetMode == PhotoTypePresetMode.a4Photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "3. Paper & Layout"
        Text(
          '3. PAPER & LAYOUT',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: palette.textSecondary,
            letterSpacing: 0.5,
          ),
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
              // 1. Paper Size Dropdown & Quick Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paper Size',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _buildQuickPaperChip(
                        label: '4R',
                        isSelected: state.paperPreset.id == '4r',
                        onTap: () => notifier.setPaperPreset(StandardPaperPresets.fourR),
                      ),
                      const SizedBox(width: 4),
                      _buildQuickPaperChip(
                        label: 'A4',
                        isSelected: state.paperPreset.id == 'a4',
                        onTap: () => notifier.setPaperPreset(StandardPaperPresets.a4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaperPreset>(
                    value: state.paperPreset,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: palette.textSecondary),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
                    items: StandardPaperPresets.all.map((preset) {
                      return DropdownMenuItem(
                        value: preset,
                        child: Text('${preset.name} (${preset.widthMm.toInt()}×${preset.heightMm.toInt()} mm)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setPaperPreset(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Paper Quality (Matte & Glossy) with Live Price Adjustment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paper Quality',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: state.photoFinish == PhotoFinish.matte
                          ? (palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight)
                          : (palette.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      state.photoFinish == PhotoFinish.matte ? '+₹10/sheet' : 'Base Rate',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: state.photoFinish == PhotoFinish.matte ? palette.blue : palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildQualityCard(
                      finish: PhotoFinish.glossy,
                      title: 'Glossy',
                      subtitle: '₹4.0 cost/sh',
                      priceTag: 'Standard',
                      icon: Icons.wb_sunny_rounded,
                      isSelected: state.photoFinish == PhotoFinish.glossy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQualityCard(
                      finish: PhotoFinish.matte,
                      title: 'Matte',
                      subtitle: '₹5.5 cost/sh',
                      priceTag: '+₹10',
                      icon: Icons.blur_on_rounded,
                      isSelected: state.photoFinish == PhotoFinish.matte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Finishing: Lamination
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finishing (Lamination)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (state.photoLamination != PhotoLamination.none)
                    Text(
                      '+₹${state.photoLamination.extraPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.blue),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PhotoLamination>(
                    value: state.photoLamination,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: palette.textSecondary),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
                    items: PhotoLamination.values.map((lam) {
                      final extra = lam.extraPrice > 0 ? ' (+₹${lam.extraPrice.toStringAsFixed(0)})' : '';
                      return DropdownMenuItem(
                        value: lam,
                        child: Text('${lam.label}$extra'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setPhotoLamination(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Finishing: Frame / Mount (Studio Wall / Table Mount)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frame & Mounting',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (state.photoFraming != PhotoFraming.none)
                    Text(
                      '+₹${state.photoFraming.extraPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.blue),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PhotoFraming>(
                    value: state.photoFraming,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: palette.textSecondary),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
                    items: PhotoFraming.values.map((frm) {
                      final extra = frm.extraPrice > 0 ? ' (+₹${frm.extraPrice.toStringAsFixed(0)})' : '';
                      return DropdownMenuItem(
                        value: frm,
                        child: Text('${frm.label}$extra'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setPhotoFraming(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Orientation (Portrait vs Landscape Radio Buttons)
              Text(
                'Orientation',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildOrientationRadio(
                    label: 'Portrait',
                    isSelected: state.orientation == PaperOrientation.portrait,
                    onTap: () => notifier.setOrientation(PaperOrientation.portrait),
                  ),
                  const SizedBox(width: 16),
                  _buildOrientationRadio(
                    label: 'Landscape',
                    isSelected: state.orientation == PaperOrientation.landscape,
                    onTap: () => notifier.setOrientation(PaperOrientation.landscape),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. Contextual Controls
              if (isSinglePhoto) ...[
                // Photo Scaling Mode for 4R and A4 full sheet prints
                Text(
                  'Photo Scaling & Fit',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: palette.isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PhotoScalingMode>(
                      value: state.photoScaling,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: palette.textSecondary),
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
                      items: PhotoScalingMode.values.map((sc) {
                        return DropdownMenuItem(
                          value: sc,
                          child: Text(sc.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setPhotoScaling(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Margin for 4R/A4
                _buildStepperField(
                  label: 'Border Margin (mm)',
                  value: state.marginMm,
                  step: 0.5,
                  min: 0.0,
                  max: 20.0,
                  onChanged: (val) => notifier.setMarginMm(val),
                ),
              ] else ...[
                // Passport / Pass+Stamp Spacing & Margin
                Row(
                  children: [
                    Expanded(
                      child: _buildStepperField(
                        label: 'Spacing (mm)',
                        value: state.spacingMm,
                        step: 0.5,
                        min: 0.0,
                        max: 10.0,
                        onChanged: (val) => notifier.setSpacingMm(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStepperField(
                        label: 'Margin (mm)',
                        value: state.marginMm,
                        step: 0.5,
                        min: 0.0,
                        max: 15.0,
                        onChanged: (val) => notifier.setMarginMm(val),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPaperChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? palette.blue : (palette.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? palette.blue : palette.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQualityCard({
    required PhotoFinish finish,
    required String title,
    required String subtitle,
    required String priceTag,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => notifier.setPhotoFinish(finish),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isSelected
              ? (palette.isDark ? palette.blue.withValues(alpha: 0.15) : palette.blueLight)
              : palette.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? palette.blue : palette.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? palette.blue : palette.textSecondary,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? palette.blue : palette.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationRadio({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? palette.blue : palette.textSecondary,
                  width: isSelected ? 4.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperField({
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: palette.isDark ? Colors.white10 : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    Icons.remove,
                    size: 13,
                    color: value > min ? palette.textPrimary : palette.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    Icons.add,
                    size: 13,
                    color: value < max ? palette.textPrimary : palette.textMuted,
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

