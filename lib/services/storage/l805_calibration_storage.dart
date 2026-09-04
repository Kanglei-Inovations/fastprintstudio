import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/l805_calibration.dart';

class L805CalibrationStorage {
  static const String _key = 'epson_l805_calibration';

  /// Loads persisted calibration or returns factory default
  static Future<L805Calibration> loadCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return L805Calibration.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading L805 calibration: $e');
    }
    return L805Calibration.factoryDefault;
  }

  /// Persists calibration to SharedPreferences
  static Future<void> saveCalibration(L805Calibration calibration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(calibration.toJson());
      await prefs.setString(_key, jsonStr);
    } catch (e) {
      debugPrint('Error saving L805 calibration: $e');
    }
  }

  /// Resets calibration to factory standard
  static Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Error resetting L805 calibration: $e');
    }
  }
}
