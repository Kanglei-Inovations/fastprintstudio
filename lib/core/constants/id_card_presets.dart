import '../models/id_card_preset.dart';

class StandardIDCardPresets {
  /// Standard Aadhaar Card / ISO ID-1: 85.6 × 54.0 mm
  static const IDCardPreset aadhaar = IDCardPreset(
    id: 'aadhaar_standard',
    name: 'Aadhaar Card (85.6 × 54 mm)',
    widthMm: 85.6,
    heightMm: 54.0,
    defaultGapMm: 5.0,
    defaultMarginMm: 4.0,
    description: 'Standard UIDAI Aadhaar Card physical print dimensions (PVC / Laminated)',
  );

  /// Standard PAN Card: 85.6 × 54.0 mm
  static const IDCardPreset panCard = IDCardPreset(
    id: 'pan_card_standard',
    name: 'PAN Card (85.6 × 54 mm)',
    widthMm: 85.6,
    heightMm: 54.0,
    defaultGapMm: 5.0,
    defaultMarginMm: 4.0,
    description: 'Standard NSDL / UTI PAN card physical format',
  );

  /// Voter ID Card (EPIC): 86.0 × 54.0 mm
  static const IDCardPreset voterId = IDCardPreset(
    id: 'voter_id_standard',
    name: 'Voter ID / EPIC (86 × 54 mm)',
    widthMm: 86.0,
    heightMm: 54.0,
    defaultGapMm: 5.0,
    defaultMarginMm: 4.0,
    description: 'Election Commission of India EPIC voter card format',
  );

  /// Driving Licence / Smart Card: 85.6 × 54.0 mm
  static const IDCardPreset drivingLicense = IDCardPreset(
    id: 'driving_license',
    name: 'Driving Licence (85.6 × 54 mm)',
    widthMm: 85.6,
    heightMm: 54.0,
    defaultGapMm: 5.0,
    defaultMarginMm: 4.0,
    description: 'State Transport Driving Licence format',
  );

  static const List<IDCardPreset> all = [
    aadhaar,
    panCard,
    voterId,
    drivingLicense,
  ];

  static IDCardPreset getById(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => aadhaar,
    );
  }
}
