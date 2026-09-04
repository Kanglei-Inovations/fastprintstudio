import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/inventory_item.dart';

class InventoryStorage {
  static const _inventoryKey = 'fastprint_inventory_v1';

  static final List<InventoryItem> defaultInventory = [
    const InventoryItem(
      id: 'a4_70gsm',
      name: 'A4 70 GSM Xerox Paper',
      category: 'Paper',
      currentStock: 2500,
      minThreshold: 500,
      unit: 'sheets',
      costPerUnit: 0.50,
    ),
    const InventoryItem(
      id: 'a4_75gsm',
      name: 'A4 75 GSM Executive Bond',
      category: 'Paper',
      currentStock: 1000,
      minThreshold: 250,
      unit: 'sheets',
      costPerUnit: 0.80,
    ),
    const InventoryItem(
      id: 'a4_100gsm',
      name: 'A4 100 GSM Heavyweight',
      category: 'Paper',
      currentStock: 500,
      minThreshold: 100,
      unit: 'sheets',
      costPerUnit: 1.50,
    ),
    const InventoryItem(
      id: 'photo_4r_glossy',
      name: '4R Glossy Photo Paper',
      category: 'Paper',
      currentStock: 400,
      minThreshold: 100,
      unit: 'sheets',
      costPerUnit: 4.00,
    ),
    const InventoryItem(
      id: 'photo_4r_matte',
      name: '4R Matte Photo Paper',
      category: 'Paper',
      currentStock: 200,
      minThreshold: 50,
      unit: 'sheets',
      costPerUnit: 4.50,
    ),
    const InventoryItem(
      id: 'pvc_blank',
      name: 'PVC Card Blanks (CR80)',
      category: 'Cards & Pouches',
      currentStock: 250,
      minThreshold: 50,
      unit: 'cards',
      costPerUnit: 12.00,
    ),
    const InventoryItem(
      id: 'dragon_sheet',
      name: 'Dragon Sheet 200×300mm',
      category: 'Cards & Pouches',
      currentStock: 100,
      minThreshold: 20,
      unit: 'sheets',
      costPerUnit: 25.00,
    ),
    const InventoryItem(
      id: 'lamination_pouch',
      name: 'ID Lamination Pouches (350 Micron)',
      category: 'Cards & Pouches',
      currentStock: 350,
      minThreshold: 50,
      unit: 'pouches',
      costPerUnit: 2.50,
    ),
    const InventoryItem(
      id: 'spiral_coils',
      name: 'Spiral Binding Coils (A4)',
      category: 'Binding',
      currentStock: 80,
      minThreshold: 20,
      unit: 'units',
      costPerUnit: 10.00,
    ),
    const InventoryItem(
      id: 'ink_black',
      name: 'Black Ink / Toner',
      category: 'Ink / Toner',
      currentStock: 85.0,
      minThreshold: 20.0,
      unit: '%',
      costPerUnit: 550.00,
    ),
    const InventoryItem(
      id: 'ink_cyan',
      name: 'Cyan Ink Bottle',
      category: 'Ink / Toner',
      currentStock: 72.0,
      minThreshold: 20.0,
      unit: '%',
      costPerUnit: 450.00,
    ),
    const InventoryItem(
      id: 'ink_magenta',
      name: 'Magenta Ink Bottle',
      category: 'Ink / Toner',
      currentStock: 68.0,
      minThreshold: 20.0,
      unit: '%',
      costPerUnit: 450.00,
    ),
    const InventoryItem(
      id: 'ink_yellow',
      name: 'Yellow Ink Bottle',
      category: 'Ink / Toner',
      currentStock: 90.0,
      minThreshold: 20.0,
      unit: '%',
      costPerUnit: 450.00,
    ),
  ];

  static Future<List<InventoryItem>> loadInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = prefs.getStringList(_inventoryKey);
      if (jsonListStr != null && jsonListStr.isNotEmpty) {
        return jsonListStr
            .map((str) => InventoryItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    }
    return List.from(defaultInventory);
  }

  static Future<void> saveInventory(List<InventoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = items.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_inventoryKey, jsonListStr);
    } catch (e) {
      debugPrint('Error saving inventory: $e');
    }
  }
}
