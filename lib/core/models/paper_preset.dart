import '../utils/unit_converter.dart';

enum PaperOrientation {
  portrait,
  landscape;

  String get displayName {
    switch (this) {
      case PaperOrientation.portrait:
        return 'Portrait';
      case PaperOrientation.landscape:
        return 'Landscape';
    }
  }
}

class PaperPreset {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;
  final bool isCustom;
  final String description;

  const PaperPreset({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    this.isCustom = false,
    this.description = '',
  });

  /// Get effective width in mm given orientation
  double effectiveWidthMm(PaperOrientation orientation) {
    if (orientation == PaperOrientation.portrait) {
      return widthMm < heightMm ? widthMm : heightMm;
    } else {
      return widthMm > heightMm ? widthMm : heightMm;
    }
  }

  /// Get effective height in mm given orientation
  double effectiveHeightMm(PaperOrientation orientation) {
    if (orientation == PaperOrientation.portrait) {
      return widthMm < heightMm ? heightMm : widthMm;
    } else {
      return widthMm > heightMm ? heightMm : widthMm;
    }
  }

  /// Dimensions in points (pt) for PDF rendering
  double widthPt(PaperOrientation orientation) => UnitConverter.mmToPoints(effectiveWidthMm(orientation));
  double heightPt(PaperOrientation orientation) => UnitConverter.mmToPoints(effectiveHeightMm(orientation));

  /// Dimensions in pixels at a specific DPI
  int widthPx(PaperOrientation orientation, int dpi) => UnitConverter.mmToPixels(effectiveWidthMm(orientation), dpi);
  int heightPx(PaperOrientation orientation, int dpi) => UnitConverter.mmToPixels(effectiveHeightMm(orientation), dpi);

  String get formattedDimensions => UnitConverter.formatDimensionsMm(widthMm, heightMm);
  String get formattedInches => UnitConverter.formatDimensionsInches(widthMm, heightMm);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'isCustom': isCustom,
        'description': description,
      };

  factory PaperPreset.fromJson(Map<String, dynamic> json) => PaperPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        widthMm: (json['widthMm'] as num).toDouble(),
        heightMm: (json['heightMm'] as num).toDouble(),
        isCustom: json['isCustom'] as bool? ?? false,
        description: json['description'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          widthMm == other.widthMm &&
          heightMm == other.heightMm;

  @override
  int get hashCode => id.hashCode ^ widthMm.hashCode ^ heightMm.hashCode;
}
