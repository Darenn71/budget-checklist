import 'package:flutter/material.dart';
import '../theme.dart';

/// A small dashboard tile showing a label + value, with a coloured accent
/// strip. Can optionally be editable (used for the bank balance).
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool editable;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.editable = false,
    this.controller,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (editable)
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: onSubmitted,
                        onTapOutside: (_) {
                          if (onSubmitted != null && controller != null) {
                            onSubmitted!(controller!.text);
                          }
                        },
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          prefixText: '£',
                        ),
                      )
                    else
                      Text(
                        '£$value',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
