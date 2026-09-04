import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class DesktopStatusBar extends ConsumerWidget {
  final String paperText;
  final String copiesText;
  final String sizeSummary;

  const DesktopStatusBar({
    super.key,
    this.paperText = 'Paper: 4R (4 × 6 in)',
    this.copiesText = 'Copies: 1',
    this.sizeSummary = 'Scale: 100% Actual Size',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final availablePrintersAsync = ref.watch(availablePrintersProvider);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF151922),
        border: Border(top: BorderSide(color: Color(0xFF222836))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Printer Status
            const Icon(Icons.print, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            availablePrintersAsync.when(
              data: (printers) {
                final defaultP = settings.defaultPrinterName != null
                    ? printers.firstWhere(
                        (p) => p.name == settings.defaultPrinterName,
                        orElse: () => printers.isNotEmpty ? printers.first : null as dynamic,
                      )
                    : (printers.isNotEmpty ? printers.first : null);

                final pName = defaultP?.name ?? (printers.isNotEmpty ? printers.first.name : 'System Print Dialog');
                return Text(
                  'Printer: $pName',
                  style: const TextStyle(color: AppColors.sidebarText, fontSize: 11, fontWeight: FontWeight.w500),
                );
              },
              loading: () => const Text(
                'Printer: Discovering...',
                style: TextStyle(color: AppColors.sidebarTextMuted, fontSize: 11),
              ),
              error: (e, stack) => const Text(
                'Printer: System Dialog',
                style: TextStyle(color: AppColors.sidebarTextMuted, fontSize: 11),
              ),
            ),

            const SizedBox(width: 16),
            const Text('|', style: TextStyle(color: Color(0xFF2E384D))),
            const SizedBox(width: 16),

            // Paper info
            const Icon(Icons.description_outlined, size: 14, color: AppColors.info),
            const SizedBox(width: 6),
            Text(
              paperText,
              style: const TextStyle(color: AppColors.sidebarText, fontSize: 11),
            ),

            const SizedBox(width: 16),
            const Text('|', style: TextStyle(color: Color(0xFF2E384D))),
            const SizedBox(width: 16),

            // Copies
            const Icon(Icons.copy_rounded, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              copiesText,
              style: const TextStyle(color: AppColors.sidebarText, fontSize: 11),
            ),

            const SizedBox(width: 24),

            // Physical Scale
            const Icon(Icons.straighten_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              sizeSummary,
              style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Text(
              'DPI: ${settings.defaultDpi}',
              style: const TextStyle(color: AppColors.sidebarTextMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
