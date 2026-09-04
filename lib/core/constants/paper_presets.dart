import '../models/paper_preset.dart';

class StandardPaperPresets {
  /// 4R Photo Paper: 4 x 6 inches (101.6 x 152.4 mm) - The standard shop photo paper
  static const PaperPreset fourR = PaperPreset(
    id: '4r',
    name: '4R (4 × 6 in)',
    widthMm: 101.6,
    heightMm: 152.4,
    description: 'Standard 4×6 photo paper used in all Xerox & photo studios',
  );

  /// A4 Paper: 210 x 297 mm
  static const PaperPreset a4 = PaperPreset(
    id: 'a4',
    name: 'A4 (210 × 297 mm)',
    widthMm: 210.0,
    heightMm: 297.0,
    description: 'Standard office document & full-sheet photo paper',
  );

  /// A5 Paper: 148 x 210 mm
  static const PaperPreset a5 = PaperPreset(
    id: 'a5',
    name: 'A5 (148 × 210 mm)',
    widthMm: 148.0,
    heightMm: 210.0,
    description: 'Half A4 paper',
  );

  /// 3R Photo Paper: 3.5 x 5 inches (88.9 x 127 mm)
  static const PaperPreset threeR = PaperPreset(
    id: '3r',
    name: '3R (3.5 × 5 in)',
    widthMm: 88.9,
    heightMm: 127.0,
    description: 'Compact 3.5×5 photo paper',
  );

  /// 5R Photo Paper: 5 x 7 inches (127 x 177.8 mm)
  static const PaperPreset fiveR = PaperPreset(
    id: '5r',
    name: '5R (5 × 7 in)',
    widthMm: 127.0,
    heightMm: 177.8,
    description: 'Large 5×7 portrait photo paper',
  );

  /// 6R Photo Paper: 6 x 8 inches (152.4 x 203.2 mm)
  static const PaperPreset sixR = PaperPreset(
    id: '6r',
    name: '6R (6 × 8 in)',
    widthMm: 152.4,
    heightMm: 203.2,
    description: 'Studio 6×8 photo paper',
  );

  /// A3 Paper: 297 x 420 mm
  static const PaperPreset a3 = PaperPreset(
    id: 'a3',
    name: 'A3 (297 × 420 mm)',
    widthMm: 297.0,
    heightMm: 420.0,
    description: 'Large ledger / diagram document paper',
  );

  /// Letter Paper: 8.5 x 11 inches (215.9 x 279.4 mm)
  static const PaperPreset letter = PaperPreset(
    id: 'letter',
    name: 'Letter (8.5 × 11 in)',
    widthMm: 215.9,
    heightMm: 279.4,
    description: 'Standard North American document size',
  );

  /// Legal Paper: 8.5 x 14 inches (215.9 x 355.6 mm)
  static const PaperPreset legal = PaperPreset(
    id: 'legal',
    name: 'Legal (8.5 × 14 in)',
    widthMm: 215.9,
    heightMm: 355.6,
    description: 'Long legal document paper',
  );

  /// Dragon Sheet: 200 x 300 mm PVC / Dragon Sheet for 5 Duplex / 10 Single ID Cards
  static const PaperPreset dragonSheet200x300 = PaperPreset(
    id: 'dragon_sheet_200x300',
    name: 'Dragon Sheet (200 × 300 mm)',
    widthMm: 200.0,
    heightMm: 300.0,
    description: 'PVC / Dragon Sheet for 5 duplex or 10 single ID cards',
  );

  /// Epson L805 PVC Tray (Standard ID Card Size: 85.6 x 54 mm)
  static const PaperPreset l805PvcTray = PaperPreset(
    id: 'l805_pvc_tray',
    name: 'Epson L805 PVC Tray',
    widthMm: 85.6,
    heightMm: 54.0,
    description: 'Direct Epson L805 PVC card printing tray',
  );

  static const List<PaperPreset> all = [
    fourR,
    dragonSheet200x300,
    l805PvcTray,
    a4,
    a3,
    letter,
    legal,
    a5,
    threeR,
    fiveR,
    sixR,
  ];

  static PaperPreset getById(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => fourR,
    );
  }
}
