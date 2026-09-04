import 'package:flutter/material.dart';
import '../models/document_print_state.dart';

class DocumentPrintOptionsPanel extends StatelessWidget {
  final DocumentPrintState state;
  final ValueChanged<int> onCopiesChanged;
  final ValueChanged<ColorMode> onColorModeChanged;
  final ValueChanged<PageRangeMode> onPageRangeModeChanged;
  final ValueChanged<String> onCustomRangeChanged;
  final ValueChanged<DuplexMode> onPrintSidesChanged;
  final ValueChanged<bool> onCollateChanged;
  final ValueChanged<bool> onReverseOrderChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectOdd;
  final VoidCallback onSelectEven;

  const DocumentPrintOptionsPanel({
    super.key,
    required this.state,
    required this.onCopiesChanged,
    required this.onColorModeChanged,
    required this.onPageRangeModeChanged,
    required this.onCustomRangeChanged,
    required this.onPrintSidesChanged,
    required this.onCollateChanged,
    required this.onReverseOrderChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onSelectOdd,
    required this.onSelectEven,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "2. Print Options"
        const Text(
          '2. Print Options',
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
              // 1. Copies Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Copies',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: state.copies > 1 ? () => onCopiesChanged(state.copies - 1) : null,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Icon(Icons.remove, size: 14, color: Color(0xFF475569)),
                          ),
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '${state.copies}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ),
                        InkWell(
                          onTap: () => onCopiesChanged(state.copies + 1),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Color Mode Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Color Mode',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ColorMode>(
                        value: state.colorMode,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        items: ColorMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onColorModeChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Page Range
              const Text(
                'Page Range',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),

              // Radio: All Pages
              InkWell(
                onTap: () => onPageRangeModeChanged(PageRangeMode.all),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.pageRangeMode == PageRangeMode.all
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF94A3B8),
                            width: state.pageRangeMode == PageRangeMode.all ? 4.5 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Pages (${state.totalPages > 0 ? state.totalPages : 1})',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),

              // Radio: Custom Range with input box
              Row(
                children: [
                  InkWell(
                    onTap: () => onPageRangeModeChanged(PageRangeMode.custom),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: state.pageRangeMode == PageRangeMode.custom
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                width: state.pageRangeMode == PageRangeMode.custom ? 4.5 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Custom Range',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: TextEditingController(text: state.customRangeText)
                          ..selection = TextSelection.collapsed(offset: state.customRangeText.length),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1-3, 5, 8-10',
                          hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                          ),
                        ),
                        onChanged: onCustomRangeChanged,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Quick Range Helper Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _QuickChip(label: 'All', onTap: onSelectAll),
                  _QuickChip(label: 'Odd Pages', onTap: onSelectOdd),
                  _QuickChip(label: 'Even Pages', onTap: onSelectEven),
                  _QuickChip(label: 'Clear', onTap: onClearSelection),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Print Sides Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Print Sides',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DuplexMode>(
                        value: state.printSides,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        items: DuplexMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onPrintSidesChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Checkboxes: Collate Copies & Reverse Order
              InkWell(
                onTap: () => onCollateChanged(!state.collateCopies),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: state.collateCopies,
                        activeColor: const Color(0xFF2563EB),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => onCollateChanged(val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Collate Copies',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: () => onReverseOrderChanged(!state.reverseOrder),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: state.reverseOrder,
                        activeColor: const Color(0xFF2563EB),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => onReverseOrderChanged(val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Reverse Order',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
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

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}
