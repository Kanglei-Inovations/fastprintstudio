/// Configuration and calibration data for Epson L805 PVC Card Tray on A4 carrier paper.
class L805Calibration {
  /// Physical card width in millimeters (Standard CR80 ID Card = 85.6 mm)
  final double cardWidthMm;

  /// Physical card height in millimeters (Standard CR80 ID Card = 54.0 mm)
  final double cardHeightMm;

  /// Slot 1 X coordinate in millimeters from left edge of A4 (Centered on 210mm: (210 - 85.6)/2 = 62.2 mm)
  final double slot1XMm;

  /// Slot 1 Y coordinate in millimeters from top edge of A4 (Standard top margin = 42.0 mm)
  final double slot1YMm;

  /// Slot 2 X coordinate in millimeters from left edge of A4 (Centered on 210mm: 62.2 mm)
  final double slot2XMm;

  /// Slot 2 Y coordinate in millimeters from top edge of A4 (42 + 54 + 12mm gap = 108.0 mm)
  final double slot2YMm;

  /// Global horizontal offset in millimeters applied to both slots
  final double globalOffsetX;

  /// Global vertical offset in millimeters applied to both slots
  final double globalOffsetY;

  const L805Calibration({
    this.cardWidthMm = 85.6,
    this.cardHeightMm = 54.0,
    this.slot1XMm = 62.2,
    this.slot1YMm = 42.0,
    this.slot2XMm = 62.2,
    this.slot2YMm = 108.0,
    this.globalOffsetX = 0.0,
    this.globalOffsetY = 0.0,
  });

  /// Factory standard calibration settings for Epson L805 PVC card tray
  static const L805Calibration factoryDefault = L805Calibration();

  /// Effective X position for Slot 1 including global offset
  double get effectiveSlot1X => slot1XMm + globalOffsetX;

  /// Effective Y position for Slot 1 including global offset
  double get effectiveSlot1Y => slot1YMm + globalOffsetY;

  /// Effective X position for Slot 2 including global offset
  double get effectiveSlot2X => slot2XMm + globalOffsetX;

  /// Effective Y position for Slot 2 including global offset
  double get effectiveSlot2Y => slot2YMm + globalOffsetY;

  Map<String, dynamic> toJson() => {
        'cardWidthMm': cardWidthMm,
        'cardHeightMm': cardHeightMm,
        'slot1XMm': slot1XMm,
        'slot1YMm': slot1YMm,
        'slot2XMm': slot2XMm,
        'slot2YMm': slot2YMm,
        'globalOffsetX': globalOffsetX,
        'globalOffsetY': globalOffsetY,
      };

  factory L805Calibration.fromJson(Map<String, dynamic> json) {
    return L805Calibration(
      cardWidthMm: (json['cardWidthMm'] as num?)?.toDouble() ?? 85.6,
      cardHeightMm: (json['cardHeightMm'] as num?)?.toDouble() ?? 54.0,
      slot1XMm: (json['slot1XMm'] as num?)?.toDouble() ?? 62.2,
      slot1YMm: (json['slot1YMm'] as num?)?.toDouble() ?? 42.0,
      slot2XMm: (json['slot2XMm'] as num?)?.toDouble() ?? 62.2,
      slot2YMm: (json['slot2YMm'] as num?)?.toDouble() ?? 108.0,
      globalOffsetX: (json['globalOffsetX'] as num?)?.toDouble() ?? 0.0,
      globalOffsetY: (json['globalOffsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  L805Calibration copyWith({
    double? cardWidthMm,
    double? cardHeightMm,
    double? slot1XMm,
    double? slot1YMm,
    double? slot2XMm,
    double? slot2YMm,
    double? globalOffsetX,
    double? globalOffsetY,
  }) {
    return L805Calibration(
      cardWidthMm: cardWidthMm ?? this.cardWidthMm,
      cardHeightMm: cardHeightMm ?? this.cardHeightMm,
      slot1XMm: slot1XMm ?? this.slot1XMm,
      slot1YMm: slot1YMm ?? this.slot1YMm,
      slot2XMm: slot2XMm ?? this.slot2XMm,
      slot2YMm: slot2YMm ?? this.slot2YMm,
      globalOffsetX: globalOffsetX ?? this.globalOffsetX,
      globalOffsetY: globalOffsetY ?? this.globalOffsetY,
    );
  }
}
