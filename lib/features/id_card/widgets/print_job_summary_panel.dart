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
              Icon(Icons.receipt_long_rounded, size: 16, color: palette.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Print Job Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
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
                  label: 'Method',
                  value: isLamination
                      ? 'Photo Paper / 4R'
                      : (isL805 ? 'Epson L805 Card' : 'Dragon Sheet'),
                ),
                if (!isLamination && !isL805)
                  _JobSpecRow(
                    palette: palette,
                    label: 'Output Mode',
                    value: pvcMode == PvcOutputMode.dragonSheetDuplex
                        ? 'Dragon (5 Pairs)'
                        : 'Dragon (10 Cards)',
                  ),
                if (isL805) ...[
                  _JobSpecRow(palette: palette, label: 'Paper / Carrier', value: 'A4 (210 × 297 mm)'),
                  _JobSpecRow(palette: palette, label: 'Cards Placed', value: '$l805CardQuantity Card${l805CardQuantity > 1 ? 's' : ''} (85.6×54mm)'),
                  _JobSpecRow(palette: palette, label: 'Sides', value: hasBothSides ? 'Front + Back' : 'Front Only'),
                  _JobSpecRow(palette: palette, label: 'Page Output', value: '$l805PagesCount A4 Page${l805PagesCount > 1 ? 's' : ''}'),
                  _JobSpecRow(palette: palette, label: 'Print Scale', value: '100% Actual Size'),
                ] else ...[
                  _JobSpecRow(palette: palette, label: 'Document', value: preset.name),
                  _JobSpecRow(palette: palette, label: 'Card Dimensions', value: preset.formattedDimensions),
                  _JobSpecRow(palette: palette, label: 'Paper / Sheet', value: paper.name),
                  _JobSpecRow(palette: palette, label: 'Cards Placed', value: '$cardsPlaced ($frontCount Front, $backCount Back)'),
                  _JobSpecRow(palette: palette, label: 'Sheets Used', value: '$sheetsUsed ${sheetsUsed == 1 ? 'Sheet' : 'Sheets'}'),
                  _JobSpecRow(palette: palette, label: 'Print Resolution', value: '300 DPI High-Def'),
                ],

                const SizedBox(height: 10),
                Divider(height: 1, color: palette.divider),
                const SizedBox(height: 10),

                // Copies Stepper Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Copies',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.add, size: 13, color: palette.textPrimary),
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
                icon: Icon(Icons.picture_as_pdf_outlined, size: 15, color: hasSource ? palette.blue : palette.textMuted),
                label: Text(
                  isL805 ? 'EXPORT A4 PDF ($l805PagesCount PGS)' : 'EXPORT PDF',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: hasSource ? palette.blue : palette.textMuted,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: hasSource ? palette.blue : palette.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                backgroundColor: hasSource ? palette.green : palette.cardBorder,
                elevation: hasSource ? 2 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  final String label;
  final String value;

  const _JobSpecRow({
    required this.palette,
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
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
