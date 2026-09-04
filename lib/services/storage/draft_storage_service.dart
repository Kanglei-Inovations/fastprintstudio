import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DraftStorageService {
  static const _draftFolder = 'fastprint_drafts';

  static Future<Directory> _getDraftDirectory() async {
    Directory baseDir;
    try {
      baseDir = await getApplicationSupportDirectory();
    } catch (_) {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        baseDir = Directory.systemTemp;
      }
    }

    final draftDir = Directory('${baseDir.path}${Platform.pathSeparator}$_draftFolder');
    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }
    return draftDir;
  }

  // ==========================================
  // 1. DOCUMENT PRINT DRAFT
  // ==========================================

  static Future<void> saveDocumentDraft({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}doc_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}doc_draft.json');

      await binFile.writeAsBytes(bytes, flush: true);

      final fullMeta = {
        'fileName': fileName,
        'savedAt': DateTime.now().toIso8601String(),
        ...metadata,
      };
      await metaFile.writeAsString(jsonEncode(fullMeta), flush: true);
      debugPrint('Document draft saved successfully: $fileName (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Error saving document draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadDocumentDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}doc_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}doc_draft.json');

      if (await binFile.exists() && await metaFile.exists()) {
        final bytes = await binFile.readAsBytes();
        final metaJson = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;

        return {
          'bytes': bytes,
          'fileName': metaJson['fileName'] as String? ?? 'Restored_Document.pdf',
          'metadata': metaJson,
        };
      }
    } catch (e) {
      debugPrint('Error loading document draft: $e');
    }
    return null;
  }

  static Future<void> clearDocumentDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}doc_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}doc_draft.json');

      if (await binFile.exists()) await binFile.delete();
      if (await metaFile.exists()) await metaFile.delete();
      debugPrint('Document draft cleared');
    } catch (e) {
      debugPrint('Error clearing document draft: $e');
    }
  }

  // ==========================================
  // 2. ID CARD / AADHAAR PRINT DRAFT
  // ==========================================

  static Future<void> saveIdCardDraft({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.json');

      await binFile.writeAsBytes(bytes, flush: true);

      final fullMeta = {
        'fileName': fileName,
        'savedAt': DateTime.now().toIso8601String(),
        ...metadata,
      };
      await metaFile.writeAsString(jsonEncode(fullMeta), flush: true);
      debugPrint('ID Card draft saved successfully: $fileName (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Error saving ID card draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadIdCardDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.json');

      if (await binFile.exists() && await metaFile.exists()) {
        final bytes = await binFile.readAsBytes();
        final metaJson = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;

        return {
          'bytes': bytes,
          'fileName': metaJson['fileName'] as String? ?? 'Restored_ID_Card.jpg',
          'metadata': metaJson,
        };
      }
    } catch (e) {
      debugPrint('Error loading ID card draft: $e');
    }
    return null;
  }

  static Future<void> clearIdCardDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}idcard_draft.json');

      if (await binFile.exists()) await binFile.delete();
      if (await metaFile.exists()) await metaFile.delete();
      debugPrint('ID Card draft cleared');
    } catch (e) {
      debugPrint('Error clearing ID card draft: $e');
    }
  }

  // ==========================================
  // 3. PASSPORT / PHOTO PRINT DRAFT
  // ==========================================

  static Future<void> savePhotoDraft({
    required Uint8List bytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}photo_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}photo_draft.json');

      await binFile.writeAsBytes(bytes, flush: true);

      final fullMeta = {
        'fileName': fileName,
        'savedAt': DateTime.now().toIso8601String(),
        ...metadata,
      };
      await metaFile.writeAsString(jsonEncode(fullMeta), flush: true);
      debugPrint('Photo draft saved successfully: $fileName (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Error saving photo draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadPhotoDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}photo_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}photo_draft.json');

      if (await binFile.exists() && await metaFile.exists()) {
        final bytes = await binFile.readAsBytes();
        final metaJson = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;

        return {
          'bytes': bytes,
          'fileName': metaJson['fileName'] as String? ?? 'Restored_Photo.jpg',
          'metadata': metaJson,
        };
      }
    } catch (e) {
      debugPrint('Error loading photo draft: $e');
    }
    return null;
  }

  static Future<void> clearPhotoDraft() async {
    try {
      final dir = await _getDraftDirectory();
      final binFile = File('${dir.path}${Platform.pathSeparator}photo_draft.bin');
      final metaFile = File('${dir.path}${Platform.pathSeparator}photo_draft.json');

      if (await binFile.exists()) await binFile.delete();
      if (await metaFile.exists()) await metaFile.delete();
      debugPrint('Photo draft cleared');
    } catch (e) {
      debugPrint('Error clearing photo draft: $e');
    }
  }
}
