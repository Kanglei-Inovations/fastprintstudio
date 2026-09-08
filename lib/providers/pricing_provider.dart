import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/pricing_item.dart';
import '../services/storage/pricing_storage.dart';

class PricingNotifier extends StateNotifier<List<PricingItem>> {
  PricingNotifier() : super(PricingStorage.defaultPricing) {
    loadPricing();
  }

  Future<void> loadPricing() async {
    final list = await PricingStorage.loadPricing();
    state = list;
  }

  Future<void> addPricingItem(PricingItem item) async {
    final updated = [...state, item];
    state = updated;
    await PricingStorage.savePricing(updated);
  }

  Future<void> updatePricingItem(PricingItem item) async {
    final updated = state.map((i) => i.id == item.id ? item : i).toList();
    state = updated;
    await PricingStorage.savePricing(updated);
  }

  Future<void> deletePricingItem(String id) async {
    final updated = state.where((i) => i.id != id).toList();
    state = updated;
    await PricingStorage.savePricing(updated);
  }

  Future<void> resetToDefaults() async {
    await PricingStorage.resetPricing();
    state = PricingStorage.defaultPricing;
  }

  /// Looks up price and cost for a given service name from print history
  PricingItem getPriceForService(String serviceName) {
    final s = serviceName.toLowerCase();
    if (s.contains('xerox') && (s.contains('card') || s.contains('id') || s.contains('aadhaar'))) {
      return state.firstWhere((p) => p.id == 'id_card_xerox', orElse: () => state[2]);
    }
    if (s.contains('pvc')) {
      return state.firstWhere((p) => p.id == 'aadhaar_pvc', orElse: () => state[1]);
    }
    if (s.contains('aadhaar')) {
      return state.firstWhere((p) => p.id == 'aadhaar_lamination', orElse: () => state[0]);
    }
    if (s.contains('pan')) {
      return state.firstWhere((p) => p.id == 'pan_card', orElse: () => state[3]);
    }
    if (s.contains('voter') || s.contains('driving') || s.contains('license') || s.contains('id card') || s.contains('id_card')) {
      return state.firstWhere((p) => p.id == 'id_print', orElse: () => state[2]);
    }
    if (s.contains('passport') || s.contains('stamp') || s.contains('photo') || s.contains('4r')) {
      return state.firstWhere((p) => p.id == 'photo_print_4r', orElse: () => state[4]);
    }
    if (s.contains('color')) {
      return state.firstWhere((p) => p.id == 'doc_print_color', orElse: () => state[7]);
    }
    if (s.contains('doc') || s.contains('xerox') || s.contains('print')) {
      return state.firstWhere((p) => p.id == 'doc_print_bw', orElse: () => state[6]);
    }
    return state.first;
  }
}

final pricingProvider = StateNotifierProvider<PricingNotifier, List<PricingItem>>((ref) {
  return PricingNotifier();
});
