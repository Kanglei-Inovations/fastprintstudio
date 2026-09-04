import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/app_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final palette = AppPalette.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Financial Computations
    double totalRevenue = 0.0;
    double totalProfit = 0.0;
    double totalDue = 0.0;
    int totalJobsCount = history.length;

    for (final item in history) {
      totalRevenue += item.sellingPrice;
      totalProfit += item.profit;
      if (item.paymentStatus == 'Due') {
        totalDue += item.sellingPrice;
      }
    }

    // Filter Items
    final filteredHistory = history.where((item) {
      if (_selectedFilter == 'Paid') return item.paymentStatus == 'Paid';
      if (_selectedFilter == 'Due') return item.paymentStatus == 'Due';
      if (_selectedFilter == 'ID Cards') {
        final name = item.serviceName.toLowerCase();
        return name.contains('aadhaar') || name.contains('pan') || name.contains('voter') || name.contains('id card');
      }
      if (_selectedFilter == 'Photos') {
        return item.serviceName.toLowerCase().contains('photo') || item.paperName.toLowerCase().contains('4r');
      }
      if (_selectedFilter == 'Documents') {
        return item.serviceName.toLowerCase().contains('document');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: palette.bg,
      body: Column(
        children: [
          // 1. Header Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: palette.cardBg,
              border: Border(bottom: BorderSide(color: palette.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Activity & Financial Log',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.textPrimary),
                    ),
                    Text(
                      'Job records, revenue metrics, material expense & collection tracking',
                      style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    await FileUtils.cleanTempProcessingDir();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Temporary processing files cleaned.'),
                          backgroundColor: palette.green,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.cleaning_services_rounded, size: 15, color: palette.textPrimary),
                  label: Text('Clean Cache', style: TextStyle(fontSize: 12, color: palette.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.cardBorder),
                    backgroundColor: palette.cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                if (history.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Print History?'),
                          content: const Text(
                            'This will delete all metadata and financial records. Customer documents are never saved permanently.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: palette.red),
                              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await historyNotifier.clearAll();
                      }
                    },
                    icon: Icon(Icons.delete_outline_rounded, size: 15, color: palette.red),
                    label: Text('Clear History', style: TextStyle(fontSize: 12, color: palette.red)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.red.withValues(alpha: 0.3)),
                      backgroundColor: palette.cardBg,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Metrics Bar (Revenue, Profit, Due, Jobs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    palette: palette,
                    icon: Icons.currency_rupee_rounded,
                    label: 'Total Revenue',
                    value: '₹${totalRevenue.toStringAsFixed(0)}',
                    color: palette.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    palette: palette,
                    icon: Icons.trending_up_rounded,
                    label: 'Net Profit',
                    value: '₹${totalProfit.toStringAsFixed(0)}',
                    color: palette.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    palette: palette,
                    icon: Icons.pending_actions_rounded,
                    label: 'Uncollected / Due',
                    value: '₹${totalDue.toStringAsFixed(0)}',
                    color: totalDue > 0 ? palette.orange : palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    palette: palette,
                    icon: Icons.print_outlined,
                    label: 'Total Jobs',
                    value: '$totalJobsCount',
                    color: palette.purple,
                  ),
                ),
              ],
            ),
          ),

          // 3. Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                _filterChip('All ($totalJobsCount)', 'All', palette),
                const SizedBox(width: 6),
                _filterChip('Paid', 'Paid', palette),
                const SizedBox(width: 6),
                _filterChip('Due / Pending', 'Due', palette),
                const SizedBox(width: 6),
                _filterChip('ID Cards', 'ID Cards', palette),
                const SizedBox(width: 6),
                _filterChip('Photos', 'Photos', palette),
                const SizedBox(width: 6),
                _filterChip('Documents', 'Documents', palette),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. History List
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: palette.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No records found for this filter.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredHistory.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final isDue = item.paymentStatus == 'Due';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDue ? palette.orange.withValues(alpha: 0.5) : palette.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: palette.cardShadow,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.blueLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.print_outlined, color: palette.blue, size: 18),
                            ),
                            const SizedBox(width: 12),

                            // Job Details
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.serviceName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: palette.cardBorder),
                                        ),
                                        child: Text(
                                          item.paperName,
                                          style: TextStyle(fontSize: 10, color: palette.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.dimensionsSummary} • Printer: ${item.printerName}',
                                    style: TextStyle(fontSize: 11, color: palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),

                            // Financial Details
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${item.sellingPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: palette.blue,
                                        ),
                                      ),
                                      if (item.profit > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(+₹${item.profit.toStringAsFixed(0)})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: palette.green,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cost: ₹${(item.materialCost + item.inkCost).toStringAsFixed(1)} • ${item.paymentMethod}',
                                    style: TextStyle(fontSize: 10, color: palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Status & Payment Toggle Pill
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => historyNotifier.togglePaymentStatus(item.id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDue ? palette.orangeLight : palette.greenLight,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDue ? palette.orange : palette.green,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDue ? Icons.pending_rounded : Icons.check_circle_outline_rounded,
                                          size: 11,
                                          color: isDue ? palette.orange : palette.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.paymentStatus,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDue ? palette.orange : palette.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dateFormat.format(item.timestamp),
                                  style: TextStyle(fontSize: 10, color: palette.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, AppPalette palette) {
    final isSelected = _selectedFilter == value;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? palette.blueLight : palette.cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? palette.blue : palette.cardBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? palette.blue : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
