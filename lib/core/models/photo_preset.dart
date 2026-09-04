import '../utils/unit_converter.dart';
import 'border_config.dart';

class PhotoPreset {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;
  final String description;
  final BorderConfig defaultBorder;
  final bool isCustom;

  const PhotoPreset({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    this.description = '',
    this.defaultBorder = const BorderConfig(),
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
        'description': description,
        'defaultBorder': defaultBorder.toJson(),
        'isCustom': isCustom,
      };

  factory PhotoPreset.fromJson(Map<String, dynamic> json) => PhotoPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        widthMm: (json['widthMm'] as num).toDouble(),
        heightMm: (json['heightMm'] as num).toDouble(),
        description: json['description'] as String? ?? '',
        defaultBorder: json['defaultBorder'] != null
            ? BorderConfig.fromJson(json['defaultBorder'] as Map<String, dynamic>)
            : const BorderConfig(),
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          widthMm == other.widthMm &&
          heightMm == other.heightMm;

  @override
  int get hashCode => id.hashCode ^ widthMm.hashCode ^ heightMm.hashCode;
}
