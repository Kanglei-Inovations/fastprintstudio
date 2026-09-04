import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inventory_provider.dart';
import '../theme/dashboard_palette.dart';

class InventoryStatusCard extends ConsumerWidget {
  final DashboardPalette palette;
  final VoidCallback? onManageInventory;

  const InventoryStatusCard({
    super.key,
    required this.palette,
    this.onManageInventory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInventory = ref.watch(inventoryProvider);

    // Pick top key consumables to display on dashboard
    final displayItems = <_StockDisplayItem>[];

    if (liveInventory.isNotEmpty) {
      for (final item in liveInventory) {
        if (item.id == 'a4_70gsm') {
          displayItems.add(
            _StockDisplayItem(
              name: 'A4 Xerox Paper',
              stock: '${item.currentStock.toInt()} ${item.unit}',
              isLow: item.isLowStock,
              icon: Icons.description_outlined,
              color: palette.blue,
            ),
          );
        } else if (item.id == 'photo_4r_glossy') {
          displayItems.add(
            _StockDisplayItem(
              name: '4R Photo Paper',
              stock: '${item.currentStock.toInt()} ${item.unit}',
              isLow: item.isLowStock,
              icon: Icons.photo_size_select_actual_outlined,
              color: palette.purple,
            ),
          );
        } else if (item.id == 'pvc_blank') {
          displayItems.add(
            _StockDisplayItem(
              name: 'PVC Card Blanks',
              stock: '${item.currentStock.toInt()} ${item.unit}',
              isLow: item.isLowStock,
              icon: Icons.badge_outlined,
              color: palette.teal,
            ),
          );
        } else if (item.id == 'ink_black') {
          displayItems.add(
            _StockDisplayItem(
              name: 'Black Ink / Toner',
              stock: '${item.currentStock.toStringAsFixed(0)} %',
              isLow: item.isLowStock,
              icon: Icons.colorize_rounded,
              color: palette.orange,
            ),
          );
        }
      }
    }

    // Fallback if empty
    if (displayItems.isEmpty) {
      displayItems.addAll([
        _StockDisplayItem(name: 'A4 Paper', stock: '2500 sheets', isLow: false, icon: Icons.description_outlined, color: palette.blue),
        _StockDisplayItem(name: '4R Photo Paper', stock: '400 sheets', isLow: false, icon: Icons.photo_size_select_actual_outlined, color: palette.purple),
        _StockDisplayItem(name: 'PVC Card Blanks', stock: '250 cards', isLow: false, icon: Icons.badge_outlined, color: palette.teal),
        _StockDisplayItem(name: 'Black Ink / Toner', stock: '85 %', isLow: false, icon: Icons.colorize_rounded, color: palette.orange),
      ]);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live stock levels',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              if (onManageInventory != null)
                InkWell(
                  onTap: onManageInventory,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Manage',
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
          const SizedBox(height: 14),

          // Stock Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final it = displayItems[index];

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: it.color.withValues(alpha: palette.isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(it.icon, size: 16, color: it.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          it.stock,
                          style: TextStyle(fontSize: 10, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: it.isLow
                          ? palette.orange.withValues(alpha: palette.isDark ? 0.2 : 0.12)
                          : palette.green.withValues(alpha: palette.isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      it.isLow ? 'Low' : 'Good',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: it.isLow ? palette.orange : palette.green,
                      ),
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

class _StockDisplayItem {
  final String name;
  final String stock;
  final bool isLow;
  final IconData icon;
  final Color color;

  const _StockDisplayItem({
    required this.name,
    required this.stock,
    required this.isLow,
    required this.icon,
    required this.color,
  });
}
