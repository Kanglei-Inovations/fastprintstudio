import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class RecentProjectItem {
  final String id;
  final String projectType; // 'photo', 'id_card', or 'document'
  final String fileName;
  final String presetMode;
  final String paperName;
  final String orientation;
  final DateTime timestamp;
  final Uint8List? thumbnailBytes;
  final Map<String, dynamic> projectData;

  const RecentProjectItem({
    required this.id,
    this.projectType = 'photo',
    required this.fileName,
    required this.presetMode,
    required this.paperName,
    required this.orientation,
    required this.timestamp,
    this.thumbnailBytes,
    required this.projectData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectType': projectType,
      'fileName': fileName,
      'presetMode': presetMode,
      'paperName': paperName,
      'orientation': orientation,
      'timestamp': timestamp.toIso8601String(),
      'thumbnailBase64': thumbnailBytes != null ? base64Encode(thumbnailBytes!) : null,
      'projectData': projectData,
    };
  }

  factory RecentProjectItem.fromJson(Map<String, dynamic> json) {
    Uint8List? thumb;
    final thumbStr = json['thumbnailBase64'] as String?;
    if (thumbStr != null && thumbStr.isNotEmpty) {
      try {
        thumb = base64Decode(thumbStr);
      } catch (_) {}
    }

    return RecentProjectItem(
      id: json['id'] as String? ?? '',
      projectType: json['projectType'] as String? ?? 'photo',
      fileName: json['fileName'] as String? ?? 'Untitled Project',
      presetMode: json['presetMode'] as String? ?? 'Standard',
      paperName: json['paperName'] as String? ?? 'A4',
      orientation: json['orientation'] as String? ?? 'Portrait',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      thumbnailBytes: thumb,
      projectData: json['projectData'] as Map<String, dynamic>? ?? {},
    );
  }
}

class RecentProjectsService {
  static const int maxRecentProjects = 12;
  static File? _cachedFile;

  static Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    final recentsDir = Directory('${dir.path}${Platform.pathSeparator}FastPrintStudio${Platform.pathSeparator}recents');
    if (!await recentsDir.exists()) {
      await recentsDir.create(recursive: true);
    }
    _cachedFile = File('${recentsDir.path}${Platform.pathSeparator}recent_studio_projects.json');
    return _cachedFile!;
  }

  static Future<List<RecentProjectItem>> getRecentProjects({String? projectType}) async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final decoded = jsonDecode(content) as List<dynamic>;
      final list = decoded.map((e) => RecentProjectItem.fromJson(e as Map<String, dynamic>)).toList();
      if (projectType != null) {
        return list.where((item) => item.projectType == projectType).toList();
      }
      return list;
    } catch (e) {
      debugPrint('Error loading recent projects: $e');
      return [];
    }
  }

  static Future<void> addProject(RecentProjectItem item) async {
    try {
      final all = await getRecentProjects();
      // Remove any existing item with the same id or (fileName and projectType)
      all.removeWhere((e) => e.id == item.id || (e.fileName == item.fileName && e.projectType == item.projectType));
      all.insert(0, item);

      // Keep up to maxRecentProjects per type or max overall
      final file = await _getFile();
      await file.writeAsString(jsonEncode(all.map((e) => e.toJson()).toList()), flush: true);
    } catch (e) {
      debugPrint('Error adding recent project: $e');
    }
  }

  static Future<void> removeProject(String id) async {
    try {
      final list = await getRecentProjects();
      list.removeWhere((e) => e.id == id);
      final file = await _getFile();
      await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()), flush: true);
    } catch (e) {
      debugPrint('Error removing recent project: $e');
    }
  }

  static Future<void> clearAll({String? projectType}) async {
    try {
      if (projectType == null) {
        final file = await _getFile();
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        final list = await getRecentProjects();
        list.removeWhere((e) => e.projectType == projectType);
        final file = await _getFile();
        await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()), flush: true);
      }
    } catch (e) {
      debugPrint('Error clearing recent projects: $e');
    }
  }
}
