import 'package:flutter/material.dart';
import '../theme/dashboard_palette.dart';

class QuickServicesSection extends StatelessWidget {
  final DashboardPalette palette;
  final VoidCallback onOpenAadhaar;
  final VoidCallback onOpenPassport;
  final VoidCallback onOpenDocument;
  final VoidCallback onOpen4RPhoto;
  final VoidCallback onOpenPVC;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenXerox;
  final VoidCallback onOpenImageEditor;
  final VoidCallback? onOpenWith;

  const QuickServicesSection({
    super.key,
    required this.palette,
    required this.onOpenAadhaar,
    required this.onOpenPassport,
    required this.onOpenDocument,
    required this.onOpen4RPhoto,
    required this.onOpenPVC,
    required this.onOpenPricing,
    required this.onOpenXerox,
    required this.onOpenImageEditor,
    this.onOpenWith,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      _QuickServiceItem(
        title: 'Aadhaar / ID',
        subtitle: 'Front + Back → 4R (85.6 × 54 mm)',
        tag: 'Auto 4R',
        icon: Icons.badge_outlined,
        color: palette.blue,
        onTap: onOpenAadhaar,
      ),
      _QuickServiceItem(
        title: 'Passport Photo',
        subtitle: '30 × 40 mm (8 Copies on 4R sheet)',
        tag: '8 Copies',
        icon: Icons.portrait_rounded,
        color: palette.green,
        onTap: onOpenPassport,
      ),
      _QuickServiceItem(
        title: 'Document Print',
        subtitle: 'A4 / Legal / B&W / Color queue',
        tag: 'High Speed',
        icon: Icons.description_outlined,
        color: palette.purple,
        onTap: onOpenDocument,
      ),
      _QuickServiceItem(
        title: '4R Photo Print',
        subtitle: 'Passport + Stamp mixed studio',
        tag: 'Mixed 4R',
        icon: Icons.photo_size_select_actual_outlined,
        color: palette.orange,
        onTap: onOpen4RPhoto,
      ),
      _QuickServiceItem(
        title: 'ID Card / PVC',
        subtitle: 'PAN, Voter ID, Driving License',
        tag: 'Smart Card',
        icon: Icons.credit_card_rounded,
        color: palette.teal,
        onTap: onOpenPVC,
      ),
      _QuickServiceItem(
        title: 'Pricing & Rates',
        subtitle: 'Service selling rates & profit margins',
        tag: 'Rate Card',
        icon: Icons.sell_outlined,
        color: palette.blue,
        onTap: onOpenPricing,
      ),
      _QuickServiceItem(
        title: 'Scan & Xerox',
        subtitle: 'High speed document multi-copy',
        tag: 'Copier',
        icon: Icons.scanner_rounded,
        color: palette.purple,
        onTap: onOpenXerox,
      ),
      _QuickServiceItem(
        title: 'Image Studio',
        subtitle: '4-corner unskew & enhancement',
        tag: 'Studio Tool',
        icon: Icons.tune_rounded,
        color: palette.red,
        onTap: onOpenImageEditor,
      ),
      if (onOpenWith != null)
        _QuickServiceItem(
          title: 'Open Any File...',
          subtitle: 'Choose photo, doc, or ID to print',
          tag: 'Open With',
          icon: Icons.open_in_new_rounded,
          color: palette.blue,
          onTap: onOpenWith!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Quick Start Services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.pillBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '8 Workflows',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'One-click launch into dedicated printing workflows',
              style: TextStyle(
                fontSize: 11,
                color: palette.textMuted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Grid of Service Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1150
                ? 4
                : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 540 ? 2 : 1));

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 80,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: services.map((s) {
                return _ServiceShortcutTile(palette: palette, item: s);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickServiceItem {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickServiceItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ServiceShortcutTile extends StatefulWidget {
  final DashboardPalette palette;
  final _QuickServiceItem item;

  const _ServiceShortcutTile({
    required this.palette,
    required this.item,
  });

  @override
  State<_ServiceShortcutTile> createState() => _ServiceShortcutTileState();
}

class _ServiceShortcutTileState extends State<_ServiceShortcutTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final palette = widget.palette;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? palette.cardBgElevated : palette.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? item.color : palette.cardBorder,
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? item.color.withValues(alpha: 0.15) : palette.cardShadow,
                blurRadius: _isHovered ? 10 : 4,
                offset: Offset(0, _isHovered ? 3 : 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? item.color.withValues(alpha: 0.18)
                      : item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: palette.isDark
                      ? Border.all(color: item.color.withValues(alpha: 0.3))
                      : null,
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 10),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.pillBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: _isHovered ? item.color : palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Open Action Indicator
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: _isHovered ? item.color : palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
