enum IdCardWorkflowType {
  photoPaperLamination('Lamination Card', 50.0),
  epsonL805('Epson L805 Card', 100.0),
  dragonSheet('Dragon Sheet (200×300mm)', 100.0);

  final String label;
  final double defaultPricePerCard;

  const IdCardWorkflowType(this.label, this.defaultPricePerCard);

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
