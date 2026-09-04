import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the Dashboard Theme Mode (Light = Design #3, Dark = Design #4)
final dashboardThemeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light; // Default to Design #3 (Light Theme), easily toggled
});
