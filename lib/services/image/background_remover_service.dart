import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Configuration for the Background Remover
class BackgroundRemoverConfig {
  /// Color distance tolerance for background detection [0.05 to 0.60] (default: 0.22)
  final double tolerance;

  /// Edge smoothing / feathering radius in pixels [0 to 6] (default: 2)
  final int featherRadius;

  /// Optional replacement background ARGB color value (e.g. 0xFFFFFFFF for white).
  /// If null, the background is made completely transparent (alpha = 0).
  final int? replacementColorValue;

  /// Optional manual seed points for flood fill (in image pixel space)
  final List<math.Point<int>>? customSeeds;

  const BackgroundRemoverConfig({
    this.tolerance = 0.22,
    this.featherRadius = 2,
    this.replacementColorValue,
    this.customSeeds,
  });

  BackgroundRemoverConfig copyWith({
    double? tolerance,
    int? featherRadius,
    int? replacementColorValue,
    bool clearReplacementColor = false,
    List<math.Point<int>>? customSeeds,
  }) {
    return BackgroundRemoverConfig(
      tolerance: tolerance ?? this.tolerance,
      featherRadius: featherRadius ?? this.featherRadius,
      replacementColorValue: clearReplacementColor ? null : (replacementColorValue ?? this.replacementColorValue),
      customSeeds: customSeeds ?? this.customSeeds,
    );
  }
}

/// Studio-Grade Background Removal & Replacement Service for Passport, Portrait & ID Photos
class BackgroundRemoverService {
  /// Asynchronously removes background in a background isolate
  static Future<Uint8List> removeBackgroundAsync({
    required Uint8List sourceBytes,
    BackgroundRemoverConfig config = const BackgroundRemoverConfig(),
  }) async {
    return compute(
      _removeBackgroundWorker,
      _BgWorkerParams(sourceBytes: sourceBytes, config: config),
    );
  }

  /// Synchronously removes or replaces the background of an image
  static Uint8List removeBackground({
    required Uint8List sourceBytes,
    BackgroundRemoverConfig config = const BackgroundRemoverConfig(),
  }) {
    final original = img.decodeImage(sourceBytes);
    if (original == null) return sourceBytes;

    final width = original.width;
    final height = original.height;
    if (width <= 0 || height <= 0) return sourceBytes;

    // 1. Gather perimeter seeds
    final seeds = <math.Point<int>>[];
    if (config.customSeeds != null && config.customSeeds!.isNotEmpty) {
      seeds.addAll(config.customSeeds!);
    } else {
      // Top row
      final stepX = math.max(1, width ~/ 30);
      for (int x = 0; x < width; x += stepX) {
        seeds.add(math.Point(x, 0));
        if (height > 5) seeds.add(math.Point(x, 2));
      }

      // Left & right edges (top 70% where background surrounds head & shoulders)
      final maxY = (height * 0.75).round();
      final stepY = math.max(1, height ~/ 30);
      for (int y = 0; y < maxY; y += stepY) {
        seeds.add(math.Point(0, y));
        seeds.add(math.Point(width - 1, y));
        if (width > 5) {
          seeds.add(math.Point(2, y));
          seeds.add(math.Point(width - 3, y));
        }
      }

      // Top-left and top-right corner patches
      for (int dy = 0; dy < math.min(10, height); dy++) {
        for (int dx = 0; dx < math.min(10, width); dx++) {
          seeds.add(math.Point(dx, dy));
          seeds.add(math.Point(width - 1 - dx, dy));
        }
      }
    }

    // 2. Compute average background color from seeds
    double sumR = 0, sumG = 0, sumB = 0;
    int seedSampleCount = 0;
    for (final seed in seeds) {
      if (seed.x >= 0 && seed.x < width && seed.y >= 0 && seed.y < height) {
        final p = original.getPixel(seed.x, seed.y);
        sumR += p.r;
        sumG += p.g;
        sumB += p.b;
        seedSampleCount++;
      }
    }
    if (seedSampleCount == 0) return sourceBytes;

    final avgR = sumR / seedSampleCount;
    final avgG = sumG / seedSampleCount;
    final avgB = sumB / seedSampleCount;

    // 3. Multi-seed Breadth-First-Search (BFS) Flood Fill
    // 0 = background, 255 = foreground
    final mask = Uint8List(width * height);
    mask.fillRange(0, mask.length, 255);

    // Visited bitset: 1 = visited/queued as background
    final visited = Uint8List(width * height);
    final queue = Int32List(width * height);
    int head = 0;
    int tail = 0;

    void enqueue(int x, int y) {
      final idx = y * width + x;
      if (visited[idx] == 0) {
        visited[idx] = 1;
        mask[idx] = 0;
        queue[tail++] = (y << 16) | x;
      }
    }

    // Enqueue all initial perimeter seeds
    for (final seed in seeds) {
      if (seed.x >= 0 && seed.x < width && seed.y >= 0 && seed.y < height) {
        enqueue(seed.x, seed.y);
      }
    }

    final maxTolerance = config.tolerance * 441.67; // Normalized 3D Euclidean distance max
    final localTolerance = config.tolerance * 1.35 * 441.67;

    while (head < tail) {
      final val = queue[head++];
      final x = val & 0xFFFF;
      final y = (val >> 16) & 0xFFFF;

      final currentPixel = original.getPixel(x, y);
      final cr = currentPixel.r;
      final cg = currentPixel.g;
      final cb = currentPixel.b;

      // 4-connected neighbors
      final neighbors = [
        if (x > 0) math.Point(x - 1, y),
        if (x < width - 1) math.Point(x + 1, y),
        if (y > 0) math.Point(x, y - 1),
        if (y < height - 1) math.Point(x, y + 1),
      ];

      for (final n in neighbors) {
        final nIdx = n.y * width + n.x;
        if (visited[nIdx] != 0) continue;

        final np = original.getPixel(n.x, n.y);
        final nr = np.r;
        final ng = np.g;
        final nb = np.b;

        // Distance to mean background color
        final dr = nr - avgR;
        final dg = ng - avgG;
        final db = nb - avgB;
        final distMean = math.sqrt(dr * dr + dg * dg + db * db);

        // Distance to current adjacent pixel
        final ldr = nr - cr;
        final ldg = ng - cg;
        final ldb = nb - cb;
        final distLocal = math.sqrt(ldr * ldr + ldg * ldg + ldb * ldb);

        if (distMean <= maxTolerance && distLocal <= localTolerance) {
          enqueue(n.x, n.y);
        }
      }
    }

    // 4. Edge Feathering / Anti-Aliasing (Smoothing borders around hair and shoulders)
    final featheredMask = Uint8List.fromList(mask);
    if (config.featherRadius > 0) {
      final r = config.featherRadius;
      for (int y = r; y < height - r; y++) {
        for (int x = r; x < width - r; x++) {
          final idx = y * width + x;
          // Only feather pixels near the boundary
          int currentVal = mask[idx];
          bool isBorder = false;
          for (int dy = -1; dy <= 1 && !isBorder; dy++) {
            for (int dx = -1; dx <= 1 && !isBorder; dx++) {
              if (mask[(y + dy) * width + (x + dx)] != currentVal) {
                isBorder = true;
              }
            }
          }

          if (isBorder) {
            int sum = 0;
            int count = 0;
            for (int dy = -r; dy <= r; dy++) {
              for (int dx = -r; dx <= r; dx++) {
                sum += mask[(y + dy) * width + (x + dx)];
                count++;
              }
            }
            featheredMask[idx] = (sum / count).round().clamp(0, 255);
          }
        }
      }
    }

    // 5. Build output image with transparent or replaced background
    final output = img.Image(width: width, height: height, numChannels: 4);
    final replVal = config.replacementColorValue;

    int replR = 255, replG = 255, replB = 255, replA = 255;
    if (replVal != null) {
      replA = (replVal >> 24) & 0xFF;
      replR = (replVal >> 16) & 0xFF;
      replG = (replVal >> 8) & 0xFF;
      replB = replVal & 0xFF;
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final alphaFactor = featheredMask[idx];
        final srcPixel = original.getPixel(x, y);

        if (replVal != null) {
          // Blend with replacement background color
          final fgR = srcPixel.r.toInt();
          final fgG = srcPixel.g.toInt();
          final fgB = srcPixel.b.toInt();

          final outR = ((fgR * alphaFactor) + (replR * (255 - alphaFactor))) ~/ 255;
          final outG = ((fgG * alphaFactor) + (replG * (255 - alphaFactor))) ~/ 255;
          final outB = ((fgB * alphaFactor) + (replB * (255 - alphaFactor))) ~/ 255;
          output.setPixelRgba(x, y, outR, outG, outB, replA);
        } else {
          // Transparent PNG background
          final outA = ((srcPixel.a.toInt()) * alphaFactor) ~/ 255;
          output.setPixelRgba(
            x,
            y,
            srcPixel.r.toInt(),
            srcPixel.g.toInt(),
            srcPixel.b.toInt(),
            outA,
          );
        }
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }
}

class _BgWorkerParams {
  final Uint8List sourceBytes;
  final BackgroundRemoverConfig config;

  _BgWorkerParams({required this.sourceBytes, required this.config});
}

Uint8List _removeBackgroundWorker(_BgWorkerParams params) {
  return BackgroundRemoverService.removeBackground(
    sourceBytes: params.sourceBytes,
    config: params.config,
  );
}
