import '../models/photo_preset.dart';

class StandardPhotoPresets {
  /// Standard Indian Passport Size: 30 × 40 mm
  static const PhotoPreset passport = PhotoPreset(
    id: 'passport_30_40',
    name: 'Passport (30 × 40 mm)',
    widthMm: 30.0,
    heightMm: 40.0,
    description: 'Standard Indian Passport, ID & Official photos (30 × 40 mm)',
  );

  /// Stamp Size Photo: 25 × 30 mm
  static const PhotoPreset stamp = PhotoPreset(
    id: 'stamp_25_30',
    name: 'Stamp Size (25 × 30 mm)',
    widthMm: 25.0,
    heightMm: 30.0,
    description: 'Standard stamp size for college/school admission forms & applications',
  );

  /// Square / US Visa Photo: 50.8 × 50.8 mm (2 × 2 inches)
  static const PhotoPreset usVisa = PhotoPreset(
    id: 'us_visa_2x2',
    name: 'US Visa / Square (2 × 2 in / 51 × 51 mm)',
    widthMm: 50.8,
    heightMm: 50.8,
    description: 'US Visa, Schengen & International 2x2 inch square photos',
  );

  /// 4R Photo Print: 101.6 × 152.4 mm (4 × 6 inches)
  static const PhotoPreset fourR = PhotoPreset(
    id: 'photo_4r',
    name: '4R Photo (4 × 6 in / 102 × 152 mm)',
    widthMm: 101.6,
    heightMm: 152.4,
    description: 'Standard 4×6 photo studio print / postcard',
  );

  /// A4 Photo Print: 210.0 × 297.0 mm (Full Page Enlargement)
  static const PhotoPreset a4 = PhotoPreset(
    id: 'photo_a4',
    name: 'A4 Photo (8.3 × 11.7 in / 210 × 297 mm)',
    widthMm: 210.0,
    heightMm: 297.0,
    description: 'Full page A4 portrait / landscape photo print',
  );

  static const List<PhotoPreset> all = [
    passport,
    stamp,
    fourR,
    a4,
    usVisa,
  ];

  static PhotoPreset getById(String id) {
    if (id == 'photo_4r' || id == '4r') return fourR;
    if (id == 'photo_a4' || id == 'a4') return a4;
    return all.firstWhere(
      (p) => p.id == id || (p.id.contains('passport') && id.contains('passport')),
      orElse: () => passport,
    );
  }
}
