import 'dart:typed_data';
import '../utils/unit_converter.dart';
import 'border_config.dart';

class LayoutItem {
  final String id;
  final String label;
  final String? groupId;
  final String? groupName;
  final Uint8List imageBytes;
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;
  final int rotationDegrees;
  final bool isFront;
  final bool isBack;
  final BorderConfig? borderConfig;

  const LayoutItem({
    required this.id,
    required this.label,
    this.groupId,
    this.groupName,
    required this.imageBytes,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.rotationDegrees = 0,
    this.isFront = false,
    this.isBack = false,
    this.borderConfig,
  });

  /// Bounding box right in mm
  double get rightMm => xMm + widthMm;

  /// Bounding box bottom in mm
  double get bottomMm => yMm + heightMm;

  /// Point coordinates for PDF layout
  double get xPt => UnitConverter.mmToPoints(xMm);
  double get yPt => UnitConverter.mmToPoints(yMm);
  double get widthPt => UnitConverter.mmToPoints(widthMm);
  double get heightPt => UnitConverter.mmToPoints(heightMm);

  /// Pixel coordinates for raster rendering at DPI
  int xPx(int dpi) => UnitConverter.mmToPixels(xMm, dpi);
  int yPx(int dpi) => UnitConverter.mmToPixels(yMm, dpi);
  int widthPx(int dpi) => UnitConverter.mmToPixels(widthMm, dpi);
  int heightPx(int dpi) => UnitConverter.mmToPixels(heightMm, dpi);

  LayoutItem copyWith({
    String? id,
    String? label,
    String? groupId,
    String? groupName,
    Uint8List? imageBytes,
    double? xMm,
    double? yMm,
    double? widthMm,
    double? heightMm,
    int? rotationDegrees,
    bool? isFront,
    bool? isBack,
    BorderConfig? borderConfig,
  }) {
    return LayoutItem(
      id: id ?? this.id,
      label: label ?? this.label,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      imageBytes: imageBytes ?? this.imageBytes,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isFront: isFront ?? this.isFront,
      isBack: isBack ?? this.isBack,
      borderConfig: borderConfig ?? this.borderConfig,
    );
  }
}
