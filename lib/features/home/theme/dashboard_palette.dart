import 'package:flutter/material.dart';

/// Design #3 (Light) and Design #4 (Dark) Color Palettes for FastPrint Studio Dashboard
class DashboardPalette {
  final bool isDark;
  final Color bg;
  final Color cardBg;
  final Color cardBgElevated;
  final Color cardBorder;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color pillBg;
  final Color pillBorder;
  final Color divider;

  // Accents
  final Color blue;
  final Color blueLight;
  final Color green;
  final Color greenLight;
  final Color purple;
  final Color purpleLight;
  final Color orange;
  final Color orangeLight;
  final Color red;
  final Color teal;

  const DashboardPalette({
    required this.isDark,
    required this.bg,
    required this.cardBg,
    required this.cardBgElevated,
    required this.cardBorder,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.pillBg,
    required this.pillBorder,
    required this.divider,
    required this.blue,
    required this.blueLight,
    required this.green,
    required this.greenLight,
    required this.purple,
    required this.purpleLight,
    required this.orange,
    required this.orangeLight,
    required this.red,
    required this.teal,
  });

  /// Design #3: Clean, Premium Light SaaS Theme
  factory DashboardPalette.light() {
    return const DashboardPalette(
      isDark: false,
      bg: Color(0xFFF4F6F9), // Soft off-white
      cardBg: Color(0xFFFFFFFF), // Pure white
      cardBgElevated: Color(0xFFFAFCFF),
      cardBorder: Color(0xFFE2E8F0),
      cardShadow: Color(0x0A000000),
      textPrimary: Color(0xFF0F172A), // Dark slate
      textSecondary: Color(0xFF64748B), // Slate gray
      textMuted: Color(0xFF94A3B8), // Light slate
      pillBg: Color(0xFFF1F5F9),
      pillBorder: Color(0xFFE2E8F0),
      divider: Color(0xFFF1F5F9),
      blue: Color(0xFF2563EB),
      blueLight: Color(0xFFEFF6FF),
      green: Color(0xFF10B981),
      greenLight: Color(0xFFECFDF5),
      purple: Color(0xFF8B5CF6),
      purpleLight: Color(0xFFF5F3FF),
      orange: Color(0xFFF59E0B),
      orangeLight: Color(0xFFFFFBEB),
      red: Color(0xFFEF4444),
      teal: Color(0xFF06B6D4),
    );
  }

  /// Design #4: Sophisticated, Modern Charcoal/Navy Dark Theme
  factory DashboardPalette.dark() {
    return const DashboardPalette(
      isDark: true,
      bg: Color(0xFF0B101B), // Deep charcoal/navy
      cardBg: Color(0xFF131B2C), // Elevated dark card
      cardBgElevated: Color(0xFF1A243B),
      cardBorder: Color(0x1FFFFFFF), // Subtle glass border
      cardShadow: Color(0x28000000),
      textPrimary: Color(0xFFF8FAFC), // Crisp white
      textSecondary: Color(0xFF94A3B8), // Soft silver
      textMuted: Color(0xFF64748B), // Muted dark slate
      pillBg: Color(0x14FFFFFF),
      pillBorder: Color(0x1FFFFFFF),
      divider: Color(0x14FFFFFF),
      blue: Color(0xFF38BDF8),
      blueLight: Color(0x1F38BDF8),
      green: Color(0xFF34D399),
      greenLight: Color(0x1F34D399),
      purple: Color(0xFFA78BFA),
      purpleLight: Color(0x1FA78BFA),
      orange: Color(0xFFFBBF24),
      orangeLight: Color(0x1FFBBF24),
      red: Color(0xFFF87171),
      teal: Color(0xFF2DD4BF),
    );
  }

  static DashboardPalette of(BuildContext context, {bool isDark = false}) {
    return isDark ? DashboardPalette.dark() : DashboardPalette.light();
  }
}
