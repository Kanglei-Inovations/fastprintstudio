import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/models/paper_preset.dart';
import '../../../core/models/photo_finish.dart';
import '../../../providers/passport_photo_provider.dart';

class PhotoBottomStatusBar extends StatelessWidget {
  final PassportPhotoState state;
  final Printer? currentPrinter;

  const PhotoBottomStatusBar({
    super.key,
    required this.state,
    this.currentPrinter,
  });

  @override
  Widget build(BuildContext context) {
    final printerName = currentPrinter?.name ?? 'Default Printer';
    final paperText = '${state.paperPreset.name} (${state.orientation == PaperOrientation.portrait ? "Portrait" : "Landscape"})';
    final finishText = state.photoFinish == PhotoFinish.glossy ? 'Glossy Photo Paper' : 'Matte Photo Paper';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF0F172A), // Dark slate background matching Document Printing
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Printer Name
                  const Icon(Icons.print_rounded, size: 13, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Printer: $printerName',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // Paper Preset
                  const Icon(Icons.description_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Paper: $paperText',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // Photo Finish
                  const Icon(Icons.wb_sunny_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Finish: $finishText',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // Copies
                  const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Copies: ${state.printJobCopies}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // Packed Photos
                  const Icon(Icons.portrait_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Photos: ${state.totalCopiesCount} pcs (${state.totalSheetsRequired} Sheet${state.totalSheetsRequired > 1 ? "s" : ""})',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // DPI
                  const Icon(Icons.speed_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  const Text(
                    'DPI: 300',
                    style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ready / Processing Status Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isProcessing) ...[
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.processingStatusText.isNotEmpty ? state.processingStatusText : 'Processing...',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8)),
                ),
              ] else ...[
                Icon(
                  Icons.circle,
                  size: 8,
                  color: state.hasImage ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  state.hasImage ? 'Ready to print' : 'No photo selected',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: const Color(0xFF334155),
    );
  }
}
