import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../constants/photo_presets.dart';
import 'border_config.dart';
import 'crop_rect_data.dart';
import 'enhancement_config.dart';
import 'photo_preset.dart';

class PhotoGroup {
  final String id;
  final String name;
  final PhotoPreset preset;
  final Uint8List? rawImageBytes;
  final CropRectData cropData;
  final EnhancementConfig enhancement;
  final BorderConfig borderConfig;
  final int copiesCount;
  final Uint8List? processedBytes;

  PhotoGroup({
    String? id,
    required this.name,
    required this.preset,
    this.rawImageBytes,
    CropRectData? cropData,
    this.enhancement = const EnhancementConfig(),
    this.borderConfig = const BorderConfig(outerBorderMm: 2.0, innerBorderMm: 0.15),
    this.copiesCount = 4,
    this.processedBytes,
  })  : id = id ?? const Uuid().v4(),
        cropData = cropData ?? CropRectData.centeredWithAspectRatio(preset.aspectRatio);

  /// Default Passport photo group (30 × 40 mm)
  factory PhotoGroup.passport({Uint8List? rawImageBytes, int copies = 8}) {
    return PhotoGroup(
      name: 'Passport Photo',
      preset: StandardPhotoPresets.passport,
      rawImageBytes: rawImageBytes,
      copiesCount: copies,
      borderConfig: const BorderConfig(outerBorderMm: 2.0, innerBorderMm: 0.15),
    );
  }

  /// Default Stamp photo group (25 × 30 mm)
  factory PhotoGroup.stamp({Uint8List? rawImageBytes, int copies = 4}) {
    return PhotoGroup(
      name: 'Stamp Photo',
      preset: StandardPhotoPresets.stamp,
      rawImageBytes: rawImageBytes,
      copiesCount: copies,
      borderConfig: const BorderConfig(outerBorderMm: 1.5, innerBorderMm: 0.15),
    );
  }

  double get widthMm => preset.widthMm;
  double get heightMm => preset.heightMm;
  double get aspectRatio => preset.aspectRatio;

  double get totalItemWidthMm => widthMm + borderConfig.totalExtraWidthMm;
  double get totalItemHeightMm => heightMm + borderConfig.totalExtraHeightMm;

  PhotoGroup copyWith({
    String? name,
    PhotoPreset? preset,
    Uint8List? rawImageBytes,
    CropRectData? cropData,
    EnhancementConfig? enhancement,
    BorderConfig? borderConfig,
    int? copiesCount,
    Uint8List? processedBytes,
    bool clearProcessedBytes = false,
  }) {
    return PhotoGroup(
      id: id,
      name: name ?? this.name,
      preset: preset ?? this.preset,
      rawImageBytes: rawImageBytes ?? this.rawImageBytes,
      cropData: cropData ?? this.cropData,
      enhancement: enhancement ?? this.enhancement,
      borderConfig: borderConfig ?? this.borderConfig,
      copiesCount: copiesCount ?? this.copiesCount,
      processedBytes: clearProcessedBytes ? null : (processedBytes ?? this.processedBytes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'presetId': preset.id,
        'copiesCount': copiesCount,
        'cropData': cropData.toJson(),
        'enhancement': enhancement.toJson(),
        'borderConfig': borderConfig.toJson(),
      };
}
