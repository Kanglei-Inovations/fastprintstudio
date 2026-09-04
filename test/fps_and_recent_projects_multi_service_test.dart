import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/services/project/fps_project_service.dart';
import 'package:fastprintstudio/services/storage/recent_projects_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FpsProjectService Multi-Service Tests', () {
    test('parses ID Card .fps project JSON format correctly', () {
      final dummyBytes = Uint8List.fromList([10, 20, 30, 40]);
      final jsonMap = {
        'format': FpsProjectService.formatIdentifier,
        'version': FpsProjectService.currentVersion,
        'projectType': 'id_card',
        'savedAt': DateTime.now().toIso8601String(),
        'fileName': 'aadhaar_card.pdf',
        'rawImageBase64': base64Encode(dummyBytes),
        'metadata': {
          'idCardPresetName': 'Aadhaar (Split Front/Back)',
          'paperPresetName': 'A4',
          'orientationName': 'portrait',
        },
      };

      final parsed = FpsProjectService.parseFpsJson(jsonEncode(jsonMap));
      expect(parsed, isNotNull);
      expect(parsed!['projectType'], equals('id_card'));
      expect(parsed['fileName'], equals('aadhaar_card.pdf'));
      expect(parsed['bytes'], equals(dummyBytes));
      expect(parsed['metadata']['idCardPresetName'], equals('Aadhaar (Split Front/Back)'));
    });

    test('parses Document .fps project JSON format correctly', () {
      final dummyBytes = Uint8List.fromList([50, 60, 70, 80]);
      final jsonMap = {
        'format': FpsProjectService.formatIdentifier,
        'version': FpsProjectService.currentVersion,
        'projectType': 'document',
        'savedAt': DateTime.now().toIso8601String(),
        'fileName': 'annual_report.docx',
        'rawImageBase64': base64Encode(dummyBytes),
        'metadata': {
          'paperPresetName': 'A4',
          'orientation': 'portrait',
          'colorMode': 'color',
          'totalPages': 15,
        },
      };

      final parsed = FpsProjectService.parseFpsJson(jsonEncode(jsonMap));
      expect(parsed, isNotNull);
      expect(parsed!['projectType'], equals('document'));
      expect(parsed['fileName'], equals('annual_report.docx'));
      expect(parsed['bytes'], equals(dummyBytes));
      expect(parsed['metadata']['colorMode'], equals('color'));
      expect(parsed['metadata']['totalPages'], equals(15));
    });
  });

  group('RecentProjectItem Serialization Tests', () {
    test('serializes and deserializes ID Card and Document items', () {
      final idCardItem = RecentProjectItem(
        id: 'id-123',
        projectType: 'id_card',
        fileName: 'voter_id.jpg',
        presetMode: 'Voter ID',
        paperName: '4R',
        orientation: 'Landscape',
        timestamp: DateTime(2026, 9, 2, 12, 0),
        projectData: {'mock': true},
      );

      final json = idCardItem.toJson();
      final restored = RecentProjectItem.fromJson(json);

      expect(restored.id, equals('id-123'));
      expect(restored.projectType, equals('id_card'));
      expect(restored.fileName, equals('voter_id.jpg'));
      expect(restored.presetMode, equals('Voter ID'));
      expect(restored.paperName, equals('4R'));
      expect(restored.orientation, equals('Landscape'));
    });
  });
}
