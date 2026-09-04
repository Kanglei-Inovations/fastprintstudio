import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class LibreOfficeConverter {
  static const _uuid = Uuid();

  /// Detects the LibreOffice executable path on Windows, Linux, or macOS.
  static String? findSofficeExecutable() {
    if (Platform.isWindows) {
      final candidates = [
        r'C:\Program Files\LibreOffice\program\soffice.exe',
        r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
      ];
      for (final p in candidates) {
        if (File(p).existsSync()) return p;
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      final candidates = [
        '/usr/bin/soffice',
        '/usr/local/bin/soffice',
        '/Applications/LibreOffice.app/Contents/MacOS/soffice',
      ];
      for (final p in candidates) {
        if (File(p).existsSync()) return p;
      }
    }
    return null;
  }

  /// Converts a document to PDF using headless LibreOffice if installed.
  static Future<Uint8List?> convertToPdf({
    required Uint8List sourceBytes,
    required String originalFileName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final sofficePath = findSofficeExecutable();
    if (sofficePath == null) return null;

    final tempDir = Directory.systemTemp;
    final randomId = _uuid.v4();
    final dotIdx = originalFileName.lastIndexOf('.');
    final ext = dotIdx != -1 ? originalFileName.substring(dotIdx) : '.docx';
    final sourcePath = '${tempDir.path}\\fastprint_lo_in_$randomId$ext';
    final targetPdfPath = '${tempDir.path}\\fastprint_lo_in_$randomId.pdf';

    final sourceFile = File(sourcePath);
    final targetPdfFile = File(targetPdfPath);

    try {
      await sourceFile.writeAsBytes(sourceBytes, flush: true);

      final result = await Process.run(
        sofficePath,
        [
          '--headless',
          '--convert-to',
          'pdf',
          '--outdir',
          tempDir.path,
          sourcePath,
        ],
      ).timeout(timeout);

      if (result.exitCode == 0 && await targetPdfFile.exists()) {
        final bytes = await targetPdfFile.readAsBytes();
        if (bytes.isNotEmpty) {
          debugPrint('LibreOffice headless conversion succeeded: ${bytes.length} bytes');
          return bytes;
        }
      }
    } catch (e) {
      debugPrint('LibreOffice conversion exception: $e');
    } finally {
      try {
        if (await sourceFile.exists()) await sourceFile.delete();
      } catch (_) {}
      try {
        if (await targetPdfFile.exists()) await targetPdfFile.delete();
      } catch (_) {}
    }

    return null;
  }
}
