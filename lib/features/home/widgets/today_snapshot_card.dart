import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class TodaySnapshotCard extends StatelessWidget {
  final DashboardPalette palette;
  final int totalCustomers;
  final int newCustomers;
  final double avgOrderValue;
  final int returnCustomers;

  const TodaySnapshotCard({
    super.key,
    required this.palette,
    this.totalCustomers = 18,
    this.newCustomers = 3,
    this.avgOrderValue = 106,
    this.returnCustomers = 7,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _SnapshotMetric(
        label: 'Total Customers',
        value: '$totalCustomers',
        growth: '+ 12% vs yesterday',
        icon: Icons.people_outline_rounded,
        color: palette.blue,
      ),
      _SnapshotMetric(
        label: 'New Customers',
        value: '$newCustomers',
        growth: '+ 50% vs yesterday',
        icon: Icons.person_add_alt_1_outlined,
        color: palette.green,
      ),
      _SnapshotMetric(
        label: 'Avg. Order Value',
        value: '₹ ${avgOrderValue.toStringAsFixed(0)}',
        growth: '+ 8% vs yesterday',
        icon: Icons.receipt_long_outlined,
        color: palette.purple,
      ),
      _SnapshotMetric(
        label: 'Return Customers',
        value: '$returnCustomers',
        growth: '+ 16% vs yesterday',
        icon: Icons.sync_rounded,
        color: palette.orange,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Today's Snapshot",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Daily customer & order performance',
            style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Metrics
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final m = metrics[index];

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: palette.isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m.icon, size: 16, color: m.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: TextStyle(fontSize: 10, color: palette.textMuted),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          m.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 11, color: palette.green),
                      const SizedBox(width: 2),
                      Text(
                        m.growth,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: palette.green,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric {
  final String label;
  final String value;
  final String growth;
  final IconData icon;
  final Color color;

  _SnapshotMetric({
    required this.label,
    required this.value,
    required this.growth,
    required this.icon,
    required this.color,
  });
}
