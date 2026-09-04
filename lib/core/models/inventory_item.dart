class InventoryItem {
  final String id;
  final String name;
  final String category; // 'Paper', 'Cards & Pouches', 'Ink / Toner', 'Binding'
  final double currentStock;
  final double minThreshold;
  final String unit; // 'sheets', 'cards', 'pouches', 'ml', 'units'
  final double costPerUnit;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minThreshold,
    required this.unit,
    required this.costPerUnit,
  });

  bool get isLowStock => currentStock <= minThreshold;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    double? minThreshold,
    String? unit,
    double? costPerUnit,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minThreshold: minThreshold ?? this.minThreshold,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'currentStock': currentStock,
        'minThreshold': minThreshold,
        'unit': unit,
        'costPerUnit': costPerUnit,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'General',
        currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
        minThreshold: (json['minThreshold'] as num?)?.toDouble() ?? 10.0,
        unit: json['unit'] as String? ?? 'units',
        costPerUnit: (json['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      );
}
