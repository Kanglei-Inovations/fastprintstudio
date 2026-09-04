import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/printable_document.dart';

class DocumentTypeDetector {
  /// Detects the accurate DocumentFileType based on file extension and magic byte signatures
  static DocumentFileType detect({
    required String fileName,
    Uint8List? bytes,
  }) {
    final lowerName = fileName.toLowerCase().trim();
    final ext = lowerName.contains('.') ? lowerName.substring(lowerName.lastIndexOf('.')) : '';

    // First, check magic bytes if available
    if (bytes != null && bytes.length >= 4) {
      // 1. PDF magic bytes: %PDF (0x25, 0x50, 0x44, 0x46)
      if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
        return DocumentFileType.pdf;
      }

      // 2. Images
      // PNG: 0x89 0x50 0x4E 0x47
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return DocumentFileType.image;
      }
      // JPEG: 0xFF 0xD8 0xFF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return DocumentFileType.image;
      }
      // BMP: 'B' 'M'
      if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return DocumentFileType.image;
      }
      // WEBP: 'R' 'I' 'F' 'F' ... 'W' 'E' 'B' 'P'
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return DocumentFileType.image;
      }

      // 3. OLE2 Compound File Binary Format (Legacy Office: .doc, .xls, .ppt)
      // 0xD0 0xCF 0x11 0xE0 0xA1 0xB1 0x1A 0xE1
      if (bytes.length >= 8 &&
          bytes[0] == 0xD0 &&
          bytes[1] == 0xCF &&
          bytes[2] == 0x11 &&
          bytes[3] == 0xE0 &&
          bytes[4] == 0xA1 &&
          bytes[5] == 0xB1 &&
          bytes[6] == 0x1A &&
          bytes[7] == 0xE1) {
        if (ext == '.doc') return DocumentFileType.doc;
        if (ext == '.xls') return DocumentFileType.xls;
        if (ext == '.ppt') return DocumentFileType.ppt;
        return DocumentFileType.doc; // Default legacy Office
      }

      // 4. ZIP Package (Modern OpenXML: .docx, .xlsx, .pptx)
      // 'P' 'K' 0x03 0x04
      if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
        // Check extension first for fast match
        if (ext == '.docx') return DocumentFileType.docx;
        if (ext == '.xlsx') return DocumentFileType.xlsx;
        if (ext == '.pptx') return DocumentFileType.pptx;

        // Inspect zip archive entries if extension is ambiguous
        try {
          final archive = ZipDecoder().decodeBytes(bytes, verify: false);
          for (final file in archive.files) {
            if (file.name.startsWith('word/')) return DocumentFileType.docx;
            if (file.name.startsWith('xl/')) return DocumentFileType.xlsx;
            if (file.name.startsWith('ppt/')) return DocumentFileType.pptx;
          }
        } catch (_) {}
      }
    }

    // Fallback: match strictly by file extension
    switch (ext) {
      case '.pdf':
        return DocumentFileType.pdf;
      case '.docx':
        return DocumentFileType.docx;
      case '.doc':
        return DocumentFileType.doc;
      case '.xlsx':
        return DocumentFileType.xlsx;
      case '.xls':
        return DocumentFileType.xls;
      case '.pptx':
        return DocumentFileType.pptx;
      case '.ppt':
        return DocumentFileType.ppt;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
      case '.bmp':
      case '.tiff':
      case '.tif':
        return DocumentFileType.image;
      default:
        return DocumentFileType.unknown;
    }
  }
}
