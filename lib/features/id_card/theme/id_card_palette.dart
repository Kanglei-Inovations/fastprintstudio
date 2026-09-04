import 'package:flutter/material.dart';

class IdCardPalette {
  final bool isDark;
  final Color bg;
  final Color cardBg;
  final Color cardBgElevated;
  final Color cardBorder;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color blue;
  final Color blueLight;
  final Color green;
  final Color greenLight;
  final Color orange;
  final Color orangeLight;
  final Color purple;
  final Color purpleLight;
  final Color red;
  final Color teal;
  final Color divider;
  final Color pillBg;
  final Color pillBorder;
  final Color canvasBg;

  const IdCardPalette({
    required this.isDark,
    required this.bg,
    required this.cardBg,
    required this.cardBgElevated,
    required this.cardBorder,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.blue,
    required this.blueLight,
    required this.green,
    required this.greenLight,
    required this.orange,
    required this.orangeLight,
    required this.purple,
    required this.purpleLight,
    required this.red,
    required this.teal,
    required this.divider,
    required this.pillBg,
    required this.pillBorder,
    required this.canvasBg,
  });

  factory IdCardPalette.of(BuildContext context, {bool? isDark}) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    if (dark) {
      // Dark Mode (Visual Language of Design #4)
      return const IdCardPalette(
        isDark: true,
        bg: Color(0xFF0B0F19),
        cardBg: Color(0xFF131B2A),
        cardBgElevated: Color(0xFF1B2438),
        cardBorder: Color(0xFF222F45),
        cardShadow: Color(0x33000000),
        textPrimary: Color(0xFFF1F5F9),
        textSecondary: Color(0xFF94A3B8),
        textMuted: Color(0xFF64748B),
        blue: Color(0xFF38BDF8),
        blueLight: Color(0x2A38BDF8),
        green: Color(0xFF34D399),
        greenLight: Color(0x2A34D399),
        orange: Color(0xFFFB923C),
        orangeLight: Color(0x2AFB923C),
        purple: Color(0xFFA78BFA),
        purpleLight: Color(0x2AA78BFA),
        red: Color(0xFFF87171),
        teal: Color(0xFF2DD4BF),
        divider: Color(0xFF1E293B),
        pillBg: Color(0xFF192233),
        pillBorder: Color(0xFF2B3A54),
        canvasBg: Color(0xFF0F1523),
      );
    } else {
      // Light Mode (Visual Language of Design #3)
      return const IdCardPalette(
        isDark: false,
        bg: Color(0xFFF8FAFC),
        cardBg: Color(0xFFFFFFFF),
        cardBgElevated: Color(0xFFFFFFFF),
        cardBorder: Color(0xFFE2E8F0),
        cardShadow: Color(0x0A000000),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF475569),
        textMuted: Color(0xFF94A3B8),
        blue: Color(0xFF2563EB),
        blueLight: Color(0xFFEFF6FF),
        green: Color(0xFF059669),
        greenLight: Color(0xFFECFDF5),
        orange: Color(0xFFD97706),
        orangeLight: Color(0xFFFFFBEB),
        purple: Color(0xFF7C3AED),
        purpleLight: Color(0xFFF5F3FF),
        red: Color(0xFFDC2626),
        teal: Color(0xFF0D9488),
        divider: Color(0xFFE2E8F0),
        pillBg: Color(0xFFF1F5F9),
        pillBorder: Color(0xFFCBD5E1),
        canvasBg: Color(0xFFF1F5F9),
      );
    }
  }
}
