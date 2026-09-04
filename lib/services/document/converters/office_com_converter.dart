import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/printable_document.dart';

class OfficeComConverter {
  static const _uuid = Uuid();
  static bool enableComInTest = false;

  /// Converts Office document (.doc, .docx, .xls, .xlsx, .ppt, .pptx) to PDF using Windows COM Automation.
  /// Generates a clean temporary .ps1 script file to avoid PowerShell command-line escaping bugs.
  /// Returns null if COM is unavailable, times out, or fails.
  static Future<Uint8List?> convertToPdf({
    required Uint8List sourceBytes,
    required String originalFileName,
    required DocumentFileType fileType,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    if (!Platform.isWindows) return null;
    if (Platform.environment.containsKey('FLUTTER_TEST') && !enableComInTest) {
      return null;
    }

    final tempDir = Directory.systemTemp;
    final ext = fileType.primaryExtension;
    final randomId = _uuid.v4();
    final sourcePath = '${tempDir.path}\\fastprint_input_$randomId$ext';
    final targetPdfPath = '${tempDir.path}\\fastprint_output_$randomId.pdf';
    final scriptPath = '${tempDir.path}\\fastprint_script_$randomId.ps1';

    final sourceFile = File(sourcePath);
    final targetFile = File(targetPdfPath);
    final scriptFile = File(scriptPath);

    try {
      await sourceFile.writeAsBytes(sourceBytes, flush: true);

      // Escape single quotes for PowerShell script
      final escapedSrc = sourcePath.replaceAll("'", "''");
      final escapedDst = targetPdfPath.replaceAll("'", "''");

      String psScript;
      if (fileType.isWord) {
        psScript = '''
\$ErrorActionPreference = "Stop"
\$src = '$escapedSrc'
\$dst = '$escapedDst'

if (Test-Path \$dst) { Remove-Item \$dst -Force }
Unblock-File -Path \$src -ErrorAction SilentlyContinue

\$word = New-Object -ComObject Word.Application
\$word.Visible = \$false
\$word.DisplayAlerts = 0
\$word.ScreenUpdating = \$false

try {
    # Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles)
    \$doc = \$word.Documents.Open([string]\$src, \$false, \$true, \$false)
    \$doc.ExportAsFixedFormat([string]\$dst, 17) # 17 = wdExportFormatPDF
    \$doc.Close([ref]\$false)
} finally {
    \$word.Quit([ref]\$false)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$word) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
''';
      } else if (fileType.isExcel) {
        psScript = '''
\$ErrorActionPreference = "Stop"
\$src = '$escapedSrc'
\$dst = '$escapedDst'

if (Test-Path \$dst) { Remove-Item \$dst -Force }
Unblock-File -Path \$src -ErrorAction SilentlyContinue

\$excel = New-Object -ComObject Excel.Application
\$excel.Visible = \$false
\$excel.DisplayAlerts = \$false
\$excel.ScreenUpdating = \$false

try {
    \$wb = \$excel.Workbooks.Open([string]\$src, [Type]::Missing, \$true)
    \$wb.ExportAsFixedFormat(0, [string]\$dst) # 0 = xlTypePDF
    \$wb.Close(\$false)
} finally {
    \$excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
''';
      } else if (fileType.isPowerPoint) {
        psScript = '''
\$ErrorActionPreference = "Stop"
\$src = '$escapedSrc'
\$dst = '$escapedDst'

if (Test-Path \$dst) { Remove-Item \$dst -Force }
Unblock-File -Path \$src -ErrorAction SilentlyContinue

\$ppt = New-Object -ComObject PowerPoint.Application

try {
    \$pres = \$ppt.Presentations.Open([string]\$src, [Microsoft.Office.Core.MsoTriState]::msoTrue, [Microsoft.Office.Core.MsoTriState]::msoFalse, [Microsoft.Office.Core.MsoTriState]::msoFalse)
    \$pres.ExportAsFixedFormat([string]\$dst, 2) # 2 = ppFixedFormatTypePDF
    \$pres.Close()
} finally {
    \$ppt.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(\$ppt) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
''';
      } else {
        return null;
      }

      await scriptFile.writeAsString(psScript, flush: true);

      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          scriptPath,
        ],
      ).timeout(timeout);

      if (result.exitCode == 0 && await targetFile.exists()) {
        final pdfBytes = await targetFile.readAsBytes();
        if (pdfBytes.isNotEmpty) {
          debugPrint('Office COM conversion succeeded via PowerShell script. PDF size: \${pdfBytes.length} bytes');
          return pdfBytes;
        }
      } else {
        debugPrint('Office COM script exited with code \${result.exitCode}: \${result.stderr}\\n\${result.stdout}');
      }
    } catch (e) {
      debugPrint('Office COM conversion exception: \$e');
    } finally {
      try {
        if (await sourceFile.exists()) await sourceFile.delete();
      } catch (_) {}
      try {
        if (await targetFile.exists()) await targetFile.delete();
      } catch (_) {}
      try {
        if (await scriptFile.exists()) await scriptFile.delete();
      } catch (_) {}
    }

    return null;
  }
}
