import '../constants/app_constants.dart';

/// Accurate physical and digital unit conversions for printing.
class UnitConverter {
  /// Converts millimeters to typographic points (1 pt = 1/72 inch).
  static double mmToPoints(double mm) {
    return mm * AppConstants.ptPerMm;
  }

  /// Converts typographic points to millimeters.
  static double pointsToMm(double pt) {
    return pt / AppConstants.ptPerMm;
  }

  /// Converts millimeters to pixels at the given DPI (Dots Per Inch).
  static int mmToPixels(double mm, int dpi) {
    return ((mm / AppConstants.mmPerInch) * dpi).round();
  }

  /// Converts pixels to millimeters at the given DPI.
  static double pixelsToMm(int px, int dpi) {
    return (px / dpi) * AppConstants.mmPerInch;
  }

  /// Converts inches to millimeters.
  static double inchesToMm(double inches) {
    return inches * AppConstants.mmPerInch;
  }

  /// Converts millimeters to inches.
  static double mmToInches(double mm) {
    return mm / AppConstants.mmPerInch;
  }

  /// Formats a physical dimension in millimeters to a user-friendly string (e.g. "35 × 45 mm").
  static String formatDimensionsMm(double widthMm, double heightMm) {
    return '${widthMm.toStringAsFixed(widthMm.truncateToDouble() == widthMm ? 0 : 1)} × ${heightMm.toStringAsFixed(heightMm.truncateToDouble() == heightMm ? 0 : 1)} mm';
  }

  /// Formats physical dimensions in inches (e.g. "4 × 6 in").
  static String formatDimensionsInches(double widthMm, double heightMm) {
    final wIn = mmToInches(widthMm);
    final hIn = mmToInches(heightMm);
    return '${wIn.toStringAsFixed(1)} × ${hIn.toStringAsFixed(1)} in';
  }

  /// Calculates aspect ratio (width / height).
  static double aspectRatio(double widthMm, double heightMm) {
    if (heightMm == 0) return 1.0;
    return widthMm / heightMm;
  }
}
