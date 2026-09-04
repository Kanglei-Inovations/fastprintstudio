import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class SalesByServiceCard extends StatelessWidget {
  final DashboardPalette palette;
  final double totalRevenue;
  final VoidCallback? onViewReport;

  const SalesByServiceCard({
    super.key,
    required this.palette,
    this.totalRevenue = 17850,
    this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      _ServiceShare(name: 'Aadhaar / ID Card', pct: 45, color: palette.blue),
      _ServiceShare(name: 'Passport Photo', pct: 25, color: palette.green),
      _ServiceShare(name: 'Documents Print', pct: 15, color: palette.purple),
      _ServiceShare(name: '4R Photo Print', pct: 10, color: palette.orange),
      _ServiceShare(name: 'Other Services', pct: 5, color: palette.teal),
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
          Text(
            'Sales by Service',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Share of sales by service type',
            style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Donut Chart + Legend Row
          Expanded(
            child: Row(
              children: [
                // 1. Center Donut Gauge
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: _DonutChartPainter(
                              segments: categories,
                              strokeWidth: 20,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹ ${totalRevenue > 0 ? totalRevenue.toStringAsFixed(0) : '17,850'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Legend List
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: palette.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${cat.pct}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Footer Link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onViewReport,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View Report →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceShare {
  final String name;
  final int pct;
  final Color color;

  _ServiceShare({
    required this.name,
    required this.pct,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_ServiceShare> segments;
  final double strokeWidth;

  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    double startAngle = -pi / 2;

    for (final seg in segments) {
      final sweepAngle = (seg.pct / 100) * 2 * pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04, // small gap between segments
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
