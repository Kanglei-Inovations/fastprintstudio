import 'package:flutter/material.dart';
import '../../../core/constants/paper_presets.dart';
import '../../../core/models/paper_preset.dart';
import '../models/document_paper_type.dart';
import '../models/document_print_state.dart';

class DocumentPaperLayoutPanel extends StatelessWidget {
  final DocumentPrintState state;
  final ValueChanged<PaperPreset> onPaperPresetChanged;
  final ValueChanged<DocumentPaperType> onPaperTypeChanged;
  final ValueChanged<DocumentBindingType> onBindingTypeChanged;
  final ValueChanged<PaperOrientation> onOrientationChanged;
  final ValueChanged<PageScaling> onScalingChanged;
  final ValueChanged<double> onCustomScaleChanged;
  final ValueChanged<bool> onAutoRotateChanged;
  final ValueChanged<int> onPagesPerSheetChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<bool> onBorderChanged;

  const DocumentPaperLayoutPanel({
    super.key,
    required this.state,
    required this.onPaperPresetChanged,
    required this.onPaperTypeChanged,
    required this.onBindingTypeChanged,
    required this.onOrientationChanged,
    required this.onScalingChanged,
    required this.onCustomScaleChanged,
    required this.onAutoRotateChanged,
    required this.onPagesPerSheetChanged,
    required this.onMarginChanged,
    required this.onBorderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "3. Paper & Layout"
        const Text(
          '3. Paper & Layout',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Paper Size Dropdown
              const Text(
                'Paper Size',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaperPreset>(
                    value: state.paperPreset,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    items: StandardPaperPresets.all.map((preset) {
                      return DropdownMenuItem(
                        value: preset,
                        child: Text(preset.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onPaperPresetChanged(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Paper Quality & GSM
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paper Quality (GSM)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Text(
                    state.colorMode == ColorMode.color
                        ? 'Color: ₹${state.paperType.colorRatePerPage.toStringAsFixed(0)}/pg'
                        : 'B&W: ₹${state.paperType.bwRatePerPage.toStringAsFixed(0)}/pg',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DocumentPaperType>(
                    value: state.paperType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    items: DocumentPaperType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onPaperTypeChanged(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Finishing & Binding
              const Text(
                'Finishing & Binding',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DocumentBindingType>(
                    value: state.bindingType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    items: DocumentBindingType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onBindingTypeChanged(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Orientation Radio Buttons
              const Text(
                'Orientation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  InkWell(
                    onTap: () => onOrientationChanged(PaperOrientation.portrait),
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
                                color: state.orientation == PaperOrientation.portrait
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                width: state.orientation == PaperOrientation.portrait ? 4.5 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Portrait',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  InkWell(
                    onTap: () => onOrientationChanged(PaperOrientation.landscape),
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
                                color: state.orientation == PaperOrientation.landscape
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                width: state.orientation == PaperOrientation.landscape ? 4.5 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Landscape',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Scaling Dropdown
              const Text(
                'Scaling',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PageScaling>(
                    value: state.scaling,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    items: PageScaling.values.map((scaling) {
                      return DropdownMenuItem(
                        value: scaling,
                        child: Text(scaling.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onScalingChanged(val);
                    },
                  ),
                ),
              ),

              // Custom % slider if PageScaling.custom
              if (state.scaling == PageScaling.custom) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.customScalePercent,
                        min: 25.0,
                        max: 300.0,
                        divisions: 55,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: onCustomScaleChanged,
                      ),
                    ),
                    Text(
                      '${state.customScalePercent.round()}%',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // 4. Auto Rotate Pages Checkbox
              InkWell(
                onTap: () => onAutoRotateChanged(!state.autoRotatePages),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: state.autoRotatePages,
                        activeColor: const Color(0xFF2563EB),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => onAutoRotateChanged(val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Auto Rotate Pages',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. Pages Per Sheet (N-Up)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pages per sheet',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Row(
                    children: [1, 2, 4, 6].map((count) {
                      final isSelected = state.pagesPerSheet == count;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          onTap: () => onPagesPerSheetChanged(count),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 6. Page Margin & Border
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Margin (mm)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: state.marginMm > 0 ? () => onMarginChanged(state.marginMm - 1) : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Icon(Icons.remove, size: 12, color: Color(0xFF475569)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${state.marginMm.toInt()} mm',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        InkWell(
                          onTap: state.marginMm < 30 ? () => onMarginChanged(state.marginMm + 1) : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Icon(Icons.add, size: 12, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: () => onBorderChanged(!state.borderAroundPages),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: state.borderAroundPages,
                        activeColor: const Color(0xFF2563EB),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => onBorderChanged(val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Border around pages',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
