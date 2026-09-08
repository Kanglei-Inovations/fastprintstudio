import 'package:flutter/foundation.dart';
import 'crop_rect_data.dart';
import 'enhancement_config.dart';

/// Represents a single person / document entry in multi-card ID printing
class IdCardEntry {
  final String id;
  final String name;
  final Uint8List? rawBytes;
  final bool isPdf;
  final List<Uint8List> renderedPages;
  final int selectedPageIndex;
  final CropRectData frontCrop;
  final CropRectData? backCrop;
  final EnhancementConfig frontEnhancement;
  final EnhancementConfig backEnhancement;
  final bool hasBothSides;
  final bool swapFrontBack;
  final Uint8List? frontBytes;
  final Uint8List? backBytes;
  final Uint8List? backRawBytes;
  final bool backIsPdf;
  final List<Uint8List> backRenderedPages;
  final int backSelectedPageIndex;

  const IdCardEntry({
    required this.id,
    required this.name,
    this.rawBytes,
    this.isPdf = false,
    this.renderedPages = const [],
    this.selectedPageIndex = 0,
    this.frontCrop = const CropRectData(),
    this.backCrop,
    this.frontEnhancement = const EnhancementConfig(),
    this.backEnhancement = const EnhancementConfig(),
    this.hasBothSides = true,
    this.swapFrontBack = false,
    this.frontBytes,
    this.backBytes,
    this.backRawBytes,
    this.backIsPdf = false,
    this.backRenderedPages = const [],
    this.backSelectedPageIndex = 0,
  });

  Uint8List? get activePageImageBytes {
    if (renderedPages.isNotEmpty && selectedPageIndex < renderedPages.length) {
      return renderedPages[selectedPageIndex];
    }
    return rawBytes;
  }

  Uint8List? get frontSourceImageBytes => activePageImageBytes;

  Uint8List? get backSourceImageBytes {
    if (backRawBytes != null) {
      if (backRenderedPages.isNotEmpty && backSelectedPageIndex < backRenderedPages.length) {
        return backRenderedPages[backSelectedPageIndex];
      }
      return backRawBytes;
    }
    if (renderedPages.length >= 2) {
      final idx = (backSelectedPageIndex < renderedPages.length && backSelectedPageIndex != selectedPageIndex)
          ? backSelectedPageIndex
          : (selectedPageIndex == 0 ? 1 : 0);
      return renderedPages[idx];
    }
    return activePageImageBytes;
  }

  IdCardEntry copyWith({
    String? id,
    String? name,
    Uint8List? rawBytes,
    bool? isPdf,
    List<Uint8List>? renderedPages,
    int? selectedPageIndex,
    CropRectData? frontCrop,
    CropRectData? backCrop,
    bool clearBackCrop = false,
    EnhancementConfig? frontEnhancement,
    EnhancementConfig? backEnhancement,
    bool? hasBothSides,
    bool? swapFrontBack,
    Uint8List? frontBytes,
    Uint8List? backBytes,
    bool clearBackBytes = false,
    Uint8List? backRawBytes,
    bool clearBackRawBytes = false,
    bool? backIsPdf,
    List<Uint8List>? backRenderedPages,
    int? backSelectedPageIndex,
  }) {
    return IdCardEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      rawBytes: rawBytes ?? this.rawBytes,
      isPdf: isPdf ?? this.isPdf,
      renderedPages: renderedPages ?? this.renderedPages,
      selectedPageIndex: selectedPageIndex ?? this.selectedPageIndex,
      frontCrop: frontCrop ?? this.frontCrop,
      backCrop: clearBackCrop ? null : (backCrop ?? this.backCrop),
      frontEnhancement: frontEnhancement ?? this.frontEnhancement,
      backEnhancement: backEnhancement ?? this.backEnhancement,
      hasBothSides: hasBothSides ?? this.hasBothSides,
      swapFrontBack: swapFrontBack ?? this.swapFrontBack,
      frontBytes: frontBytes ?? this.frontBytes,
      backBytes: clearBackBytes ? null : (backBytes ?? this.backBytes),
      backRawBytes: clearBackRawBytes ? null : (backRawBytes ?? this.backRawBytes),
      backIsPdf: backIsPdf ?? this.backIsPdf,
      backRenderedPages: backRenderedPages ?? this.backRenderedPages,
      backSelectedPageIndex: backSelectedPageIndex ?? this.backSelectedPageIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPdf': isPdf,
      'selectedPageIndex': selectedPageIndex,
      'frontCrop': frontCrop.toJson(),
      'backCrop': backCrop?.toJson(),
      'frontEnhancement': frontEnhancement.toJson(),
      'backEnhancement': backEnhancement.toJson(),
      'hasBothSides': hasBothSides,
      'swapFrontBack': swapFrontBack,
    };
  }

  factory IdCardEntry.fromJson(Map<String, dynamic> json, {Uint8List? rawBytes, List<Uint8List>? renderedPages}) {
    return IdCardEntry(
      id: json['id'] as String? ?? 'id_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'ID Card',
      rawBytes: rawBytes,
      isPdf: json['isPdf'] as bool? ?? false,
      renderedPages: renderedPages ?? const [],
      selectedPageIndex: json['selectedPageIndex'] as int? ?? 0,
      frontCrop: json['frontCrop'] != null
          ? CropRectData.fromJson(Map<String, dynamic>.from(json['frontCrop'] as Map))
          : const CropRectData(),
      backCrop: json['backCrop'] != null
          ? CropRectData.fromJson(Map<String, dynamic>.from(json['backCrop'] as Map))
          : null,
      frontEnhancement: json['frontEnhancement'] != null
          ? EnhancementConfig.fromJson(Map<String, dynamic>.from(json['frontEnhancement'] as Map))
          : const EnhancementConfig(),
      backEnhancement: json['backEnhancement'] != null
          ? EnhancementConfig.fromJson(Map<String, dynamic>.from(json['backEnhancement'] as Map))
          : const EnhancementConfig(),
      hasBothSides: json['hasBothSides'] as bool? ?? true,
      swapFrontBack: json['swapFrontBack'] as bool? ?? false,
    );
  }
}
