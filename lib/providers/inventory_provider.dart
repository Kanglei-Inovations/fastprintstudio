import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/inventory_item.dart';
import '../core/models/print_history_item.dart';
import '../services/storage/inventory_storage.dart';

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  InventoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await InventoryStorage.loadInventory();
  }

  Future<void> updateStock(String id, double newStock) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(currentStock: newStock.clamp(0.0, 999999.0)) else item,
    ];
    await InventoryStorage.saveInventory(state);
  }

  Future<void> addStock(String id, double amount) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(currentStock: item.currentStock + amount) else item,
    ];
    await InventoryStorage.saveInventory(state);
  }

  Future<void> deductStock(String id, double amount) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(currentStock: (item.currentStock - amount).clamp(0.0, 999999.0))
        else
          item,
    ];
    await InventoryStorage.saveInventory(state);
  }

  /// Automatically deducts consumed materials and ink based on printed record
  Future<void> deductForPrintJob(PrintHistoryItem record) async {
    final lowerService = record.serviceName.toLowerCase();
    final lowerPaper = record.paperName.toLowerCase();

    // 1. Photo Print (4R)
    if (lowerService.contains('photo') || lowerPaper.contains('4r')) {
      final sheets = (record.copiesCount / 8).ceil().clamp(1, 999);
      if (lowerPaper.contains('matte')) {
        await deductStock('photo_4r_matte', sheets.toDouble());
      } else {
        await deductStock('photo_4r_glossy', sheets.toDouble());
      }
      // Deduct color ink (approx 0.15% per sheet)
      await deductStock('ink_black', 0.05 * sheets);
      await deductStock('ink_cyan', 0.10 * sheets);
      await deductStock('ink_magenta', 0.10 * sheets);
      await deductStock('ink_yellow', 0.10 * sheets);
    }
    // 2. ID Card Print
    else if (lowerService.contains('aadhaar') ||
        lowerService.contains('pan') ||
        lowerService.contains('voter') ||
        lowerService.contains('id card')) {
      final cards = record.copiesCount;
      if (lowerPaper.contains('pvc')) {
        await deductStock('pvc_blank', cards.toDouble());
      } else if (lowerPaper.contains('dragon')) {
        final dragonSheets = (cards / 5).ceil().clamp(1, 99);
        await deductStock('dragon_sheet', dragonSheets.toDouble());
      } else {
        // Lamination workflow: 4R photo paper + lamination pouch
        final photoSheets = (cards / 2).ceil().clamp(1, 999);
        await deductStock('photo_4r_glossy', photoSheets.toDouble());
        await deductStock('lamination_pouch', cards.toDouble());
      }
      await deductStock('ink_black', 0.08 * cards);
      await deductStock('ink_cyan', 0.05 * cards);
      await deductStock('ink_magenta', 0.05 * cards);
      await deductStock('ink_yellow', 0.05 * cards);
    }
    // 3. Document Print
    else {
      final pages = record.copiesCount;
      final sheets = lowerPaper.contains('duplex') ? (pages / 2).ceil() : pages;

      if (lowerPaper.contains('75') || lowerPaper.contains('bond')) {
        await deductStock('a4_75gsm', sheets.toDouble());
      } else if (lowerPaper.contains('100')) {
        await deductStock('a4_100gsm', sheets.toDouble());
      } else {
        await deductStock('a4_70gsm', sheets.toDouble());
      }

      await deductStock('ink_black', 0.02 * pages);
    }
  }

  Future<void> resetToDefaults() async {
    state = List.from(InventoryStorage.defaultInventory);
    await InventoryStorage.saveInventory(state);
  }

  List<InventoryItem> get lowStockItems => state.where((i) => i.isLowStock).toList();
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  return InventoryNotifier();
});
