import 'package:flutter/material.dart';
import '../../../shared/widgets/pulsing_dot.dart';
import '../theme/id_card_palette.dart';

/// Navigation and pagination control bar for multi-page ID card preview
class IdCardPaginationBar extends StatelessWidget {
  final IdCardPalette palette;
  final int activeSheetIndex;
  final int totalSheets;
  final String? sheetTitle;
  final String? activeCardName;
  final ValueChanged<int> onSelectSheet;
  final VoidCallback onPrevSheet;
  final VoidCallback onNextSheet;
  final String Function(int index)? sheetLabelBuilder;

  const IdCardPaginationBar({
    super.key,
    required this.palette,
    required this.activeSheetIndex,
    required this.totalSheets,
    this.sheetTitle,
    this.activeCardName,
    required this.onSelectSheet,
    required this.onPrevSheet,
    required this.onNextSheet,
    this.sheetLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 15, color: palette.blue),
              const SizedBox(width: 8),
              Text(
                'Sheet Preview:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: palette.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulsingDot(
                      color: palette.blue,
                      size: 5.5,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${activeSheetIndex + 1} of $totalSheets',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Previous Page Arrow
          InkWell(
            onTap: activeSheetIndex > 0 ? onPrevSheet : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: activeSheetIndex > 0 ? palette.pillBg : palette.pillBg.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: activeSheetIndex > 0 ? palette.pillBorder : palette.pillBorder.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: activeSheetIndex > 0 ? palette.textPrimary : palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Sheet Pills
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < totalSheets; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onSelectSheet(i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeSheetIndex == i ? palette.blue : palette.pillBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: activeSheetIndex == i ? palette.blue : palette.pillBorder,
                            width: activeSheetIndex == i ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activeSheetIndex == i) ...[
                              const PulsingDot(
                                color: Colors.white,
                                size: 5.5,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              sheetLabelBuilder != null ? sheetLabelBuilder!(i) : 'Sheet ${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: activeSheetIndex == i ? FontWeight.w800 : FontWeight.w600,
                                color: activeSheetIndex == i ? Colors.white : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Next Page Arrow
          InkWell(
            onTap: activeSheetIndex < totalSheets - 1 ? onNextSheet : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: activeSheetIndex < totalSheets - 1 ? palette.pillBg : palette.pillBg.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: activeSheetIndex < totalSheets - 1 ? palette.pillBorder : palette.pillBorder.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: activeSheetIndex < totalSheets - 1 ? palette.textPrimary : palette.textMuted,
              ),
            ),
          ),

          if (activeCardName != null && activeCardName!.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: palette.isDark ? palette.blue.withValues(alpha: 0.18) : palette.blueLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.blue.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingDot(color: palette.blue, size: 5.5),
                  const SizedBox(width: 5),
                  Text(
                    'Card: $activeCardName',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (sheetTitle != null && sheetTitle!.isNotEmpty) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                sheetTitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          // Actual size badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.pillBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.straighten_rounded, size: 12, color: palette.blue),
                const SizedBox(width: 4),
                Text(
                  '100% Scale',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
