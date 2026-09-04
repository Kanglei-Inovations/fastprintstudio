import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class RemindersSection extends StatelessWidget {
  final DashboardPalette palette;
  final VoidCallback? onBackupNow;
  final VoidCallback? onScheduleMaintenance;

  const RemindersSection({
    super.key,
    required this.palette,
    this.onBackupNow,
    this.onScheduleMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders & Alerts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // 4 Reminder Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1050
                ? 4
                : (constraints.maxWidth > 600 ? 2 : 1);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 72,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 1. Low Ink Alert
                _ReminderCard(
                  palette: palette,
                  icon: Icons.warning_amber_rounded,
                  color: palette.red,
                  title: 'Low Ink Alert',
                  subtitle: 'Black ink level is low • 45% remaining',
                ),

                // 2. Paper Stock Alert
                _ReminderCard(
                  palette: palette,
                  icon: Icons.layers_outlined,
                  color: palette.orange,
                  title: 'Paper Stock Alert',
                  subtitle: '4R photo paper stock low • 86 packs left',
                ),

                // 3. Backup Reminder
                _ReminderCard(
                  palette: palette,
                  icon: Icons.cloud_done_outlined,
                  color: palette.blue,
                  title: 'Backup Reminder',
                  subtitle: 'Last backup 3 days ago',
                  actionLabel: 'Backup Now',
                  onAction: onBackupNow,
                ),

                // 4. Maintenance
                _ReminderCard(
                  palette: palette,
                  icon: Icons.handyman_outlined,
                  color: palette.purple,
                  title: 'Maintenance',
                  subtitle: 'Printer head cleaning due',
                  actionLabel: 'Schedule Now',
                  onAction: onScheduleMaintenance,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final DashboardPalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ReminderCard({
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.5, color: palette.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: palette.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
