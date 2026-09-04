class EnhancementConfig {
  final double brightness; // -1.0 to 1.0 (default 0.0)
  final double contrast; // 0.0 to 2.0 (default 1.0)
  final double saturation; // 0.0 to 2.0 (default 1.0)
  final double sharpness; // 0.0 to 1.0 (default 0.0)
  final double smoothSkin; // 0.0 to 1.0 (default 0.0)
  final int rotationDegrees; // 0, 90, 180, 270

  const EnhancementConfig({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.sharpness = 0.0,
    this.smoothSkin = 0.0,
    this.rotationDegrees = 0,
  });

  bool get isDefault =>
      brightness == 0.0 &&
      contrast == 1.0 &&
      saturation == 1.0 &&
      sharpness == 0.0 &&
      smoothSkin == 0.0 &&
      rotationDegrees == 0;

  EnhancementConfig copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
    double? smoothSkin,
    int? rotationDegrees,
  }) {
    return EnhancementConfig(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpness: sharpness ?? this.sharpness,
      smoothSkin: smoothSkin ?? this.smoothSkin,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }

  Map<String, dynamic> toJson() => {
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'sharpness': sharpness,
        'smoothSkin': smoothSkin,
        'rotationDegrees': rotationDegrees,
      };

  factory EnhancementConfig.fromJson(Map<String, dynamic> json) => EnhancementConfig(
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
        sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0.0,
        smoothSkin: (json['smoothSkin'] as num?)?.toDouble() ?? 0.0,
        rotationDegrees: json['rotationDegrees'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancementConfig &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          contrast == other.contrast &&
          saturation == other.saturation &&
          sharpness == other.sharpness &&
          smoothSkin == other.smoothSkin &&
          rotationDegrees == other.rotationDegrees;

  @override
  int get hashCode =>
      brightness.hashCode ^
      contrast.hashCode ^
      saturation.hashCode ^
      sharpness.hashCode ^
      smoothSkin.hashCode ^
      rotationDegrees.hashCode;
}
