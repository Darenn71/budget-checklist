import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

/// A single "money owed to me" row.
class OwedCard extends StatelessWidget {
  final OwedItem item;
  final bool alt;
  final VoidCallback onTogglePaid;
  final VoidCallback onTap;

  const OwedCard({
    super.key,
    required this.item,
    required this.alt,
    required this.onTogglePaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = item.paid
        ? AppColors.cardPaid
        : (alt ? AppColors.surfaceAlt : AppColors.surface);
    final typeColor = item.paid ? AppColors.success : AppColors.teal;
    final strip = item.paid ? AppColors.stripPaid : AppColors.stripOwed;

    final detailParts = <String>['£${item.amount.toStringAsFixed(2)}'];
    if (item.notes.isNotEmpty) detailParts.add(item.notes);
    final detailColor = item.paid ? AppColors.success : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
          IconButton(
            onPressed: onTogglePaid,
            icon: Icon(
              item.paid ? Icons.check_box : Icons.check_box_outline_blank,
              color: item.paid ? AppColors.success : AppColors.textMuted,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 10,
                      children: detailParts
                          .map((t) => Text(
                                t,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, color: detailColor),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 6, color: strip),
          ),
        ],
      ),
    );
  }
}