import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class FileUtils {
  /// Checks whether a file path has an image extension.
  static bool isImageFile(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    return AppConstants.supportedImageExtensions.contains(ext);
  }

  /// Checks whether a file path is a PDF.
  static bool isPdfFile(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    return AppConstants.supportedPdfExtensions.contains(ext);
  }

  /// Returns temporary directory for processing, creating it if needed.
  static Future<Directory?> getTempProcessingDir() async {
    if (kIsWeb) return null;
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory(p.join(base.path, AppConstants.tempFolderName));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      debugPrint('Error getting temp dir: $e');
      return null;
    }
  }

  /// Cleans up any leftover temporary files to ensure privacy.
  static Future<void> cleanTempProcessingDir() async {
    if (kIsWeb) return;
    try {
      final dir = await getTempProcessingDir();
      if (dir != null && await dir.exists()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          try {
            await entry.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error cleaning temp dir: $e');
    }
  }

  /// Formats byte size to KB/MB.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
