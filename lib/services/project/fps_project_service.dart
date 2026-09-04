import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../storage/recent_projects_service.dart';

class FpsProjectService {
  static const String formatIdentifier = 'fastprint_studio_project';
  static const int currentVersion = 1;

  /// Bundles and saves any project (photo, id_card, document) as a standalone `.fps` project file
  static Future<String?> saveProjectAsFps({
    String projectType = 'photo',
    Uint8List? rawBytes,
    Uint8List? rawImageBytes,
    required String fileName,
    required Map<String, dynamic> metadata,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final bytes = rawBytes ?? rawImageBytes;
      if (bytes == null || bytes.isEmpty) return null;

      final baseName = p.basenameWithoutExtension(fileName);
      final suggestedFileName = '$baseName.fps';

      final bundle = <String, dynamic>{
        'format': formatIdentifier,
        'version': currentVersion,
        'projectType': projectType,
        'savedAt': DateTime.now().toIso8601String(),
        'fileName': fileName,
        'metadata': metadata,
        'rawImageBase64': base64Encode(bytes),
        'thumbnailBase64': thumbnailBytes != null ? base64Encode(thumbnailBytes) : null,
      };

      final jsonString = jsonEncode(bundle);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      // Prompt user for save destination on desktop
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save FastPrint Studio Project (.fps)',
        fileName: suggestedFileName,
        bytes: jsonBytes,
        type: FileType.custom,
        allowedExtensions: ['fps'],
      );

      if (savedUri == null) return null; // Cancelled

      final finalPath = savedUri.toFilePath();
      debugPrint('Successfully saved $projectType .fps project to: $finalPath');

      // Record in Recent Projects
      final presetMode = metadata['presetModeName'] as String? ??
          metadata['idCardPresetName'] as String? ??
          metadata['documentTypeName'] as String? ??
          (projectType == 'id_card' ? 'ID Card' : (projectType == 'document' ? 'Document' : 'Photo'));
      final paperName = metadata['paperPresetName'] as String? ?? metadata['paperSizeName'] as String? ?? 'A4';
      final orientation = metadata['orientationName'] as String? ?? 'Portrait';

      await RecentProjectsService.addProject(
        RecentProjectItem(
          id: finalPath,
          projectType: projectType,
          fileName: p.basename(finalPath),
          presetMode: presetMode,
          paperName: paperName,
          orientation: orientation,
          timestamp: DateTime.now(),
          thumbnailBytes: thumbnailBytes,
          projectData: bundle,
        ),
      );

      return finalPath;
    } catch (e) {
      debugPrint('Error saving .fps project: $e');
      rethrow;
    }
  }

  /// Opens file dialog to pick an existing `.fps` file
  static Future<Map<String, dynamic>?> pickAndLoadFpsFile({String? title}) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: title ?? 'Open FastPrint Studio Project',
        type: FileType.custom,
        allowedExtensions: ['fps'],
      );

      if (file == null) return null;

      final path = file.path;
      if (path != null) {
        return await loadFpsFromFile(path);
      }

      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);
      return parseFpsJson(content, filePath: file.name);
    } catch (e) {
      debugPrint('Error picking .fps file: $e');
      return null;
    }
  }

  /// Reads and parses a `.fps` file from a path
  static Future<Map<String, dynamic>?> loadFpsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      return parseFpsJson(content, filePath: filePath);
    } catch (e) {
      debugPrint('Error loading .fps file from path $filePath: $e');
      return null;
    }
  }

  /// Parses JSON content of a `.fps` project file
  static Map<String, dynamic>? parseFpsJson(String jsonString, {String? filePath}) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data['format'] != formatIdentifier) {
        debugPrint('Warning: file format header does not match $formatIdentifier');
      }

      final rawBase64 = data['rawImageBase64'] as String?;
      if (rawBase64 == null || rawBase64.isEmpty) return null;

      final rawBytes = base64Decode(rawBase64);
      final fileName = data['fileName'] as String? ?? (filePath != null ? p.basename(filePath) : 'Project.fps');
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      final projectType = data['projectType'] as String? ?? 'photo';

      Uint8List? thumbBytes;
      final thumbBase64 = data['thumbnailBase64'] as String?;
      if (thumbBase64 != null && thumbBase64.isNotEmpty) {
        try {
          thumbBytes = base64Decode(thumbBase64);
        } catch (_) {}
      }

      return {
        'projectType': projectType,
        'bytes': rawBytes,
        'fileName': fileName,
        'metadata': metadata,
        'thumbnailBytes': thumbBytes,
        'filePath': filePath,
      };
    } catch (e) {
      debugPrint('Error parsing .fps JSON: $e');
      return null;
    }
  }

  /// Registers Windows File Associations for `.fps` project files and photos
  /// Writes keys to `HKEY_CURRENT_USER\Software\Classes` without requiring Admin rights.
  static Future<bool> registerWindowsFileAssociation() async {
    if (!Platform.isWindows) return false;

    try {
      final exePath = Platform.resolvedExecutable;
      if (exePath.isEmpty || !exePath.endsWith('.exe')) return false;

      final batchCommands = '''
reg add "HKCU\\Software\\Classes\\.fps" /ve /d "FastPrintStudio.Project" /f
reg add "HKCU\\Software\\Classes\\FastPrintStudio.Project" /ve /d "FastPrint Studio Project" /f
reg add "HKCU\\Software\\Classes\\FastPrintStudio.Project\\DefaultIcon" /ve /d "$exePath,0" /f
reg add "HKCU\\Software\\Classes\\FastPrintStudio.Project\\shell\\open\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f

reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\shell\\open\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".fps" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".jpg" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".jpeg" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".png" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".webp" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".bmp" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".pdf" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".doc" /t REG_SZ /d "" /f
reg add "HKCU\\Software\\Classes\\Applications\\FastPrintStudio.exe\\SupportedTypes" /v ".docx" /t REG_SZ /d "" /f

reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\image\\shell\\FastPrintStudio" /ve /d "Open with FastPrint Studio" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\image\\shell\\FastPrintStudio" /v "Icon" /d "$exePath,0" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\image\\shell\\FastPrintStudio\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f

reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.pdf\\shell\\FastPrintStudio" /ve /d "Open with FastPrint Studio" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.pdf\\shell\\FastPrintStudio" /v "Icon" /d "$exePath,0" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.pdf\\shell\\FastPrintStudio\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f

reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.docx\\shell\\FastPrintStudio" /ve /d "Open with FastPrint Studio" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.docx\\shell\\FastPrintStudio" /v "Icon" /d "$exePath,0" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.docx\\shell\\FastPrintStudio\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f

reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.doc\\shell\\FastPrintStudio" /ve /d "Open with FastPrint Studio" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.doc\\shell\\FastPrintStudio" /v "Icon" /d "$exePath,0" /f
reg add "HKCU\\Software\\Classes\\SystemFileAssociations\\.doc\\shell\\FastPrintStudio\\command" /ve /d "\\"$exePath\\" \\"%1\\"" /f
''';

      final tempDir = Directory.systemTemp;
      final regScriptFile = File('${tempDir.path}${Platform.pathSeparator}register_fps.bat');
      await regScriptFile.writeAsString(batchCommands);

      final process = await Process.run('cmd.exe', ['/c', regScriptFile.path]);
      try {
        if (await regScriptFile.exists()) await regScriptFile.delete();
      } catch (_) {}

      debugPrint('Windows file association result: ${process.exitCode}');
      return process.exitCode == 0;
    } catch (e) {
      debugPrint('Error registering Windows file associations: $e');
      return false;
    }
  }
}
