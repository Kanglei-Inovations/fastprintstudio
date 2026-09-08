import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/layout_item.dart';
import '../../core/models/photo_finish.dart';
import '../../core/models/print_layout.dart';
import '../../core/theme/app_colors.dart';
import 'pulsing_dot.dart';

class PrintPreviewCanvas extends StatefulWidget {
  final PrintLayout layout;
  final PhotoFinish? photoFinish;
  final bool showRulers;
  final bool showGrid;
  final bool showCutMarks;
  final String? selectedGroupId;
  final ValueChanged<String>? onSelectGroup;
  final VoidCallback? onClearAll;

  const PrintPreviewCanvas({
    super.key,
    required this.layout,
    this.photoFinish,
    this.showRulers = true,
    this.showGrid = false,
    this.showCutMarks = true,
    this.selectedGroupId,
    this.onSelectGroup,
    this.onClearAll,
  });

  @override
  State<PrintPreviewCanvas> createState() => _PrintPreviewCanvasState();
}

class _PrintPreviewCanvasState extends State<PrintPreviewCanvas> with TickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  double _zoomScale = 1.0;

  late final AnimationController _feedController;
  late final Animation<double> _slideYAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _inkSweepAnim;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _feedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _slideYAnim = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _feedController, curve: Curves.easeOutCubic),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _feedController, curve: Curves.easeOutCubic),
    );
    _inkSweepAnim = Tween<double>(begin: 0.0, end: 1.15).animate(
      CurvedAnimation(parent: _feedController, curve: Curves.easeInOut),
    );
    _feedController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PrintPreviewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout || oldWidget.photoFinish != widget.photoFinish) {
      _feedController.reset();
      _feedController.forward();
    }
  }

  @override
  void dispose() {
    _feedController.dispose();
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale * 1.25).clamp(0.4, 4.0);
      _transformController.value = Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale / 1.25).clamp(0.4, 4.0);
      _transformController.value = Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final paperW = layout.paperWidthMm;
    final paperH = layout.paperHeightMm;

    return Container(
      color: const Color(0xFFF1F5F9), // Clean light slate background matching PhotoUi.png
      child: Column(
        children: [
          // 1. Preview Canvas Toolbar (Header)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          Flexible(
                            child: Text(
                              '${layout.paperPreset.name} (${layout.orientation.displayName})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (layout.warningMessage != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                layout.warningMessage!,
                                style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paper: ${paperW.toStringAsFixed(1)} x ${paperH.toStringAsFixed(1)} mm  •  DPI: ${layout.dpi}  •  ${layout.orientation.displayName}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
                        onPressed: _zoomOut,
                        icon: const Icon(Icons.remove, size: 16, color: Color(0xFF475569)),
                        tooltip: 'Zoom Out',
                        visualDensity: VisualDensity.compact,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${(_zoomScale * 100).round()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        onPressed: _zoomIn,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF475569)),
                        tooltip: 'Zoom In',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetZoom,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Fit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ),
              ],
            ),
          ),

          // 2. Paper Sheet Canvas Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const overheadH = 95.0; // Allowance for printer tray bar, margins and breathing room
                const overheadW = 40.0;
                final availableW = math.max(60.0, constraints.maxWidth - overheadW);
                final availableH = math.max(60.0, constraints.maxHeight - overheadH);

                final scaleX = availableW / paperW;
                final scaleY = availableH / paperH;
                final baseScale = math.min(scaleX, scaleY).clamp(0.3, 5.0);

                final canvasW = paperW * baseScale;
                final canvasH = paperH * baseScale;

                return InteractiveViewer(
                  transformationController: _transformController,
                  boundaryMargin: const EdgeInsets.all(80),
                  minScale: 0.3,
                  maxScale: 4.0,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Studio Output Tray Ejection Slot
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155), width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: _feedController,
                            builder: (context, _) {
                              final isFeeding = _feedController.isAnimating;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isFeeding ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isFeeding ? const Color(0xFF38BDF8) : const Color(0xFF10B981))
                                              .withValues(alpha: 0.8),
                                          blurRadius: 5,
                                          spreadRadius: 1.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isFeeding
                                        ? 'PRINTING TO TRAY...'
                                        : 'OUTPUT TRAY • ${widget.layout.paperPreset.name.toUpperCase()} (${widget.layout.paperWidthMm.toInt()}×${widget.layout.paperHeightMm.toInt()} mm)',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isFeeding ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded,
                                    size: 13,
                                    color: isFeeding ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Realistic Physical Paper Ejection from Printer
                        AnimatedBuilder(
                          animation: _feedController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideYAnim.value),
                              child: Transform.scale(
                                scale: _scaleAnim.value,
                                child: child,
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            width: canvasW,
                            height: canvasH,
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3.5),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                              boxShadow: [
                                // Studio Floor Soft Ambient Shadow
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.09),
                                  blurRadius: 32,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 16),
                                ),
                                // Elevated Paper Depth Shadow
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 14,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 5),
                                ),
                                // Crisp Contact Edge Shadow
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 3,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: RepaintBoundary(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.0),
                                child: Stack(
                                children: [
                                  // Grid Lines (if enabled)
                                  if (widget.showGrid)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _PaperGridPainter(
                                          paperWidthMm: paperW,
                                          paperHeightMm: paperH,
                                          scale: baseScale,
                                        ),
                                      ),
                                    ),

                                  // Dashed Cutting Boundary & Section Separator with Scissor Icons
                                  if (widget.showCutMarks && layout.items.isNotEmpty)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _DashedCutLinePainter(
                                          layout: layout,
                                          items: layout.items,
                                          scale: baseScale,
                                        ),
                                      ),
                                    ),

                                  // Photos with gapless playback to prevent flicker & animated card selection indicator
                                  for (final item in layout.items)
                                    _buildLayoutItem(item, baseScale),

                                  // Real Photographic Paper Finish: Specular Sheen for Glossy / Diffuse for Matte
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: widget.photoFinish == PhotoFinish.matte
                                              ? LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.white.withValues(alpha: 0.05),
                                                    Colors.black.withValues(alpha: 0.02),
                                                  ],
                                                )
                                              : LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  stops: const [0.0, 0.35, 0.45, 0.70, 1.0],
                                                  colors: [
                                                    Colors.white.withValues(alpha: 0.16),
                                                    Colors.white.withValues(alpha: 0.04),
                                                    Colors.transparent,
                                                    Colors.white.withValues(alpha: 0.03),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Realistic Ink Head Print Sweep Line during Ejection
                                  AnimatedBuilder(
                                    animation: _feedController,
                                    builder: (context, _) {
                                      if (!_feedController.isAnimating) return const SizedBox.shrink();
                                      final sweepY = canvasH * _inkSweepAnim.value - 24;
                                      return Positioned(
                                        top: sweepY,
                                        left: 0,
                                        right: 0,
                                        height: 32,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  const Color(0xFF38BDF8).withValues(alpha: 0.32),
                                                  const Color(0xFF38BDF8).withValues(alpha: 0.08),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutItem(LayoutItem item, double baseScale) {
    final isSelected = widget.selectedGroupId != null &&
        item.groupId != null &&
        item.groupId == widget.selectedGroupId;

    final imageWidget = (item.rotationDegrees != 0)
        ? RotatedBox(
            quarterTurns: (item.rotationDegrees ~/ 90) % 4,
            child: Image.memory(
              item.imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          )
        : Image.memory(
            item.imageBytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );

    return Positioned(
      left: item.xMm * baseScale,
      top: item.yMm * baseScale,
      width: item.widthMm * baseScale,
      height: item.heightMm * baseScale,
      child: MouseRegion(
        cursor: item.groupId != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () {
            if (item.groupId != null && widget.onSelectGroup != null) {
              widget.onSelectGroup!(item.groupId!);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Photo with optional animated selection border & glow
              if (isSelected)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    final t = _pulseAnim.value;
                    final pulseColor = Color.lerp(
                      const Color(0xFF0284C7),
                      const Color(0xFF38BDF8),
                      t,
                    )!;

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: pulseColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: (0.45 + 0.45 * t).clamp(0.0, 1.0)),
                            blurRadius: 8.0 + (8.0 * t),
                            spreadRadius: 1.5 + (2.0 * t),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1.5),
                        child: child,
                      ),
                    );
                  },
                  child: imageWidget,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: imageWidget,
                ),

              // Animated Selection Badge on top of selected card
              if (isSelected)
                Positioned(
                  top: 5,
                  left: 5,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, _) {
                      final t = _pulseAnim.value;
                      final borderColor = Color.lerp(
                        const Color(0xFF0284C7),
                        const Color(0xFF38BDF8),
                        t,
                      )!;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: (0.4 + 0.4 * t).clamp(0.0, 1.0)),
                              blurRadius: 5.0 + 3.0 * t,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PulsingDot(
                              color: Color(0xFF38BDF8),
                              size: 6.0,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'SELECTED • ${item.label.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
        ),
      ),
    );
  }
}

class _DashedCutLinePainter extends CustomPainter {
  final PrintLayout layout;
  final List<LayoutItem> items;
  final double scale;

  _DashedCutLinePainter({
    required this.layout,
    required this.items,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    double minX = items.first.xMm * scale;
    double minY = items.first.yMm * scale;
    double maxX = items.first.rightMm * scale;
    double maxY = items.first.bottomMm * scale;

    for (final it in items) {
      minX = math.min(minX, it.xMm * scale);
      minY = math.min(minY, it.yMm * scale);
      maxX = math.max(maxX, it.rightMm * scale);
      maxY = math.max(maxY, it.bottomMm * scale);
    }

    final isL805 = layout.paperPreset.id.contains('l805') ||
        layout.serviceType.toLowerCase().contains('l805') ||
        layout.paperPreset.id == 'l805_tray';

    if (isL805) {
      // Epson L805: Remove all cut borders / lines (plastic PVC cards already precut)
      return;
    }

    final isXerox = layout.serviceType.toLowerCase().contains('xerox');

    if (isXerox) {
      // Xerox has no cut lines or borders
      return;
    }

    final isDragon = (layout.paperPreset.id == 'dragon_sheet_200x300' ||
        layout.serviceType.toLowerCase().contains('dragon'));

    if (isDragon) {
      if (!layout.showDragonCutLines) return;

      final redDottedPaint = Paint()
        ..color = const Color(0xFFEF4444) // Bright Red
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final centerX = (layout.paperWidthMm / 2.0) * scale;
      final leftX = minX;
      final rightX = maxX;

      // 1. Center vertical dotted cut line (down middle of Dragon Sheet between Front and Back columns)
      _drawDashedLine(
        canvas,
        Offset(centerX, minY),
        Offset(centerX, maxY),
        redDottedPaint,
        dashWidth: 2.5,
        dashSpace: 2.5,
      );
      _drawScissorText(canvas, Offset(centerX - 6, minY - 14), color: const Color(0xFFEF4444));
      _drawScissorText(canvas, Offset(centerX - 6, maxY + 2), color: const Color(0xFFEF4444));

      // 2. Left vertical dotted cut line (left of cards)
      _drawDashedLine(
        canvas,
        Offset(leftX, minY),
        Offset(leftX, maxY),
        redDottedPaint,
        dashWidth: 2.5,
        dashSpace: 2.5,
      );
      _drawScissorText(canvas, Offset(leftX - 14, minY - 6), color: const Color(0xFFEF4444));

      // 3. Right vertical dotted cut line (right of cards)
      _drawDashedLine(
        canvas,
        Offset(rightX, minY),
        Offset(rightX, maxY),
        redDottedPaint,
        dashWidth: 2.5,
        dashSpace: 2.5,
      );
      _drawScissorText(canvas, Offset(rightX + 2, minY - 6), color: const Color(0xFFEF4444));

      // 4. Horizontal cut lines across each row top and bottom
      final rowYs = <double>{};
      for (final it in items) {
        rowYs.add(((it.yMm * scale) * 10).round() / 10.0);
        rowYs.add(((it.bottomMm * scale) * 10).round() / 10.0);
      }
      for (final y in rowYs) {
        _drawDashedLine(
          canvas,
          Offset(leftX, y),
          Offset(rightX, y),
          redDottedPaint,
          dashWidth: 2.5,
          dashSpace: 2.5,
        );
      }
      // Dragon Sheet has no grey outer border
      return;
    }

    final isLamination = (layout.paperPreset.id == '4r' ||
        layout.paperPreset.id == 'four_r' ||
        layout.paperPreset.id == 'a4' ||
        layout.serviceType.toLowerCase().contains('lamination') ||
        layout.serviceType.toLowerCase().contains('aadhaar') ||
        layout.serviceType.toLowerCase().contains('id card'));

    if (isLamination) {
      if (layout.showDragonCutLines) {
        final redDottedPaint = Paint()
          ..color = const Color(0xFFEF4444) // Bright Red
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final pairedItems = <LayoutItem>{};

        // Check for foldable cards (stacked Front normal and Back 180° rotated)
        for (int i = 0; i < items.length; i++) {
          final backItem = items[i];
          if (backItem.rotationDegrees == 180) {
            for (int j = 0; j < items.length; j++) {
              if (i == j) continue;
              final frontItem = items[j];
              if ((frontItem.xMm - backItem.xMm).abs() < 5.0 &&
                  frontItem.yMm < backItem.yMm &&
                  (backItem.yMm - frontItem.bottomMm).abs() < 10.0) {
                pairedItems.add(frontItem);
                pairedItems.add(backItem);

                final left = math.min(frontItem.xMm, backItem.xMm) * scale;
                final right = math.max(frontItem.rightMm, backItem.rightMm) * scale;
                final top = frontItem.yMm * scale;
                final bottom = backItem.bottomMm * scale;

                // 1. Top horizontal cut line
                _drawDashedLine(canvas, Offset(left, top), Offset(right, top), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
                _drawScissorText(canvas, Offset(left - 14, top - 6), color: const Color(0xFFEF4444));

                // 2. Bottom horizontal cut line
                _drawDashedLine(canvas, Offset(left, bottom), Offset(right, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
                _drawScissorText(canvas, Offset(left - 14, bottom - 6), color: const Color(0xFFEF4444));

                // 3. Left vertical cut line
                _drawDashedLine(canvas, Offset(left, top), Offset(left, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);

                // 4. Right vertical cut line
                _drawDashedLine(canvas, Offset(right, top), Offset(right, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
                _drawScissorText(canvas, Offset(right + 2, top - 6), color: const Color(0xFFEF4444));

                // Middle: NO CUT LINE (only amber fold line)
                final foldY = (frontItem.bottomMm + backItem.yMm) / 2.0 * scale;
                _drawFoldLine(canvas, left, right, foldY);
                break;
              }
            }
          }
        }

        // Standalone or non-stacked items on Lamination
        for (final item in items) {
          if (pairedItems.contains(item)) continue;

          final left = item.xMm * scale;
          final right = item.rightMm * scale;
          final top = item.yMm * scale;
          final bottom = item.bottomMm * scale;

          _drawDashedLine(canvas, Offset(left, top), Offset(right, top), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
          _drawDashedLine(canvas, Offset(left, bottom), Offset(right, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
          _drawDashedLine(canvas, Offset(left, top), Offset(left, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
          _drawDashedLine(canvas, Offset(right, top), Offset(right, bottom), redDottedPaint, dashWidth: 2.5, dashSpace: 2.5);
          _drawScissorText(canvas, Offset(left - 14, top - 6), color: const Color(0xFFEF4444));
          _drawScissorText(canvas, Offset(right + 2, top - 6), color: const Color(0xFFEF4444));
        }
      }
      // Lamination has no grey outer border
      return;
    }
  }

  void _drawFoldLine(Canvas canvas, double left, double right, double foldY) {
    final foldPaint = Paint()
      ..color = const Color(0xFFF59E0B) // Amber fold line
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(left, foldY), Offset(right, foldY), foldPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '── FOLD LINE ──',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textX = (left + right - textPainter.width) / 2;
    final textY = foldY - (textPainter.height / 2);

    final bgRect = Rect.fromLTWH(
      textX - 4,
      textY - 1,
      textPainter.width + 8,
      textPainter.height + 2,
    );
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), bgPaint);

    textPainter.paint(canvas, Offset(textX, textY));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashWidth = 4.0,
    double dashSpace = 3.0,
  }) {
    double dx = p2.dx - p1.dx;
    double dy = p2.dy - p1.dy;
    double distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;
    double unitX = dx / distance;
    double unitY = dy / distance;

    double current = 0.0;
    while (current < distance) {
      double len = math.min(dashWidth, distance - current);
      canvas.drawLine(
        Offset(p1.dx + unitX * current, p1.dy + unitY * current),
        Offset(p1.dx + unitX * (current + len), p1.dy + unitY * (current + len)),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  void _drawScissorText(Canvas canvas, Offset offset, {Color color = const Color(0xFF64748B)}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '✂',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'Segoe UI Emoji',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DashedCutLinePainter oldDelegate) => true;
}

class _PaperGridPainter extends CustomPainter {
  final double paperWidthMm;
  final double paperHeightMm;
  final double scale;

  _PaperGridPainter({
    required this.paperWidthMm,
    required this.paperHeightMm,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.canvasGridLine
      ..strokeWidth = 0.5;

    const gridMm = 10.0;
    final gridPx = gridMm * scale;

    for (double x = gridPx; x < size.width; x += gridPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = gridPx; y < size.height; y += gridPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGridPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.paperWidthMm != paperWidthMm ||
        oldDelegate.paperHeightMm != paperHeightMm;
  }
}
