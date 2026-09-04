import '../utils/unit_converter.dart';

class BorderConfig {
  final bool enabled;
  final double outerBorderMm; // Outer White Margin in mm (default 2.00mm)
  final double innerBorderMm; // Cutting Stroke in mm applied after white margin (default 0.15mm)
  final int outerColorValue; // 0xFFFFFFFF (White)
  final int innerColorValue; // 0xFF000000 (Black Cutting Stroke)

  const BorderConfig({
    this.enabled = true,
    this.outerBorderMm = 2.0, // 2.00mm clean white outer margin by default
    this.innerBorderMm = 0.15, // 0.15mm thin cutting stroke line after white margin
    this.outerColorValue = 0xFFFFFFFF,
    this.innerColorValue = 0xFF000000,
  });

  /// Outer White Margin in mm
  double get outerWhiteMarginMm => outerBorderMm;

  /// Cutting Stroke in mm (after white margin)
  double get strokeMm => innerBorderMm;

  /// Total extra border added to each side in mm
  double get totalBorderPerSideMm => enabled ? (outerBorderMm + innerBorderMm) : 0.0;

  /// Total extra width added to item in mm
  double get totalExtraWidthMm => totalBorderPerSideMm * 2;

  /// Total extra height added to item in mm
  double get totalExtraHeightMm => totalBorderPerSideMm * 2;

  /// Outer border (white margin) in pixels at given DPI
  int outerBorderPx(int dpi) => enabled ? UnitConverter.mmToPixels(outerBorderMm, dpi) : 0;

  /// Cutting Stroke in pixels at given DPI
  int innerBorderPx(int dpi) => enabled ? UnitConverter.mmToPixels(innerBorderMm, dpi) : 0;
  int strokePx(int dpi) => innerBorderPx(dpi);

  BorderConfig copyWith({
    bool? enabled,
    double? outerBorderMm,
    double? innerBorderMm,
    double? strokeMm,
    double? outerWhiteMarginMm,
    int? outerColorValue,
    int? innerColorValue,
  }) {
    return BorderConfig(
      enabled: enabled ?? this.enabled,
      outerBorderMm: outerWhiteMarginMm ?? outerBorderMm ?? this.outerBorderMm,
      innerBorderMm: strokeMm ?? innerBorderMm ?? this.innerBorderMm,
      outerColorValue: outerColorValue ?? this.outerColorValue,
      innerColorValue: innerColorValue ?? this.innerColorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'outerBorderMm': outerBorderMm,
        'innerBorderMm': innerBorderMm,
        'outerColorValue': outerColorValue,
        'innerColorValue': innerColorValue,
      };

  factory BorderConfig.fromJson(Map<String, dynamic> json) => BorderConfig(
        enabled: json['enabled'] as bool? ?? true,
        outerBorderMm: (json['outerBorderMm'] as num?)?.toDouble() ?? 2.0,
        innerBorderMm: (json['innerBorderMm'] as num?)?.toDouble() ?? (json['strokeMm'] as num?)?.toDouble() ?? 0.15,
        outerColorValue: json['outerColorValue'] as int? ?? 0xFFFFFFFF,
        innerColorValue: json['innerColorValue'] as int? ?? 0xFF000000,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          outerBorderMm == other.outerBorderMm &&
          innerBorderMm == other.innerBorderMm &&
          outerColorValue == other.outerColorValue &&
          innerColorValue == other.innerColorValue;

  @override
  int get hashCode =>
      enabled.hashCode ^
      outerBorderMm.hashCode ^
      innerBorderMm.hashCode ^
      outerColorValue.hashCode ^
      innerColorValue.hashCode;
}
