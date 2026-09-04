import 'paper_preset.dart';
import 'layout_item.dart';
import '../utils/unit_converter.dart';

class PrintLayout {
  final PaperPreset paperPreset;
  final PaperOrientation orientation;
  final int dpi;
  final double marginMm;
  final double spacingMm;
  final List<LayoutItem> items;
  final String serviceType;
  final int maxCapacity;
  final String? warningMessage;

  const PrintLayout({
    required this.paperPreset,
    this.orientation = PaperOrientation.portrait,
    this.dpi = 300,
    this.marginMm = 4.0,
    this.spacingMm = 3.0,
    this.items = const [],
    this.serviceType = '',
    this.maxCapacity = 0,
    this.warningMessage,
  });

  double get paperWidthMm => paperPreset.effectiveWidthMm(orientation);
  double get paperHeightMm => paperPreset.effectiveHeightMm(orientation);

  double get paperWidthPt => UnitConverter.mmToPoints(paperWidthMm);
  double get paperHeightPt => UnitConverter.mmToPoints(paperHeightMm);

  int get paperWidthPx => UnitConverter.mmToPixels(paperWidthMm, dpi);
  int get paperHeightPx => UnitConverter.mmToPixels(paperHeightMm, dpi);

  int get itemCount => items.length;

  /// Checks if all requested items fit inside the paper bounds without warnings
  bool get allItemsFit {
    if (warningMessage != null && warningMessage!.isNotEmpty) return false;
    for (final item in items) {
      if (item.xMm < 0 ||
          item.yMm < 0 ||
          item.rightMm > paperWidthMm + 0.5 ||
          item.bottomMm > paperHeightMm + 0.5) {
        return false;
      }
    }
    return true;
  }

  PrintLayout copyWith({
    PaperPreset? paperPreset,
    PaperOrientation? orientation,
    int? dpi,
    double? marginMm,
    double? spacingMm,
    List<LayoutItem>? items,
    String? serviceType,
    int? maxCapacity,
    String? warningMessage,
  }) {
    return PrintLayout(
      paperPreset: paperPreset ?? this.paperPreset,
      orientation: orientation ?? this.orientation,
      dpi: dpi ?? this.dpi,
      marginMm: marginMm ?? this.marginMm,
      spacingMm: spacingMm ?? this.spacingMm,
      items: items ?? this.items,
      serviceType: serviceType ?? this.serviceType,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      warningMessage: warningMessage,
    );
  }
}
