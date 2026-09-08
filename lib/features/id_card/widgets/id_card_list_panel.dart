import 'package:flutter/material.dart';
import '../../../core/models/id_card_entry.dart';
import '../../../shared/widgets/pulsing_dot.dart';
import '../theme/id_card_palette.dart';

/// Panel displaying the list of loaded ID cards in multi-person workflow
class IdCardListPanel extends StatelessWidget {
  final IdCardPalette palette;
  final List<IdCardEntry> cards;
  final String? activeCardId;
  final ValueChanged<String> onSelectCard;
  final ValueChanged<String> onRemoveCard;
  final VoidCallback onAddCard;
  final void Function(String frontCardId, String backCardId)? onMergeCards;

  const IdCardListPanel({
    super.key,
    required this.palette,
    required this.cards,
    required this.activeCardId,
    required this.onSelectCard,
    required this.onRemoveCard,
    required this.onAddCard,
    this.onMergeCards,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final activeId = activeCardId ?? cards.first.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, size: 16, color: palette.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Cards / Persons (${cards.length})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              if (cards.length >= 2 && onMergeCards != null)
                Tooltip(
                  message: 'Join Card 1 & Card 2 as Front & Back of 1 card',
                  child: InkWell(
                    onTap: () => onMergeCards!(cards[0].id, cards[1].id),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.isDark ? palette.purple.withValues(alpha: 0.2) : palette.purpleLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.purple.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded, size: 14, color: palette.purple),
                          const SizedBox(width: 3),
                          Text(
                            'Join F+B',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Cards list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final card = cards[index];
                final isSelected = card.id == activeId;

                return InkWell(
                  onTap: () => onSelectCard(card.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight)
                          : palette.pillBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? palette.blue : palette.pillBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Card Number Badge
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? palette.blue : (palette.isDark ? Colors.white12 : Colors.black12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Card Name & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isSelected) ...[
                                    PulsingDot(color: palette.blue, size: 5.5),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      card.name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? palette.blue : palette.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    card.hasBothSides ? 'Front & Back' : 'Front Only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                  if (card.isPdf) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: palette.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'PDF',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: palette.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Join with Next Card as Back
                        if (index + 1 < cards.length && onMergeCards != null)
                          Tooltip(
                            message: 'Join as Front with Card ${index + 2} as Back',
                            child: InkWell(
                              onTap: () => onMergeCards!(card.id, cards[index + 1].id),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: palette.purple,
                                ),
                              ),
                            ),
                          ),

                        // Remove Button (when more than 1 card)
                        if (cards.length > 1)
                          InkWell(
                            onTap: () => onRemoveCard(card.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
