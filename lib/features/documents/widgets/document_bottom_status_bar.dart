import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/document_print_state.dart';

class DocumentBottomStatusBar extends StatelessWidget {
  final DocumentPrintState state;
  final Printer? currentPrinter;

  const DocumentBottomStatusBar({
    super.key,
    required this.state,
    this.currentPrinter,
  });

  @override
  Widget build(BuildContext context) {
    final printerName = currentPrinter?.name ?? 'Default Printer';
    final paperText = '${state.paperPreset.name} (${state.orientation.displayName})';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF0F172A), // Dark slate background matching document.png
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

                  // Copies
                  const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Copies: ${state.copies}',
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
                  const SizedBox(width: 16),
                  _DividerDot(),
                  const SizedBox(width: 16),

                  // Mode
                  const Icon(Icons.palette_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Mode: ${state.colorMode.displayName}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ready Status Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: state.hasDocument ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                state.hasDocument ? 'Ready to print' : 'No document selected',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
              ),
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
