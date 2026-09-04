import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_settings.dart';

class SettingsStorage {
  static const _settingsKey = 'fastprint_settings_v1';

  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_settingsKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    return const AppSettings();
  }

  static Future<bool> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(settings.toJson());
      return await prefs.setString(_settingsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }
}
