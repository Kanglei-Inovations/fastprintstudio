import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/print_history_item.dart';

class HistoryStorage {
  static const _historyKey = 'fastprint_history_v1';
  static const int maxHistoryItems = 100;

  static Future<List<PrintHistoryItem>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = prefs.getStringList(_historyKey);
      if (jsonListStr != null) {
        return jsonListStr
            .map((str) => PrintHistoryItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading print history: $e');
    }
    return [];
  }

  static Future<void> addHistoryItem(PrintHistoryItem item) async {
    try {
      final history = await loadHistory();
      // Add newest at top
      history.insert(0, item);
      if (history.length > maxHistoryItems) {
        history.removeRange(maxHistoryItems, history.length);
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = history.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonListStr);
    } catch (e) {
      debugPrint('Error saving print history item: $e');
    }
  }

  static Future<void> saveAll(List<PrintHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = items.take(maxHistoryItems).map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonListStr);
    } catch (e) {
      debugPrint('Error saving all print history: $e');
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Error clearing print history: $e');
    }
  }
}
