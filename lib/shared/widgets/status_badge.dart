import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

enum BadgeVariant { primary, success, warning, error, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final BadgeVariant variant;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.text,
    this.icon,
    this.variant = BadgeVariant.primary,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.primary:
        bg = palette.primaryLight;
        fg = palette.primary;
        break;
      case BadgeVariant.success:
        bg = palette.successLight;
        fg = palette.success;
        break;
      case BadgeVariant.warning:
        bg = palette.warningLight;
        fg = palette.warning;
        break;
      case BadgeVariant.error:
        bg = palette.errorLight;
        fg = palette.error;
        break;
      case BadgeVariant.neutral:
        bg = palette.pillBg;
        fg = palette.textSecondary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 3.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: fg.withValues(alpha: palette.isDark ? 0.35 : 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 10 : 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
