import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/document/models/printable_document.dart';
import '../models/document_print_state.dart';

class DocumentPreviewCanvas extends StatefulWidget {
  final DocumentPrintState state;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback? onRetry;
  final VoidCallback? onChooseAnother;

  const DocumentPreviewCanvas({
    super.key,
    required this.state,
    required this.onSelectPage,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    this.onRetry,
    this.onChooseAnother,
  });

  @override
  State<DocumentPreviewCanvas> createState() => _DocumentPreviewCanvasState();
}

class _DocumentPreviewCanvasState extends State<DocumentPreviewCanvas> {
  final ScrollController _thumbScrollController = ScrollController();

  @override
  void dispose() {
    _thumbScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final paperW = state.paperPreset.effectiveWidthMm(state.orientation);
    final paperH = state.paperPreset.effectiveHeightMm(state.orientation);

    final isPreparing = state.renderStatus == DocumentRenderStatus.preparing;
    final hasError = state.renderStatus == DocumentRenderStatus.error ||
        (state.errorMessage != null && !state.hasDocument);

    return Container(
      color: const Color(0xFFF1F5F9), // Light slate gray background matching document.png
      child: Column(
        children: [
          // 1. Top Preview Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Document Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (state.hasDocument && state.totalPages > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Document ready — ${state.totalPages} ${state.totalPages == 1 ? "page" : "pages"}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.paperPreset.name}  |  ${state.orientation.displayName}  |  DPI: 300  |  Mode: ${state.colorMode.displayName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Zoom Stepper & Fit Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onZoomOut,
                        icon: const Icon(Icons.remove, size: 15, color: Color(0xFF475569)),
                        tooltip: 'Zoom Out',
                        visualDensity: VisualDensity.compact,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${(state.zoomScale * 100).round()}%',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onZoomIn,
                        icon: const Icon(Icons.add, size: 15, color: Color(0xFF475569)),
                        tooltip: 'Zoom In',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.onResetZoom,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Fit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ),
              ],
            ),
          ),

          // 2. Center Content Area (Loading, Error, or Paper Sheet)
          if (isPreparing)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Preparing document preview…',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Formatting ${state.fileName ?? "document"} into print-ready pages',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (hasError)
            Expanded(
              child: Center(
                child: Container(
                  width: 490,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(Icons.description_outlined, size: 32, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to preview this ${state.fileType ?? "Word"} document',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'Try opening it in a compatible Office application and saving as PDF.',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.onRetry != null) ...[
                            ElevatedButton.icon(
                              onPressed: widget.onRetry,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                              label: const Text('Retry Preview', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (widget.onChooseAnother != null)
                            OutlinedButton.icon(
                              onPressed: widget.onChooseAnother,
                              icon: const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF475569)),
                              label: const Text('Choose Another File', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availW = constraints.maxWidth - 40;
                  final availH = constraints.maxHeight - 40;

                  final scaleX = availW / paperW;
                  final scaleY = availH / paperH;
                  final baseScale = math.min(scaleX, scaleY).clamp(0.5, 3.5);

                  final sheetW = paperW * baseScale * state.zoomScale;
                  final sheetH = paperH * baseScale * state.zoomScale;

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          width: sheetW,
                          height: sheetH,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: state.activePageImageBytes != null
                              ? Stack(
                                  children: [
                                    // Rendered Document Page Image
                                    Positioned.fill(
                                      child: Padding(
                                        padding: EdgeInsets.all(state.marginMm * baseScale * state.zoomScale),
                                        child: RotatedBox(
                                          quarterTurns: state.rotationAngle ~/ 90,
                                          child: state.colorMode == ColorMode.blackAndWhite
                                              ? ColorFiltered(
                                                  colorFilter: const ColorFilter.mode(
                                                    Colors.grey,
                                                    BlendMode.saturation,
                                                  ),
                                                  child: Image.memory(
                                                    state.activePageImageBytes!,
                                                    fit: state.scaling == PageScaling.fillPage
                                                        ? BoxFit.fill
                                                        : (state.scaling == PageScaling.actualSize ? BoxFit.none : BoxFit.contain),
                                                  ),
                                                )
                                              : Image.memory(
                                                  state.activePageImageBytes!,
                                                  fit: state.scaling == PageScaling.fillPage
                                                      ? BoxFit.fill
                                                      : (state.scaling == PageScaling.actualSize ? BoxFit.none : BoxFit.contain),
                                                ),
                                        ),
                                      ),
                                    ),

                                    // Paper Footer watermark/counter matching document.png
                                    Positioned(
                                      bottom: 8,
                                      left: 14,
                                      right: 14,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'FastPrint Studio',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          Text(
                                            'Page ${state.activePageIndex + 1} of ${state.totalPages}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Bottom Thumbnail Strip matching document.png
          if (state.totalPages > 1 && !hasError && !isPreparing)
            Container(
              height: 105,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: ListView.separated(
                controller: _thumbScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: state.totalPages,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = state.activePageIndex == index;
                  final isPageIncluded = state.selectedPageIndices.contains(index);

                  return InkWell(
                    onTap: () => widget.onSelectPage(index),
                    borderRadius: BorderRadius.circular(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.memory(
                              state.renderedPages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Page Number Indicator Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isPageIncluded ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isPageIncluded ? const Color(0xFF475569) : const Color(0xFFDC2626)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
