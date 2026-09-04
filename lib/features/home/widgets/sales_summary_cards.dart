import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class SalesSummaryCards extends StatelessWidget {
  final DashboardPalette palette;
  final double todaySales;
  final int todayJobs;
  final int printsCompleted;
  final int pendingJobs;
  final double salesGrowth;
  final double jobsGrowth;
  final double printsGrowth;
  final double pendingGrowth;

  const SalesSummaryCards({
    super.key,
    required this.palette,
    required this.todaySales,
    required this.todayJobs,
    required this.printsCompleted,
    required this.pendingJobs,
    this.salesGrowth = 18.6,
    this.jobsGrowth = 27.8,
    this.printsGrowth = 15.2,
    this.pendingGrowth = 16.7,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 4
            : (constraints.maxWidth > 640 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 145,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Today's Sale
            _SummaryCard(
              palette: palette,
              title: "Today's Sale",
              value: '₹ ${todaySales > 0 ? todaySales.toStringAsFixed(0) : '2,450'}',
              trend: '↑ $salesGrowth%',
              trendSubtitle: 'vs yesterday',
              isPositiveTrend: true,
              icon: Icons.currency_rupee_rounded,
              accentColor: palette.blue,
              iconBgColor: palette.blueLight,
              sparklinePoints: const [0.3, 0.45, 0.35, 0.6, 0.48, 0.75, 0.68, 0.9, 0.85, 0.95],
            ),

            // 2. Today's Jobs
            _SummaryCard(
              palette: palette,
              title: "Today's Jobs",
              value: '${todayJobs > 0 ? todayJobs : 23}',
              trend: '↑ $jobsGrowth%',
              trendSubtitle: 'vs yesterday',
              isPositiveTrend: true,
              icon: Icons.work_outline_rounded,
              accentColor: palette.green,
              iconBgColor: palette.greenLight,
              sparklinePoints: const [0.25, 0.3, 0.5, 0.4, 0.65, 0.55, 0.8, 0.7, 0.88, 0.92],
            ),

            // 3. Prints Completed
            _SummaryCard(
              palette: palette,
              title: 'Prints Completed',
              value: '${printsCompleted > 0 ? printsCompleted : 56}',
              trend: '↑ $printsGrowth%',
              trendSubtitle: 'vs yesterday',
              isPositiveTrend: true,
              icon: Icons.print_outlined,
              accentColor: palette.purple,
              iconBgColor: palette.purpleLight,
              sparklinePoints: const [0.4, 0.35, 0.6, 0.5, 0.45, 0.7, 0.6, 0.85, 0.8, 0.9],
            ),

            // 4. Pending Jobs
            _SummaryCard(
              palette: palette,
              title: 'Pending Jobs',
              value: '${pendingJobs > 0 ? pendingJobs : 5}',
              trend: '↑ $pendingGrowth%',
              trendSubtitle: 'vs yesterday',
              isPositiveTrend: true,
              icon: Icons.access_time_rounded,
              accentColor: palette.orange,
              iconBgColor: palette.orangeLight,
              sparklinePoints: const [0.5, 0.4, 0.55, 0.35, 0.6, 0.5, 0.7, 0.65, 0.8, 0.75],
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DashboardPalette palette;
  final String title;
  final String value;
  final String trend;
  final String trendSubtitle;
  final bool isPositiveTrend;
  final IconData icon;
  final Color accentColor;
  final Color iconBgColor;
  final List<double> sparklinePoints;

  const _SummaryCard({
    required this.palette,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendSubtitle,
    required this.isPositiveTrend,
    required this.icon,
    required this.accentColor,
    required this.iconBgColor,
    required this.sparklinePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Sparkline Wave at the bottom of the card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 38,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: sparklinePoints,
                  color: accentColor,
                  fillColor: accentColor.withValues(alpha: palette.isDark ? 0.12 : 0.08),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + Icon Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? accentColor.withValues(alpha: 0.18)
                              : iconBgColor,
                          shape: BoxShape.circle,
                          border: palette.isDark
                              ? Border.all(color: accentColor.withValues(alpha: 0.35))
                              : null,
                        ),
                        child: Icon(icon, size: 14, color: accentColor),
                      ),
                    ],
                  ),

                  // Large Value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Trend subtitle
                  Row(
                    children: [
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isPositiveTrend ? palette.green : palette.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendSubtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Sparkline Wave Painter for KPI Cards
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final Color fillColor;

  _SparklinePainter({
    required this.points,
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path();
    final fillPath = Path();

    final dx = size.width / (points.length - 1);
    final firstY = size.height - (points[0] * (size.height - 8)) - 4;

    path.moveTo(0, firstY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, firstY);

    for (int i = 0; i < points.length - 1; i++) {
      final p0x = i * dx;
      final p0y = size.height - (points[i] * (size.height - 8)) - 4;
      final p1x = (i + 1) * dx;
      final p1y = size.height - (points[i + 1] * (size.height - 8)) - 4;

      final midX = (p0x + p1x) / 2;
      path.cubicTo(midX, p0y, midX, p1y, p1x, p1y);
      fillPath.cubicTo(midX, p0y, midX, p1y, p1x, p1y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw translucent gradient fill under curve
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw curve line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
