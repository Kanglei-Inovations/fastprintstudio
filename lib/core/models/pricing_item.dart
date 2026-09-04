class PricingItem {
  final String id;
  final String name;
  final String category; // 'Card Printing', 'Photo Studio', 'Document Xerox', 'Custom'
  final double price; // Selling price in INR (₹)
  final double cost; // Estimated material/ink/overhead cost in INR (₹)
  final String unit; // 'per card', 'per 4R sheet', 'per page', 'per print'
  final String description;
  final bool isCustom;

  const PricingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.cost = 0.0,
    required this.unit,
    this.description = '',
    this.isCustom = false,
  });

  /// Net profit earned per unit
  double get profit => price - cost;

  /// Profit margin percentage (e.g. 75.0%)
  double get profitMarginPct => price > 0 ? ((price - cost) / price) * 100 : 0.0;

  PricingItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    double? cost,
    String? unit,
    String? description,
    bool? isCustom,
  }) {
    return PricingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'cost': cost,
        'unit': unit,
        'description': description,
        'isCustom': isCustom,
      };

  factory PricingItem.fromJson(Map<String, dynamic> json) => PricingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'General',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'per print',
        description: json['description'] as String? ?? '',
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          price == other.price &&
          cost == other.cost &&
          unit == other.unit &&
          isCustom == other.isCustom;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      category.hashCode ^
      price.hashCode ^
      cost.hashCode ^
      unit.hashCode ^
      isCustom.hashCode;
}
