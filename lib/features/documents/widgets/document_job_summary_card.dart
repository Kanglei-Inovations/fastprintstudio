import 'package:flutter/material.dart';
import '../../../core/models/pricing_item.dart';
import '../models/document_paper_type.dart';
import '../models/document_print_state.dart';

class DocumentJobSummaryCard extends StatelessWidget {
  final DocumentPrintState state;
  final PricingItem bwPricing;
  final PricingItem colorPricing;
  final ValueChanged<int> onCopiesChanged;
  final VoidCallback onPrintNow;
  final VoidCallback onPreviewFullscreen;
  final VoidCallback onPrintCurrentPage;
  final VoidCallback onExportPdf;
  final VoidCallback onClearAll;

  const DocumentJobSummaryCard({
    super.key,
    required this.state,
    required this.bwPricing,
    required this.colorPricing,
    required this.onCopiesChanged,
    required this.onPrintNow,
    required this.onPreviewFullscreen,
    required this.onPrintCurrentPage,
    required this.onExportPdf,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoc = state.hasDocument;

    return Container(
      width: 290,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Job Summary Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Job Summary',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Key-Value Rows
                _SummaryRow(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'File Name',
                  value: state.fileName ?? 'No file selected',
                  isBold: true,
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.layers_outlined,
                  label: 'Total Pages',
                  value: '${state.totalPages}',
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.aspect_ratio_outlined,
                  label: 'Paper Size',
                  value: state.paperPreset.name,
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.screen_rotation_outlined,
                  label: 'Orientation',
                  value: state.orientation.displayName,
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.palette_outlined,
                  label: 'Color Mode',
                  value: state.colorMode.displayName,
                  isBold: true,
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.flip_to_back_outlined,
                  label: 'Print Sides',
                  value: state.printSides.displayName,
                ),
                const SizedBox(height: 10),

                // Copies inline stepper
                Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text(
                      'Copies',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
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
                            onTap: state.copies > 1 ? () => onCopiesChanged(state.copies - 1) : null,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Icon(Icons.remove, size: 12, color: Color(0xFF475569)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${state.copies}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          InkWell(
                            onTap: () => onCopiesChanged(state.copies + 1),
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
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.description_outlined,
                  label: 'Paper Type',
                  value: state.paperType.name,
                ),
                const SizedBox(height: 10),

                if (state.bindingType != DocumentBindingType.none) ...[
                  _SummaryRow(
                    icon: Icons.book_outlined,
                    label: 'Binding / Finish',
                    value: state.bindingType.label,
                  ),
                  const SizedBox(height: 10),
                ],

                _SummaryRow(
                  icon: Icons.print_outlined,
                  label: 'Total Pages to Print',
                  value: '${state.pagesToPrint * state.copies}',
                  isBold: true,
                ),
                const SizedBox(height: 10),

                _SummaryRow(
                  icon: Icons.layers_outlined,
                  label: 'Sheets Required',
                  value: '${state.totalSheetsToPrint} sheets',
                ),
                const SizedBox(height: 14),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Financial Breakdown Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selling Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                          Text(
                            '₹ ${state.calculatedSellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paper & Material (${state.totalSheetsToPrint} sh)', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          Text('-₹ ${state.calculatedMaterialCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Ink', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          Text('-₹ ${state.calculatedInkCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(height: 1, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Profit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                          Text(
                            '₹ ${state.calculatedProfit.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Big Primary "Print Now" Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: hasDoc ? onPrintNow : null,
                    icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
                    label: const Text(
                      'Print Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Quick Actions Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.dashboard_customize_outlined, size: 15, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2x2 Grid of Actions matching document.png
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        label: 'Preview Fullscreen',
                        onTap: hasDoc ? onPreviewFullscreen : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        label: 'Print Current Page',
                        onTap: hasDoc ? onPrintCurrentPage : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        label: 'Export as PDF',
                        onTap: hasDoc ? onExportPdf : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        label: 'Clear All',
                        onTap: hasDoc ? onClearAll : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        backgroundColor: Colors.white,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: onTap != null ? const Color(0xFF334155) : const Color(0xFF94A3B8),
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
