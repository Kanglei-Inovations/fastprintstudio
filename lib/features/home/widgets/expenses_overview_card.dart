import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class ExpensesOverviewCard extends StatelessWidget {
  final DashboardPalette palette;
  final VoidCallback? onViewDetails;

  const ExpensesOverviewCard({
    super.key,
    required this.palette,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final expenses = [
      _ExpenseItem(name: 'Ink / Toner', pct: 45, amount: '₹ 3,050', color: palette.purple),
      _ExpenseItem(name: 'Paper A4', pct: 20, amount: '₹ 1,356', color: palette.blue),
      _ExpenseItem(name: '4R Paper', pct: 15, amount: '₹ 1,017', color: palette.red),
      _ExpenseItem(name: 'Maintenance', pct: 10, amount: '₹ 678', color: palette.orange),
      _ExpenseItem(name: 'Grocery & Other', pct: 10, amount: '₹ 679', color: palette.teal),
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
            'Expenses Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'This Month Expenses',
            style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Total Expenses Callout
          Text(
            'Total Expenses',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: palette.textMuted),
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '₹ 6,780',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                '↓ 8.6% vs last month',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.green),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mini Donut Gauge + Expense Breakdown
          Row(
            children: [
              // Donut
              SizedBox(
                width: 76,
                height: 76,
                child: CustomPaint(
                  painter: _MiniDonutPainter(items: expenses),
                ),
              ),

              const SizedBox(width: 12),

              // Legend
              Expanded(
                child: Column(
                  children: expenses.map((exp) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: exp.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exp.name,
                              style: TextStyle(fontSize: 10, color: palette.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${exp.pct}%',
                            style: TextStyle(fontSize: 9.5, color: palette.textMuted),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            exp.amount,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Footer Link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onViewDetails,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View Details →',
                  style: TextStyle(
                    fontSize: 10.5,
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

class _ExpenseItem {
  final String name;
  final int pct;
  final String amount;
  final Color color;

  _ExpenseItem({
    required this.name,
    required this.pct,
    required this.amount,
    required this.color,
  });
}

class _MiniDonutPainter extends CustomPainter {
  final List<_ExpenseItem> items;

  _MiniDonutPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    double startAngle = -pi / 2;

    for (final it in items) {
      final sweepAngle = (it.pct / 100) * 2 * pi;
      final paint = Paint()
        ..color = it.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter oldDelegate) => false;
}
