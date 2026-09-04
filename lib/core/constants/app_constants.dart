class AppConstants {
  static const String appName = 'FastPrint Studio';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Automated Printing Workflow for Xerox & Photo Shops';

  // Standard DPIs
  static const int defaultPrintDpi = 300;
  static const int draftPrintDpi = 150;
  static const int highQualityPrintDpi = 600;

  // Millimeter conversions
  static const double mmPerInch = 25.4;
  static const double ptPerInch = 72.0;
  static const double ptPerMm = ptPerInch / mmPerInch; // ~2.83464567

  // Supported extensions
  static const List<String> supportedImageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
  static const List<String> supportedPdfExtensions = ['pdf'];
  static const List<String> allSupportedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp'];

  // Temporary storage folder name
  static const String tempFolderName = 'fastprint_temp';
}
