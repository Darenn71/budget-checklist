import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

/// A single bill row: checkbox, accent strip, name/due/amount/notes, and a
/// tap target that opens the edit screen.
class BillCard extends StatelessWidget {
  final BillItem bill;
  final bool overdue;
  final bool alt;
  final VoidCallback onTogglePaid;
  final VoidCallback onTap;

  const BillCard({
    super.key,
    required this.bill,
    required this.overdue,
    required this.alt,
    required this.onTogglePaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color nameColor;
    Color strip;

    if (bill.paid) {
      bg = AppColors.cardPaid;
      nameColor = AppColors.success;
      strip = AppColors.stripPaid;
    } else if (overdue) {
      bg = AppColors.cardOverdue;
      nameColor = AppColors.danger;
      strip = AppColors.stripOverdue;
    } else if (alt) {
      bg = AppColors.surfaceAlt;
      nameColor = AppColors.textDark;
      strip = AppColors.stripUnpaid;
    } else {
      bg = AppColors.surface;
      nameColor = AppColors.textDark;
      strip = AppColors.stripUnpaid;
    }

    final amountText = (bill.paid && bill.paidAmount != null)
        ? '£${bill.paidAmount!.toStringAsFixed(2)} paid'
        : '£${bill.amount.toStringAsFixed(2)}';

    final detailParts = <String>[];
    if (bill.due.isNotEmpty) detailParts.add('Due ${bill.due}');
    detailParts.add(amountText);
    if (overdue) detailParts.add('OVERDUE');

    final detailColor =
        overdue ? AppColors.danger : (bill.paid ? AppColors.success : AppColors.textMuted);

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
              bill.paid ? Icons.check_box : Icons.check_box_outline_blank,
              color: bill.paid ? AppColors.success : AppColors.textMuted,
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
                      bill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: nameColor,
                        fontWeight: bill.paid ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 10,
                      children: detailParts
                          .map((t) => Text(
                                t,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: t == 'OVERDUE'
                                      ? AppColors.danger
                                      : detailColor,
                                  fontWeight: t == 'OVERDUE'
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ))
                          .toList(),
                    ),
                    if (bill.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bill.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

/// Pill-shaped section header (e.g. "Unpaid (3)").
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const SectionLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}