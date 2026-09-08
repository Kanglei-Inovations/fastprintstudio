import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/pricing_item.dart';

class PricingStorage {
  static const _pricingKey = 'fastprint_pricing_v1';

  static List<PricingItem> get defaultPricing => const [
        PricingItem(
          id: 'aadhaar_lamination',
          name: 'Aadhaar Lamination Print',
          category: 'Card Printing',
          price: 30.0,
          cost: 6.0,
          unit: 'per card',
          description: 'Front & back laminated Aadhaar card print on 4R photo sheet',
        ),
        PricingItem(
          id: 'aadhaar_pvc',
          name: 'Aadhaar PVC Print',
          category: 'Card Printing',
          price: 60.0,
          cost: 18.0,
          unit: 'per card',
          description: 'High durability PVC plastic smart card print with glossy finish',
        ),
        PricingItem(
          id: 'id_card_xerox',
          name: 'ID Card Xerox (Paper Copy)',
          category: 'Card Printing',
          price: 10.0,
          cost: 1.5,
          unit: 'per card',
          description: 'Front & back ID card copy on normal paper in Color',
        ),
        PricingItem(
          id: 'id_card_xerox_bw',
          name: 'ID Card Xerox (Black & White)',
          category: 'Card Printing',
          price: 5.0,
          cost: 1.5,
          unit: 'per card',
          description: 'Front & back ID card copy on normal paper in Black & White',
        ),
        PricingItem(
          id: 'id_print',
          name: 'ID Card / Voter / DL Print',
          category: 'Card Printing',
          price: 35.0,
          cost: 7.0,
          unit: 'per card',
          description: 'Standard Voter ID, Driving License & College ID print',
        ),
        PricingItem(
          id: 'pan_card',
          name: 'PAN Card Print',
          category: 'Card Printing',
          price: 35.0,
          cost: 7.0,
          unit: 'per card',
          description: 'Standard NSDL / UTI PAN card print format',
        ),
        PricingItem(
          id: 'photo_print_4r',
          name: 'Photo Print (Passport / Mixed Stamp 4R)',
          category: 'Photo Studio',
          price: 40.0,
          cost: 10.0,
          unit: 'per 4R sheet',
          description: 'Standard 4R photo sheet with 8 Passport or mixed Passport + Stamp photos (Fixed ₹40)',
        ),
        PricingItem(
          id: 'photo_4r_glossy',
          name: '4R Glossy Photo Print',
          category: 'Photo Studio',
          price: 35.0,
          cost: 8.0,
          unit: 'per 4R sheet',
          description: 'Single high resolution 4x6 inch studio glossy photo',
        ),
        PricingItem(
          id: 'doc_print_bw',
          name: 'Document Print (Black & White)',
          category: 'Document Xerox',
          price: 3.0,
          cost: 0.60,
          unit: 'per page',
          description: 'Single or double sided laser black & white print (A4 / Legal)',
        ),
        PricingItem(
          id: 'doc_print_color',
          name: 'Document Print (Color)',
          category: 'Document Xerox',
          price: 10.0,
          cost: 2.50,
          unit: 'per page',
          description: 'Full color inkjet or laser document print on 75 GSM paper',
        ),
        PricingItem(
          id: 'doc_lamination_a4',
          name: 'A4 Document Lamination',
          category: 'Document Xerox',
          price: 20.0,
          cost: 5.0,
          unit: 'per doc',
          description: 'Heavy duty hot pouch lamination for certificates and marksheets',
        ),
      ];

  static Future<List<PricingItem>> loadPricing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = prefs.getStringList(_pricingKey);
      if (jsonListStr != null && jsonListStr.isNotEmpty) {
        return jsonListStr
            .map((str) => PricingItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading pricing: $e');
    }
    return defaultPricing;
  }

  static Future<void> savePricing(List<PricingItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonListStr = items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_pricingKey, jsonListStr);
    } catch (e) {
      debugPrint('Error saving pricing: $e');
    }
  }

  static Future<void> resetPricing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pricingKey);
    } catch (e) {
      debugPrint('Error resetting pricing: $e');
    }
  }
}
