import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class AppSectionCard extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? badge;
  final Widget? headerAction;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppSectionCard({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.badge,
    this.headerAction,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null || headerAction != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: palette.primary),
                    const SizedBox(width: 8),
                  ],
                  if (title != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                badge!,
                              ],
                            ],
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ?headerAction,
                ],
              ),
            ),
            Divider(height: 1, color: palette.divider),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
