import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class TopServicesCard extends StatelessWidget {
  final DashboardPalette palette;
  final VoidCallback? onViewAll;

  const TopServicesCard({
    super.key,
    required this.palette,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      _TopServiceItem(rank: '1', name: 'Aadhaar / ID Card', revenue: '₹ 8,025', pct: 45, icon: Icons.badge_outlined, color: palette.blue),
      _TopServiceItem(rank: '2', name: 'Passport Photo', revenue: '₹ 4,462', pct: 25, icon: Icons.portrait_rounded, color: palette.green),
      _TopServiceItem(rank: '3', name: 'Documents Print', revenue: '₹ 2,678', pct: 15, icon: Icons.description_outlined, color: palette.purple),
      _TopServiceItem(rank: '4', name: '4R Photo Print', revenue: '₹ 1,785', pct: 10, icon: Icons.photo_outlined, color: palette.orange),
      _TopServiceItem(rank: '5', name: 'Other Services', revenue: '₹ 890', pct: 5, icon: Icons.sell_outlined, color: palette.teal),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Services',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Most used services by sales volume',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View All →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Ranked Service Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = services[index];

              return Row(
                children: [
                  // Rank number
                  Text(
                    s.rank,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Icon badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: palette.isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(s.icon, size: 14, color: s.color),
                  ),
                  const SizedBox(width: 10),

                  // Name + Horizontal Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: s.pct / 100,
                            minHeight: 4,
                            backgroundColor: palette.pillBg,
                            valueColor: AlwaysStoppedAnimation<Color>(s.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Revenue (Percentage)
                  Text(
                    '${s.revenue} (${s.pct}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                    ),
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

class _TopServiceItem {
  final String rank;
  final String name;
  final String revenue;
  final int pct;
  final IconData icon;
  final Color color;

  _TopServiceItem({
    required this.rank,
    required this.name,
    required this.revenue,
    required this.pct,
    required this.icon,
    required this.color,
  });
}
