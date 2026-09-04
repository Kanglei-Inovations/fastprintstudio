import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../core/models/crop_rect_data.dart';
import '../../core/models/id_card_preset.dart';

class DetectedCandidate {
  final String id;
  final String label;
  final CropRectData crop;
  final double aspectRatio;
  final double confidence;
  final bool isFrontSuggestion;
  final bool isBackSuggestion;

  const DetectedCandidate({
    required this.id,
    required this.label,
    required this.crop,
    required this.aspectRatio,
    required this.confidence,
    this.isFrontSuggestion = false,
    this.isBackSuggestion = false,
  });
}

class DocumentDetectionResult {
  final bool isDetected;
  final bool hasBothSides;
  final CropRectData frontCrop;
  final CropRectData? backCrop;
  final List<DetectedCandidate> candidates;
  final double confidence;
  final String description;
  final bool needsUserConfirmation;

  const DocumentDetectionResult({
    required this.isDetected,
    required this.hasBothSides,
    required this.frontCrop,
    this.backCrop,
    this.candidates = const [],
    required this.confidence,
    this.description = '',
    this.needsUserConfirmation = false,
  });
}

class DocumentDetector {
  /// Analyzes an image (scanned, photo, or rendered PDF page) and detects Aadhaar / ID card bounding boxes dynamically.
  static Future<DocumentDetectionResult> detectIDCard({
    required Uint8List imageBytes,
    required IDCardPreset preset,
  }) async {
    return compute(
      _dynamicDocumentDetectionWorker,
      _DocDetectionParams(imageBytes: imageBytes, preset: preset),
    );
  }
}

class _DocDetectionParams {
  final Uint8List imageBytes;
  final IDCardPreset preset;

  _DocDetectionParams({required this.imageBytes, required this.preset});
}

class _BoundingBox {
  double left;
  double top;
  double width;
  double height;
  double score;

  _BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.score = 0.0,
  });

  double get right => left + width;
  double get bottom => top + height;
  double get aspectRatio => height > 0 ? width / height : 1.0;
  double get area => width * height;

  bool overlaps(_BoundingBox other, {double threshold = 0.40}) {
    final interLeft = max(left, other.left);
    final interTop = max(top, other.top);
    final interRight = min(right, other.right);
    final interBottom = min(bottom, other.bottom);

    if (interRight <= interLeft || interBottom <= interTop) return false;
    final interArea = (interRight - interLeft) * (interBottom - interTop);
    final minArea = min(area, other.area);
    return minArea > 0 && (interArea / minArea) > threshold;
  }

  CropRectData toCropRect({double safetyMargin = 0.015}) {
    final padX = width * safetyMargin;
    final padY = height * safetyMargin;

    final cl = (left - padX).clamp(0.0, 1.0);
    final ct = (top - padY).clamp(0.0, 1.0);
    final cw = (width + padX * 2).clamp(0.05, 1.0 - cl);
    final ch = (height + padY * 2).clamp(0.05, 1.0 - ct);

    return CropRectData(
      left: cl,
      top: ct,
      width: cw,
      height: ch,
    );
  }
}

DocumentDetectionResult _dynamicDocumentDetectionWorker(_DocDetectionParams params) {
  try {
    final image = img.decodeImage(params.imageBytes);
    if (image == null) {
      return DocumentDetectionResult(
        isDetected: false,
        hasBothSides: false,
        frontCrop: CropRectData.centeredWithAspectRatio(params.preset.aspectRatio),
        confidence: 0.0,
        description: 'Failed to decode image',
        needsUserConfirmation: true,
      );
    }

    final targetRatio = params.preset.aspectRatio; // ~1.585 for Aadhaar/ISO ID-1

    // Scale down for fast boundary energy and projection analysis (<40ms)
    const analysisWidth = 480;
    final analysisHeight = (image.height * (analysisWidth / image.width)).round().clamp(100, 1200);
    final resized = img.copyResize(image, width: analysisWidth, height: analysisHeight);

    final w = resized.width;
    final h = resized.height;
    final luminance = List<int>.filled(w * h, 0);
    final edges = List<int>.filled(w * h, 0);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        luminance[y * w + x] = (0.299 * r + 0.587 * g + 0.114 * b).round();
      }
    }

    // Sobel gradient computation
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final gx = (luminance[(y - 1) * w + (x + 1)] + 2 * luminance[y * w + (x + 1)] + luminance[(y + 1) * w + (x + 1)]) -
            (luminance[(y - 1) * w + (x - 1)] + 2 * luminance[y * w + (x - 1)] + luminance[(y + 1) * w + (x - 1)]);
        final gy = (luminance[(y + 1) * w + (x - 1)] + 2 * luminance[(y + 1) * w + x] + luminance[(y + 1) * w + (x + 1)]) -
            (luminance[(y - 1) * w + (x - 1)] + 2 * luminance[(y - 1) * w + x] + luminance[(y - 1) * w + (x + 1)]);
        edges[y * w + x] = (gx.abs() + gy.abs()).clamp(0, 255);
      }
    }

    // Extract candidates using multi-pass projection & boundary discovery
    final rawCandidates = _findDocumentCardCandidates(
      w: w,
      h: h,
      luminance: luminance,
      edges: edges,
      targetRatio: targetRatio,
    );

    // Score candidates against aspect ratio and area
    final validCandidates = <_BoundingBox>[];
    for (final box in rawCandidates) {
      if (box.area < 0.025 || box.area > 0.95) continue;

      // Aspect ratio scoring (handles landscape 1.15..1.9 and rotated 0.52..0.88)
      final normalDiff = (box.aspectRatio - targetRatio).abs();
      final rotatedDiff = (box.aspectRatio - (1.0 / targetRatio)).abs();
      final minDiff = min(normalDiff, rotatedDiff);

      double ratioScore = 1.0 - (minDiff / targetRatio).clamp(0.0, 0.7);
      final contentDensity = _computeContentDensity(box, w, h, edges);

      box.score = ratioScore * (0.6 + 0.4 * contentDensity);
      validCandidates.add(box);
    }

    // Sort by confidence
    validCandidates.sort((a, b) => b.score.compareTo(a.score));

    // Non-Maximum Suppression (NMS)
    final nmsCandidates = <_BoundingBox>[];
    for (final cand in validCandidates) {
      bool duplicate = false;
      for (final kept in nmsCandidates) {
        if (cand.overlaps(kept, threshold: 0.35)) {
          duplicate = true;
          break;
        }
      }
      if (!duplicate) {
        nmsCandidates.add(cand);
      }
    }

    // Fallback: Global document boundary
    if (nmsCandidates.isEmpty) {
      final fallbackBox = _detectGlobalCardBoundary(w, h, luminance, edges, targetRatio);
      if (fallbackBox != null) {
        nmsCandidates.add(fallbackBox);
      }
    }

    // Classify candidate regions into Front and Back
    if (nmsCandidates.length >= 2) {
      // Find the two most card-like candidates
      // If there are multiple candidates (e.g. Aadhaar letter header + 2 bottom cards),
      // pick the 2 cards that have matching size/aspect ratios
      _BoundingBox candA = nmsCandidates[0];
      _BoundingBox candB = nmsCandidates[1];

      // If more than 2 candidates, prefer pairs that have similar height & width
      if (nmsCandidates.length > 2) {
        double bestPairDiff = double.infinity;
        for (int i = 0; i < nmsCandidates.length; i++) {
          for (int j = i + 1; j < nmsCandidates.length; j++) {
            final b1 = nmsCandidates[i];
            final b2 = nmsCandidates[j];
            final diff = (b1.width - b2.width).abs() + (b1.height - b2.height).abs();
            if (diff < bestPairDiff && (b1.area + b2.area) < 0.90) {
              bestPairDiff = diff;
              candA = b1;
              candB = b2;
            }
          }
        }
      }

      _BoundingBox frontBox;
      _BoundingBox backBox;
      String arrangementDesc;

      final isVerticalStack = (candA.left - candB.left).abs() < 0.30 && (candA.top - candB.top).abs() > 0.12;
      final isHorizontalPair = (candA.top - candB.top).abs() < 0.25 && (candA.left - candB.left).abs() > 0.15;

      if (isVerticalStack) {
        // Vertical: Top is front, Bottom is back
        if (candA.top < candB.top) {
          frontBox = candA;
          backBox = candB;
        } else {
          frontBox = candB;
          backBox = candA;
        }
        arrangementDesc = 'Vertical Front & Back layout detected';
      } else if (isHorizontalPair) {
        // Horizontal: Left is front, Right is back
        if (candA.left < candB.left) {
          frontBox = candA;
          backBox = candB;
        } else {
          frontBox = candB;
          backBox = candA;
        }
        arrangementDesc = 'Side-by-side Front & Back layout detected';
      } else {
        // Top-left first
        final scoreA = candA.top * 1.5 + candA.left;
        final scoreB = candB.top * 1.5 + candB.left;
        if (scoreA < scoreB) {
          frontBox = candA;
          backBox = candB;
        } else {
          frontBox = candB;
          backBox = candA;
        }
        arrangementDesc = 'Multiple ID card regions detected';
      }

      final candidateList = nmsCandidates.map((c) {
        final isFront = c == frontBox;
        final isBack = c == backBox;
        return DetectedCandidate(
          id: 'cand_${nmsCandidates.indexOf(c) + 1}',
          label: isFront ? 'Front Side' : (isBack ? 'Back Side' : 'Region ${nmsCandidates.indexOf(c) + 1}'),
          crop: c.toCropRect(),
          aspectRatio: c.aspectRatio,
          confidence: c.score.clamp(0.60, 0.98),
          isFrontSuggestion: isFront,
          isBackSuggestion: isBack,
        );
      }).toList();

      final avgConfidence = ((frontBox.score + backBox.score) / 2).clamp(0.65, 0.96);

      return DocumentDetectionResult(
        isDetected: true,
        hasBothSides: true,
        frontCrop: frontBox.toCropRect(),
        backCrop: backBox.toCropRect(),
        candidates: candidateList,
        confidence: avgConfidence,
        description: arrangementDesc,
        needsUserConfirmation: avgConfidence < 0.75,
      );
    } else if (nmsCandidates.length == 1) {
      final singleBox = nmsCandidates.first;
      final candidateList = [
        DetectedCandidate(
          id: 'cand_1',
          label: 'Front Side',
          crop: singleBox.toCropRect(),
          aspectRatio: singleBox.aspectRatio,
          confidence: singleBox.score.clamp(0.70, 0.98),
          isFrontSuggestion: true,
        ),
      ];

      return DocumentDetectionResult(
        isDetected: true,
        hasBothSides: false,
        frontCrop: singleBox.toCropRect(),
        backCrop: null,
        candidates: candidateList,
        confidence: singleBox.score.clamp(0.70, 0.98),
        description: 'Single ID card boundary detected',
        needsUserConfirmation: singleBox.score < 0.75,
      );
    }

    final defaultFront = CropRectData.centeredWithAspectRatio(targetRatio, scaleFactor: 0.90);
    return DocumentDetectionResult(
      isDetected: true,
      hasBothSides: false,
      frontCrop: defaultFront,
      backCrop: null,
      candidates: [
        DetectedCandidate(
          id: 'cand_default',
          label: 'Default Frame',
          crop: defaultFront,
          aspectRatio: targetRatio,
          confidence: 0.50,
          isFrontSuggestion: true,
        ),
      ],
      confidence: 0.50,
      description: 'Default card boundary applied',
      needsUserConfirmation: true,
    );
  } catch (e) {
    debugPrint('Document detection error: $e');
    final fallback = CropRectData.centeredWithAspectRatio(params.preset.aspectRatio);
    return DocumentDetectionResult(
      isDetected: false,
      hasBothSides: false,
      frontCrop: fallback,
      confidence: 0.0,
      description: 'Default crop applied',
      needsUserConfirmation: true,
    );
  }
}

/// Dual-Pass Projection & Edge Profile Analysis
List<_BoundingBox> _findDocumentCardCandidates({
  required int w,
  required int h,
  required List<int> luminance,
  required List<int> edges,
  required double targetRatio,
}) {
  final candidates = <_BoundingBox>[];

  // PASS 1: Row Bands -> Column Segments
  final rowHasEdge = List<bool>.filled(h, false);
  for (int y = 0; y < h; y++) {
    int edgeCount = 0;
    for (int x = 0; x < w; x++) {
      if (edges[y * w + x] > 18) edgeCount++;
    }
    rowHasEdge[y] = edgeCount >= 2;
  }

  final rowBands = _findContinuousSegments(rowHasEdge, minLength: (h * 0.08).round());

  for (final rBand in rowBands) {
    final colHasEdge = List<bool>.filled(w, false);
    for (int x = 0; x < w; x++) {
      int edgeCount = 0;
      for (int y = rBand.start; y <= rBand.end; y++) {
        if (edges[y * w + x] > 18) edgeCount++;
      }
      colHasEdge[x] = edgeCount >= 2;
    }

    final colSegments = _findContinuousSegments(colHasEdge, minLength: (w * 0.12).round());

    for (final cSeg in colSegments) {
      final box = _refineCardBoundingBox(
        cSeg.start,
        rBand.start,
        cSeg.end - cSeg.start + 1,
        rBand.end - rBand.start + 1,
        w,
        h,
        edges,
      );
      if (box != null) candidates.add(box);
    }
  }

  // PASS 2: Column Bands -> Row Segments
  final colHasEdgeGlobal = List<bool>.filled(w, false);
  for (int x = 0; x < w; x++) {
    int edgeCount = 0;
    for (int y = 0; y < h; y++) {
      if (edges[y * w + x] > 18) edgeCount++;
    }
    colHasEdgeGlobal[x] = edgeCount >= 2;
  }

  final colBands = _findContinuousSegments(colHasEdgeGlobal, minLength: (w * 0.12).round());

  for (final cBand in colBands) {
    final rowHasEdgeInCol = List<bool>.filled(h, false);
    for (int y = 0; y < h; y++) {
      int edgeCount = 0;
      for (int x = cBand.start; x <= cBand.end; x++) {
        if (edges[y * w + x] > 18) edgeCount++;
      }
      rowHasEdgeInCol[y] = edgeCount >= 2;
    }

    final rSegments = _findContinuousSegments(rowHasEdgeInCol, minLength: (h * 0.08).round());

    for (final rSeg in rSegments) {
      final box = _refineCardBoundingBox(
        cBand.start,
        rSeg.start,
        cBand.end - cBand.start + 1,
        rSeg.end - rSeg.start + 1,
        w,
        h,
        edges,
      );
      if (box != null) candidates.add(box);
    }
  }

  return candidates;
}

class _OneDimSegment {
  final int start;
  final int end;
  _OneDimSegment(this.start, this.end);
}

List<_OneDimSegment> _findContinuousSegments(List<bool> mask, {required int minLength}) {
  final segments = <_OneDimSegment>[];
  int? segStart;
  const maxGap = 8; // Bridge small gaps (e.g. gaps between text lines or dashed border lines)
  int gapCount = 0;

  for (int i = 0; i < mask.length; i++) {
    if (mask[i]) {
      segStart ??= i;
      gapCount = 0;
    } else {
      if (segStart != null) {
        gapCount++;
        if (gapCount > maxGap) {
          final segEnd = i - gapCount;
          if (segEnd - segStart + 1 >= minLength) {
            segments.add(_OneDimSegment(segStart, segEnd));
          }
          segStart = null;
          gapCount = 0;
        }
      }
    }
  }

  if (segStart != null) {
    final segEnd = mask.length - 1 - gapCount;
    if (segEnd - segStart + 1 >= minLength) {
      segments.add(_OneDimSegment(segStart, segEnd));
    }
  }

  return segments;
}

_BoundingBox? _refineCardBoundingBox(
  int sx,
  int sy,
  int sw,
  int sh,
  int w,
  int h,
  List<int> edges,
) {
  int minX = sx + sw;
  int maxX = sx;
  int minY = sy + sh;
  int maxY = sy;

  for (int y = sy; y < sy + sh; y++) {
    for (int x = sx; x < sx + sw; x++) {
      if (edges[y * w + x] > 18) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX <= minX || maxY <= minY) return null;

  final normL = minX / w;
  final normT = minY / h;
  final normW = (maxX - minX + 1) / w;
  final normH = (maxY - minY + 1) / h;

  return _BoundingBox(
    left: normL,
    top: normT,
    width: normW,
    height: normH,
  );
}

_BoundingBox? _detectGlobalCardBoundary(
  int w,
  int h,
  List<int> luminance,
  List<int> edges,
  double targetRatio,
) {
  int minX = w;
  int maxX = 0;
  int minY = h;
  int maxY = 0;

  for (int y = (h * 0.02).round(); y < (h * 0.98).round(); y++) {
    for (int x = (w * 0.02).round(); x < (w * 0.98).round(); x++) {
      if (edges[y * w + x] > 18) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX <= minX || maxY <= minY) return null;

  final normL = minX / w;
  final normT = minY / h;
  final normW = (maxX - minX + 1) / w;
  final normH = (maxY - minY + 1) / h;

  return _BoundingBox(
    left: normL,
    top: normT,
    width: normW,
    height: normH,
    score: 0.75,
  );
}

double _computeContentDensity(_BoundingBox box, int w, int h, List<int> edges) {
  final sx = (box.left * w).round().clamp(0, w - 1);
  final sy = (box.top * h).round().clamp(0, h - 1);
  final ex = ((box.left + box.width) * w).round().clamp(sx + 1, w);
  final ey = ((box.top + box.height) * h).round().clamp(sy + 1, h);

  int edgeCount = 0;
  int totalPixels = (ex - sx) * (ey - sy);
  if (totalPixels == 0) return 0.0;

  for (int y = sy; y < ey; y++) {
    for (int x = sx; x < ex; x++) {
      if (edges[y * w + x] > 18) edgeCount++;
    }
  }

  return (edgeCount / totalPixels).clamp(0.0, 1.0);
}
