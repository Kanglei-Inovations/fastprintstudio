import 'package:flutter/material.dart';
import '../../../core/models/id_card_preset.dart';
import '../../../core/models/id_card_workflow_type.dart';
import '../../../core/models/paper_preset.dart';
import '../theme/id_card_palette.dart';

class PrintJobSummaryPanel extends StatelessWidget {
  final IdCardPalette palette;
  final IDCardPreset preset;
  final PaperPreset paper;
  final PaperOrientation orientation;
  final bool hasBothSides;
  final int copies;
  final IdCardWorkflowType workflowType;
  final PvcOutputMode pvcMode;
  final int l805CardQuantity;
  final int cardsPlaced;
  final int frontCount;
  final int backCount;
  final int sheetsUsed;
  final double sellingPrice;
  final double materialCost;
  final double inkCost;
  final double profit;
  final bool hasSource;
  final ValueChanged<int> onCopiesChanged;
  final VoidCallback onPrint;
  final VoidCallback? onExportPdf;

  const PrintJobSummaryPanel({
    super.key,
    required this.palette,
    required this.preset,
    required this.paper,
    required this.orientation,
    required this.hasBothSides,
    required this.copies,
    required this.workflowType,
    required this.pvcMode,
    this.l805CardQuantity = 1,
    required this.cardsPlaced,
    required this.frontCount,
    required this.backCount,
    required this.sheetsUsed,
    required this.sellingPrice,
    required this.materialCost,
    required this.inkCost,
    required this.profit,
    required this.hasSource,
    required this.onCopiesChanged,
    required this.onPrint,
    this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final isLamination = workflowType == IdCardWorkflowType.photoPaperLamination;
    final isL805 = workflowType == IdCardWorkflowType.epsonL805;
    final l805PagesCount = (hasBothSides && backCount > 0) ? 2 : 1;

    return Container(
      width: 275,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border(left: BorderSide(color: palette.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.receipt_long_rounded, size: 15, color: palette.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Job Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Specs List
          Expanded(
            child: ListView(
              children: [
                _JobSpecRow(
                  palette: palette,
                  icon: Icons.precision_manufacturing_rounded,
                  iconColor: isLamination ? palette.green : (isL805 ? palette.blue : palette.orange),
                  label: 'Method',
                  value: isLamination
                      ? 'Lamination Card'
                      : (isL805 ? 'Epson L805 Card' : 'Dragon Sheet'),
                ),
                if (!isLamination && !isL805)
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.grid_view_rounded,
                    iconColor: palette.orange,
                    label: 'Output Mode',
                    value: hasBothSides
                        ? '5 Duplex Pairs'
                        : '10 Cards Single',
                  ),
                if (isL805) ...[
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.style_rounded,
                    iconColor: palette.blue,
                    label: 'Carrier',
                    value: 'A4 PVC Tray',
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.view_carousel_rounded,
                    iconColor: palette.teal,
                    label: 'Cards Placed',
                    value: '${cardsPlaced > 0 ? cardsPlaced : 1} Card${cardsPlaced > 1 ? 's' : ''}',
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.flip_rounded,
                    iconColor: palette.purple,
                    label: 'Sides',
                    value: hasBothSides ? 'Front + Back' : 'Front Only',
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.auto_stories_rounded,
                    iconColor: palette.blue,
                    label: 'Page Output',
                    value: '$l805PagesCount A4 Page${l805PagesCount > 1 ? 's' : ''}',
                  ),
                ] else ...[
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.badge_rounded,
                    iconColor: palette.purple,
                    label: 'Document',
                    value: preset.name,
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.straighten_rounded,
                    iconColor: palette.teal,
                    label: 'Dimensions',
                    value: preset.formattedDimensions,
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.layers_rounded,
                    iconColor: palette.blue,
                    label: 'Paper Sheet',
                    value: paper.name,
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.grid_view_rounded,
                    iconColor: palette.green,
                    label: 'Cards Placed',
                    value: '$cardsPlaced ($frontCount F, $backCount B)',
                  ),
                  _JobSpecRow(
                    palette: palette,
                    icon: Icons.copy_rounded,
                    iconColor: palette.orange,
                    label: 'Sheets Used',
                    value: '$sheetsUsed ${sheetsUsed == 1 ? 'Sheet' : 'Sheets'}',
                  ),
                ],

                const SizedBox(height: 10),
                Divider(height: 1, color: palette.divider),
                const SizedBox(height: 10),

                // Copies Stepper Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded, size: 14, color: palette.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Job Copies',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.pillBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.pillBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: copies > 1 ? () => onCopiesChanged(copies - 1) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              child: Icon(Icons.remove, size: 13, color: copies > 1 ? palette.textPrimary : palette.textMuted),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$copies',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                            ),
                          ),
                          InkWell(
                            onTap: () => onCopiesChanged(copies + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              child: Icon(Icons.add, size: 13, color: palette.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Financial Breakdown Card (Selling, Cost, Ink, Profit)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _FinancialRow(
                        palette: palette,
                        label: 'Selling Price (${isLamination ? '₹50' : '₹100'}/card)',
                        value: '₹${sellingPrice.toStringAsFixed(0)}',
                        isBold: true,
                        color: palette.blue,
                      ),
                      const SizedBox(height: 4),
                      _FinancialRow(
                        palette: palette,
                        label: 'Material Cost',
                        value: '-₹${materialCost.toStringAsFixed(1)}',
                        color: palette.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      _FinancialRow(
                        palette: palette,
                        label: 'Estimated Ink',
                        value: '-₹${inkCost.toStringAsFixed(1)}',
                        color: palette.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Divider(height: 1, color: palette.divider),
                      const SizedBox(height: 6),
                      _FinancialRow(
                        palette: palette,
                        label: 'Estimated Profit',
                        value: '₹${profit.toStringAsFixed(1)}',
                        isBold: true,
                        color: palette.green,
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Export PDF Button
          if (onExportPdf != null) ...[
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: hasSource ? onExportPdf : null,
                icon: Icon(Icons.picture_as_pdf_rounded, size: 15, color: hasSource ? palette.red : palette.textMuted),
                label: Text(
                  isL805 ? 'EXPORT A4 PDF ($l805PagesCount PGS)' : 'EXPORT PDF',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: hasSource ? palette.red : palette.textMuted,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: hasSource ? palette.red.withValues(alpha: 0.4) : palette.cardBorder,
                  ),
                  backgroundColor: hasSource ? palette.red.withValues(alpha: 0.06) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Primary Action Print Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: hasSource ? onPrint : null,
              icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
              label: Text(
                isL805
                    ? 'PRINT NOW ($l805PagesCount A4 PAGES)'
                    : 'PRINT NOW (Ctrl+P)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSource ? palette.blue : palette.cardBorder,
                elevation: hasSource ? 2 : 0,
                shadowColor: palette.blue.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSpecRow extends StatelessWidget {
  final IdCardPalette palette;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _JobSpecRow({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final IdCardPalette palette;
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final double fontSize;

  const _FinancialRow({
    required this.palette,
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? palette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
