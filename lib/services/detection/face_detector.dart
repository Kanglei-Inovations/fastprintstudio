import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../core/models/crop_rect_data.dart';
import '../../core/models/photo_preset.dart';

class FaceDetectionResult {
  final bool faceDetected;
  final double confidence;
  final CropRectData suggestedCrop;
  final String note;

  const FaceDetectionResult({
    required this.faceDetected,
    required this.confidence,
    required this.suggestedCrop,
    this.note = '',
  });
}

class FaceDetectorService {
  /// Detects face region and calculates suggested passport crop box.
  /// Works completely offline with zero cloud dependency.
  static Future<FaceDetectionResult> detectAndSuggestCrop({
    required Uint8List imageBytes,
    required PhotoPreset preset,
  }) async {
    return compute(
      _faceDetectionWorker,
      _FaceDetectionParams(imageBytes: imageBytes, preset: preset),
    );
  }
}

class _FaceDetectionParams {
  final Uint8List imageBytes;
  final PhotoPreset preset;

  _FaceDetectionParams({required this.imageBytes, required this.preset});
}

FaceDetectionResult _faceDetectionWorker(_FaceDetectionParams params) {
  try {
    final image = img.decodeImage(params.imageBytes);
    if (image == null) {
      return FaceDetectionResult(
        faceDetected: false,
        confidence: 0.0,
        suggestedCrop: CropRectData.centeredWithAspectRatio(params.preset.aspectRatio),
        note: 'Could not decode image',
      );
    }

    final targetAspectRatio = params.preset.aspectRatio; // e.g. 35/45 = 0.7777

    // Downscale for fast skin/face analysis
    final sampleWidth = 200;
    final sampleHeight = (image.height * (200.0 / image.width)).round();
    final sample = img.copyResize(image, width: sampleWidth, height: sampleHeight);

    int totalSkinPixels = 0;
    double sumX = 0;
    double sumY = 0;
    int minX = sampleWidth, maxX = 0;
    int minY = sampleHeight, maxY = 0;

    for (int y = 0; y < sampleHeight; y++) {
      for (int x = 0; x < sampleWidth; x++) {
        final pixel = sample.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Standard skin tone heuristic in RGB / YCbCr
        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));

        final isSkin = (r > 80 && g > 35 && b > 20) &&
            ((maxC - minC) > 12) &&
            (r > g && r > b) &&
            ((r - g).abs() > 10);

        if (isSkin) {
          totalSkinPixels++;
          sumX += x;
          sumY += y;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    final totalPixels = sampleWidth * sampleHeight;
    final skinRatio = totalSkinPixels / totalPixels;

    if (skinRatio > 0.03 && totalSkinPixels > 100) {
      // Face / skin detected
      final centerX = (sumX / totalSkinPixels) / sampleWidth;
      final centerY = (sumY / totalSkinPixels) / sampleHeight;
      final skinHeight = (maxY - minY) / sampleHeight;

      double cropHeight = (skinHeight * 2.0).clamp(0.4, 0.95);
      double cropWidth = cropHeight * targetAspectRatio;

      if (cropWidth > 0.95) {
        cropWidth = 0.95;
        cropHeight = cropWidth / targetAspectRatio;
      }

      // Position crop so face is nicely centered horizontally and eye-line is ~60% from bottom
      double cropLeft = centerX - (cropWidth / 2.0);
      double cropTop = centerY - (cropHeight * 0.45);

      cropLeft = cropLeft.clamp(0.0, 1.0 - cropWidth);
      cropTop = cropTop.clamp(0.0, 1.0 - cropHeight);

      return FaceDetectionResult(
        faceDetected: true,
        confidence: (skinRatio * 3.0).clamp(0.65, 0.95),
        suggestedCrop: CropRectData(
          left: cropLeft,
          top: cropTop,
          width: cropWidth,
          height: cropHeight,
        ),
        note: 'Face detected: suggested passport crop framing',
      );
    } else {
      return FaceDetectionResult(
        faceDetected: false,
        confidence: 0.5,
        suggestedCrop: CropRectData.centeredWithAspectRatio(targetAspectRatio, scaleFactor: 0.85),
        note: 'Center framing suggested',
      );
    }
  } catch (e) {
    debugPrint('Face detection error: $e');
    return FaceDetectionResult(
      faceDetected: false,
      confidence: 0.0,
      suggestedCrop: CropRectData.centeredWithAspectRatio(params.preset.aspectRatio),
      note: 'Fallback crop applied',
    );
  }
}
