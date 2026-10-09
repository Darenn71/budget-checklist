/// A warm, "Claude"-inspired visual theme: soft paper background, terracotta
/// accent, sage greens and clay reds instead of the original cool navy/blue
/// palette.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFFF7F4EC); // warm paper
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1EDE2); // alternating row tint
  static const headerBg = Color(0xFF3D3929); // deep warm charcoal-brown

  // Card states
  static const cardPaid = Color(0xFFEEF3E8); // faint sage
  static const cardOverdue = Color(0xFFFBEAE5); // faint clay

  // Accents
  static const primary = Color(0xFFCC785C); // Claude terracotta
  static const primaryDark = Color(0xFFB35F44);
  static const success = Color(0xFF7A9A65); // sage green
  static const danger = Color(0xFFC1543C); // clay red
  static const amber = Color(0xFFCE9A4B);
  static const teal = Color(0xFF5E8C82);
  static const neutral = Color(0xFF8C8A82);

  // Strips
  static const stripUnpaid = primary;
  static const stripPaid = success;
  static const stripOverdue = danger;
  static const stripOwed = teal;

  // Text
  static const textDark = Color(0xFF2D2A24);
  static const textMuted = Color(0xFF918E85);

  // Lines
  static const divider = Color(0xFFE7E2D5);
  static const cardBorder = Color(0xFFE7E2D5);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.teal,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.success;
          return AppColors.neutral;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.success.withOpacity(0.35);
          }
          return AppColors.cardBorder;
        }),
      ),
    );
  }
}

/// Helper for a tall, rounded "block" action button with a subtle shadow
/// strip — echoes the original app's `_big_btn`.
class BigButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;

  const BigButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
}
