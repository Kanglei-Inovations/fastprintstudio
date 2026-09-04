import '../utils/unit_converter.dart';

class IDCardPreset {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;
  final double defaultGapMm;
  final double defaultMarginMm;
  final String description;
  final bool isCustom;

  const IDCardPreset({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    this.defaultGapMm = 5.0,
    this.defaultMarginMm = 4.0,
    this.description = '',
    this.isCustom = false,
  });

  double get aspectRatio => UnitConverter.aspectRatio(widthMm, heightMm);

  String get formattedDimensions => UnitConverter.formatDimensionsMm(widthMm, heightMm);
  String get formattedInches => UnitConverter.formatDimensionsInches(widthMm, heightMm);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'defaultGapMm': defaultGapMm,
        'defaultMarginMm': defaultMarginMm,
        'description': description,
        'isCustom': isCustom,
      };

  factory IDCardPreset.fromJson(Map<String, dynamic> json) => IDCardPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        widthMm: (json['widthMm'] as num).toDouble(),
        heightMm: (json['heightMm'] as num).toDouble(),
        defaultGapMm: (json['defaultGapMm'] as num?)?.toDouble() ?? 5.0,
        defaultMarginMm: (json['defaultMarginMm'] as num?)?.toDouble() ?? 4.0,
        description: json['description'] as String? ?? '',
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IDCardPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          widthMm == other.widthMm &&
          heightMm == other.heightMm;

  @override
  int get hashCode => id.hashCode ^ widthMm.hashCode ^ heightMm.hashCode;
}
