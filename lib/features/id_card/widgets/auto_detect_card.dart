import 'package:flutter/material.dart';
import '../../../services/detection/document_detector.dart';
import '../theme/id_card_palette.dart';

class AutoDetectCard extends StatelessWidget {
  final IdCardPalette palette;
  final bool isDetecting;
  final DocumentDetectionResult? detectionResult;
  final bool frontDetected;
  final bool backDetected;
  final VoidCallback onRunAutoDetect;
  final ValueChanged<DetectedCandidate>? onSelectFrontCandidate;
  final ValueChanged<DetectedCandidate>? onSelectBackCandidate;
  final VoidCallback? onAdjustCrop;
  final VoidCallback? onRotate;
  final VoidCallback? onReset;

  const AutoDetectCard({
    super.key,
    required this.palette,
    required this.isDetecting,
    this.detectionResult,
    required this.frontDetected,
    required this.backDetected,
    required this.onRunAutoDetect,
    this.onSelectFrontCandidate,
    this.onSelectBackCandidate,
    this.onAdjustCrop,
    this.onRotate,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final hasResult = detectionResult != null && detectionResult!.isDetected;
    final confidencePercent = ((detectionResult?.confidence ?? 0.0) * 100).round();
    final isConfident = (detectionResult?.confidence ?? 0.0) >= 0.75;
    final candidateCount = detectionResult?.candidates.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.blue.withValues(alpha: 0.1) : palette.blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Confidence Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: palette.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Card Auto Detection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (hasResult)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isConfident
                          ? (palette.isDark ? palette.green.withValues(alpha: 0.18) : palette.greenLight)
                          : (palette.isDark ? palette.orange.withValues(alpha: 0.18) : palette.orangeLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConfident ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 10,
                          color: isConfident ? palette.green : palette.orange,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            isConfident ? '$confidencePercent%' : 'Review ($confidencePercent%)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isConfident ? palette.green : palette.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Detection Metric Breakdown (Size, Rotation, Confidence)
          if (hasResult) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricPill(
                    label: 'Status',
                    value: '✓ Detected',
                    color: palette.green,
                  ),
                  _buildMetricPill(
                    label: 'Physical Size',
                    value: '85.6 × 54 mm',
                    color: palette.blue,
                  ),
                  _buildMetricPill(
                    label: 'Rotation',
                    value: '0.0°',
                    color: palette.textPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Text(
              'Dynamic edge & boundary extraction from JPG, PNG, and PDF scans.',
              style: TextStyle(
                fontSize: 10,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Multiple Candidates Chips if > 1 card found
          if (candidateCount > 1) ...[
            Text(
              'Detected Cards ($candidateCount regions):',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // "Use All" Chip
                InkWell(
                  onTap: () {
                    if (detectionResult!.candidates.isNotEmpty && onSelectFrontCandidate != null) {
                      onSelectFrontCandidate!(detectionResult!.candidates[0]);
                    }
                    if (detectionResult!.candidates.length > 1 && onSelectBackCandidate != null) {
                      onSelectBackCandidate!(detectionResult!.candidates[1]);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Use All',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),

                // Individual Card Chips
                ...detectionResult!.candidates.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cand = entry.value;
                  return PopupMenuButton<String>(
                    tooltip: 'Assign Card ${idx + 1}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 10, color: palette.green),
                          const SizedBox(width: 3),
                          Text(
                            'Card ${idx + 1}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: palette.textPrimary),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 12, color: palette.textSecondary),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'front',
                        height: 30,
                        child: Text('Set as Front Side', style: TextStyle(fontSize: 11, color: palette.textPrimary)),
                      ),
                      PopupMenuItem(
                        value: 'back',
                        height: 30,
                        child: Text('Set as Back Side', style: TextStyle(fontSize: 11, color: palette.textPrimary)),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'front' && onSelectFrontCandidate != null) {
                        onSelectFrontCandidate!(cand);
                      } else if (val == 'back' && onSelectBackCandidate != null) {
                        onSelectBackCandidate!(cand);
                      }
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Toolbar of Actions: [ Auto Detect ], [ Adjust Crop ], [ Rotate ], [ Reset ]
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isDetecting ? null : onRunAutoDetect,
                icon: isDetecting
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.blue,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded, size: 13, color: Colors.white),
                label: Text(
                  isDetecting ? 'Detecting...' : 'Auto Detect',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  elevation: 0,
                ),
              ),

              const SizedBox(width: 6),

              if (onAdjustCrop != null)
                OutlinedButton.icon(
                  onPressed: onAdjustCrop,
                  icon: Icon(Icons.crop_rounded, size: 13, color: palette.blue),
                  label: Text(
                    'Adjust Crop',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    side: BorderSide(color: palette.blue.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                ),

              const Spacer(),

              if (onRotate != null)
                IconButton(
                  onPressed: onRotate,
                  icon: Icon(Icons.rotate_right_rounded, size: 16, color: palette.textSecondary),
                  tooltip: 'Rotate 90°',
                  visualDensity: VisualDensity.compact,
                ),

              if (onReset != null)
                IconButton(
                  onPressed: onReset,
                  icon: Icon(Icons.refresh_rounded, size: 16, color: palette.textSecondary),
                  tooltip: 'Reset Crop',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
