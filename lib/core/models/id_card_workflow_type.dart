enum IdCardWorkflowType {
  photoPaperLamination('Lamination Card', 50.0),
  epsonL805('Epson L805 Card', 100.0),
  dragonSheet('Dragon Sheet (200×300mm)', 100.0),
  xerox('Xerox', 10.0);

  final String label;
  final double defaultPricePerCard;

  const IdCardWorkflowType(this.label, this.defaultPricePerCard);

  /// User-facing description/subtitle for UI cards
  String get description {
    switch (this) {
      case IdCardWorkflowType.photoPaperLamination:
        return 'Fold + Laminate';
      case IdCardWorkflowType.xerox:
        return 'Front + Back on Paper';
      case IdCardWorkflowType.epsonL805:
        return 'A4 PVC Tray';
      case IdCardWorkflowType.dragonSheet:
        return '200 × 300 mm';
    }
  }

  /// Front card rotation angle in degrees
  int get frontRotationDegrees => 0;

  /// Back card rotation angle in degrees:
  /// - Lamination Card folds over: 180°
  /// - Xerox paper copy: 0° (normal orientation, NOT rotated)
  /// - Epson L805: 0°
  /// - Dragon Sheet: 0°
  int get backRotationDegrees {
    switch (this) {
      case IdCardWorkflowType.photoPaperLamination:
        return 180;
      case IdCardWorkflowType.xerox:
        return 0;
      case IdCardWorkflowType.epsonL805:
        return 0;
      case IdCardWorkflowType.dragonSheet:
        return 0;
    }
  }

  /// Default spacing between front & back cards in mm
  double get defaultSpacingMm {
    switch (this) {
      case IdCardWorkflowType.photoPaperLamination:
        return 0.5;
      case IdCardWorkflowType.xerox:
        return 6.0;
      case IdCardWorkflowType.epsonL805:
        return 0.0;
      case IdCardWorkflowType.dragonSheet:
        return 0.5;
    }
  }

  /// Default margin around paper sheet in mm
  double get defaultMarginMm {
    switch (this) {
      case IdCardWorkflowType.photoPaperLamination:
        return 4.0;
      case IdCardWorkflowType.xerox:
        return 5.0;
      case IdCardWorkflowType.epsonL805:
        return 0.0;
      case IdCardWorkflowType.dragonSheet:
        return 2.0;
    }
  }

  /// Backward-compatibility alias for previous epsonL805Pvc naming
  static const IdCardWorkflowType epsonL805Pvc = IdCardWorkflowType.epsonL805;
}

enum PvcOutputMode {
  l805Tray('Epson L805 Tray (Card by Card)'),
  dragonSheetDuplex('Dragon Sheet 200×300mm (5 Cards Front + Back)'),
  dragonSheetSingle('Dragon Sheet 200×300mm (10 Single-Side Cards)');

  final String label;
  const PvcOutputMode(this.label);
}
