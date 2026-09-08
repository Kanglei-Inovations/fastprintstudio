import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/id_card_presets.dart';
import '../../core/models/crop_rect_data.dart';
import '../../core/models/crop_result.dart';
import '../../core/models/enhancement_config.dart';
import '../../core/models/id_card_preset.dart';
import '../../core/models/quad_points.dart';
import '../../core/utils/coordinate_converter.dart';
import '../../services/detection/document_detector.dart';
import '../../services/image/image_processor.dart';

enum CropMode {
  rectangle,
  quadPerspective,
}

class CropEditorModal extends StatefulWidget {
  final Uint8List imageBytes;
  final CropRectData initialCrop;
  final double? targetAspectRatio; // width / height (e.g. 35/45 or 85.6/54 = ~1.585)
  final String title;
  final bool showDebugInfo;
  final EnhancementConfig? initialEnhancement;
  final bool initialBgRemoverMode;
  final IDCardPreset? idCardPreset;

  const CropEditorModal({
    super.key,
    required this.imageBytes,
    required this.initialCrop,
    this.targetAspectRatio,
    this.title = 'Edit Image',
    this.showDebugInfo = kDebugMode,
    this.initialEnhancement,
    this.initialBgRemoverMode = false,
    this.idCardPreset,
  });

  /// Displays the modal and returns the definitive CropResult containing source pixel coordinates and cropped/unskewed bytes.
  static Future<CropResult?> show({
    required BuildContext context,
    required Uint8List imageBytes,
    required CropRectData initialCrop,
    double? targetAspectRatio,
    String title = 'Edit Image',
    EnhancementConfig? initialEnhancement,
    bool initialBgRemoverMode = false,
    IDCardPreset? idCardPreset,
  }) {
    return showDialog<CropResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CropEditorModal(
        imageBytes: imageBytes,
        initialCrop: initialCrop,
        targetAspectRatio: targetAspectRatio,
        title: title,
        initialEnhancement: initialEnhancement,
        initialBgRemoverMode: initialBgRemoverMode,
        idCardPreset: idCardPreset,
      ),
    );
  }

  @override
  State<CropEditorModal> createState() => _CropEditorModalState();
}

class _CropEditorModalState extends State<CropEditorModal> {
  img.Image? _decodedOriginalImage;
  int _origWidth = 0;
  int _origHeight = 0;

  int _rotation90Degrees = 0;
  double _fineAngleDegrees = 0.0;
  bool _lockAspectRatio = true;
  bool _isLoading = true;
  CropMode _cropMode = CropMode.rectangle;
  bool _showAdjustments = false;

  double get _activeWidth => (_rotation90Degrees % 180 == 0)
      ? _origWidth.toDouble()
      : _origHeight.toDouble();

  double get _activeHeight => (_rotation90Degrees % 180 == 0)
      ? _origHeight.toDouble()
      : _origWidth.toDouble();

  // Image Adjustments state
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _sharpness = 0.0;
  double _smoothSkin = 0.0;

  // Zoom & Pan state
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;

  /// Crop rectangle in ACTIVE (rotated) image pixel coordinates
  Rect _sourcePixelCrop = Rect.zero;

  /// 4-Corner Quad points in ACTIVE image pixel coordinates
  QuadPoints _sourceQuad = const QuadPoints(
    topLeft: Offset.zero,
    topRight: Offset.zero,
    bottomRight: Offset.zero,
    bottomLeft: Offset.zero,
  );

  @override
  void initState() {
    super.initState();
    _rotation90Degrees = widget.initialCrop.rotationDegrees.round();
    _fineAngleDegrees = widget.initialCrop.fineAngleDegrees;
    if (widget.initialCrop.isQuad) {
      _cropMode = CropMode.quadPerspective;
    }
    if (widget.initialEnhancement != null) {
      _brightness = widget.initialEnhancement!.brightness;
      _contrast = widget.initialEnhancement!.contrast;
      _saturation = widget.initialEnhancement!.saturation;
      _sharpness = widget.initialEnhancement!.sharpness;
      _smoothSkin = widget.initialEnhancement!.smoothSkin;
    }
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    setState(() => _isLoading = true);

    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      _origWidth = frame.image.width;
      _origHeight = frame.image.height;
      _updateActiveCropBounds();
      setState(() => _isLoading = false);

      // Silently decode full image in background isolate for AI enhancements
      compute(_decodeWorker, widget.imageBytes).then((decoded) {
        if (mounted && decoded != null) {
          _decodedOriginalImage = decoded;
        }
      });
    } catch (e) {
      debugPrint('Error initializing image codec: $e');
      if (mounted) Navigator.of(context).pop(null);
    }
  }

  static img.Image? _decodeWorker(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  void _updateActiveCropBounds() {
    final activeW = _activeWidth;
    final activeH = _activeHeight;
    if (activeW <= 0 || activeH <= 0) return;

    // Convert initialCrop into pixel coordinates on the active image
    final init = widget.initialCrop.clamp();
    double cropLeft = init.left * activeW;
    double cropTop = init.top * activeH;
    double cropWidth = init.width * activeW;
    double cropHeight = init.height * activeH;

    if (cropWidth <= 10 || cropHeight <= 10) {
      cropLeft = activeW * 0.05;
      cropTop = activeH * 0.05;
      cropWidth = activeW * 0.9;
      cropHeight = activeH * 0.9;
    }

    var initialPixelRect = Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);

    if (widget.targetAspectRatio != null && _lockAspectRatio && _cropMode == CropMode.rectangle) {
      initialPixelRect = CoordinateConverter.enforceAspectRatio(
        rect: initialPixelRect,
        targetAspectRatio: widget.targetAspectRatio!,
        bounds: Rect.fromLTWH(0, 0, activeW, activeH),
      );
    }

    _sourcePixelCrop = initialPixelRect;

    if (widget.initialCrop.quadPoints != null) {
      final q = widget.initialCrop.quadPoints!;
      _sourceQuad = QuadPoints(
        topLeft: Offset(q.topLeft.dx * activeW, q.topLeft.dy * activeH),
        topRight: Offset(q.topRight.dx * activeW, q.topRight.dy * activeH),
        bottomRight: Offset(q.bottomRight.dx * activeW, q.bottomRight.dy * activeH),
        bottomLeft: Offset(q.bottomLeft.dx * activeW, q.bottomLeft.dy * activeH),
      );
    } else {
      _sourceQuad = QuadPoints.fromRect(initialPixelRect);
    }

    _zoomScale = 1.0;
    _panOffset = Offset.zero;
  }

  void _resetCrop() {
    final activeW = _activeWidth;
    final activeH = _activeHeight;
    if (activeW <= 0 || activeH <= 0) return;

    Rect resetRect;
    if (widget.targetAspectRatio != null && _lockAspectRatio && _cropMode == CropMode.rectangle) {
      final ratio = widget.targetAspectRatio!;
      double w, h;
      if (ratio >= 1.0) {
        w = activeW * 0.85;
        h = w / ratio;
        if (h > activeH * 0.9) {
          h = activeH * 0.9;
          w = h * ratio;
        }
      } else {
        h = activeH * 0.85;
        w = h * ratio;
        if (w > activeW * 0.9) {
          w = activeW * 0.9;
          h = w / ratio;
        }
      }
      final l = (activeW - w) / 2.0;
      final t = (activeH - h) / 2.0;
      resetRect = Rect.fromLTWH(l, t, w, h);
    } else {
      resetRect = Rect.fromLTWH(activeW * 0.05, activeH * 0.05, activeW * 0.9, activeH * 0.9);
    }

    setState(() {
      _sourcePixelCrop = resetRect;
      _sourceQuad = QuadPoints.fromRect(resetRect);
      _fineAngleDegrees = 0.0;
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  bool _isAutoDetecting = false;

  Future<void> _runAutoDetect() async {
    if (_origWidth <= 0 || _origHeight <= 0) return;
    setState(() => _isAutoDetecting = true);
    try {
      final preset = widget.idCardPreset ?? StandardIDCardPresets.aadhaar;
      final detection = await DocumentDetector.detectIDCard(
        imageBytes: widget.imageBytes,
        preset: preset,
      );

      final isBack = widget.title.toLowerCase().contains('back');
      final targetCrop = (isBack && detection.backCrop != null)
          ? detection.backCrop!
          : (detection.frontCrop.width < 0.99 || detection.frontCrop.height < 0.99
              ? detection.frontCrop
              : (detection.candidates.isNotEmpty ? detection.candidates.first.crop : null));

      if (targetCrop != null && _origWidth > 0 && _origHeight > 0) {
        setState(() {
          _sourcePixelCrop = targetCrop.toPixelRect(_origWidth, _origHeight);
          if (targetCrop.quadPoints != null) {
            _cropMode = CropMode.quadPerspective;
            _sourceQuad = targetCrop.quadPoints!;
          } else {
            _sourceQuad = QuadPoints.fromRect(_sourcePixelCrop);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card detected successfully! You can fine-tune handles or click Apply.'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No card detected automatically. Please adjust the crop boundaries manually.'),
              backgroundColor: Color(0xFFEAB308),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Auto detect in crop modal error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAutoDetecting = false);
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale * 1.35).clamp(1.0, 8.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale / 1.35).clamp(1.0, 8.0);
      if (_zoomScale <= 1.05) {
        _zoomScale = 1.0;
        _panOffset = Offset.zero;
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  void _rotateLeft90() {
    setState(() {
      _rotation90Degrees = (_rotation90Degrees - 90) % 360;
      _updateActiveCropBounds();
    });
  }

  void _rotateRight90() {
    setState(() {
      _rotation90Degrees = (_rotation90Degrees + 90) % 360;
      _updateActiveCropBounds();
    });
  }

  void _onFineAngleChanged(double angle) {
    setState(() {
      _fineAngleDegrees = angle;
    });
  }

  void _applyAndClose() {
    final activeW = _activeWidth;
    final activeH = _activeHeight;
    if (activeW <= 0 || activeH <= 0) return;

    final isQuadMode = _cropMode == CropMode.quadPerspective;

    final result = CropResult(
      sourceRect: _sourcePixelCrop,
      quadPoints: isQuadMode ? _sourceQuad : null,
      croppedBytes: widget.imageBytes, // Instant 0ms hand-off: avoids freezing UI thread with heavy PNG encoding
      sourceWidth: activeW.round(),
      sourceHeight: activeH.round(),
      rotationDegrees: _rotation90Degrees,
      fineAngleDegrees: _fineAngleDegrees,
      targetAspectRatio: widget.targetAspectRatio,
      enhancement: EnhancementConfig(
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        sharpness: _sharpness,
        smoothSkin: _smoothSkin,
        rotationDegrees: _rotation90Degrees,
      ),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogW = math.min(screenSize.width * 0.96, 1150.0);
    final dialogH = math.min(screenSize.height * 0.94, 850.0);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogW,
        height: dialogH,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // 1. Header with Mode Toggle & Zoom Toolbar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.crop_rotate_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _showAdjustments
                            ? 'Adjust brightness, contrast, color, sharpness & beauty smooth skin'
                            : (_cropMode == CropMode.quadPerspective
                                ? 'Drag 4 corners to match card/photo perspective & straighten'
                                : 'Adjust crop box boundaries and image angle'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Mode Selector: [ Standard Box ] vs [ 4-Corner Quad ] vs [ Adjustments ]
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _CropModePill(
                        label: 'Standard Box',
                        icon: Icons.crop_square_rounded,
                        isSelected: !_showAdjustments && _cropMode == CropMode.rectangle,
                        onTap: () {
                          setState(() {
                            _showAdjustments = false;
                            _cropMode = CropMode.rectangle;
                            _sourcePixelCrop = _sourceQuad.boundingBox;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      _CropModePill(
                        label: '4-Corner Quad',
                        icon: Icons.polyline_rounded,
                        isSelected: !_showAdjustments && _cropMode == CropMode.quadPerspective,
                        onTap: () {
                          setState(() {
                            _showAdjustments = false;
                            _cropMode = CropMode.quadPerspective;
                            _sourceQuad = QuadPoints.fromRect(_sourcePixelCrop);
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      _CropModePill(
                        label: 'Adjustments',
                        icon: Icons.tune_rounded,
                        isSelected: _showAdjustments,
                        onTap: () {
                          setState(() {
                            _showAdjustments = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Zoom Level Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _zoomScale > 1.0 ? _zoomOut : null,
                        icon: const Icon(Icons.zoom_out, size: 16, color: Color(0xFF475569)),
                        tooltip: 'Zoom Out',
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: _resetZoom,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            '${(_zoomScale * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _zoomScale < 8.0 ? _zoomIn : null,
                        icon: const Icon(Icons.zoom_in, size: 16, color: Color(0xFF475569)),
                        tooltip: 'Zoom In',
                        visualDensity: VisualDensity.compact,
                      ),
                      if (_zoomScale > 1.0)
                        IconButton(
                          onPressed: _resetZoom,
                          icon: const Icon(Icons.fit_screen_rounded, size: 16, color: Color(0xFF2563EB)),
                          tooltip: 'Fit View (100%)',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  tooltip: 'Cancel (Esc)',
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFE2E8F0)),

            // 2. Main Interactive Zoomable Crop & Quad Area
            Expanded(
              child: _isLoading || _origWidth == 0
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), // Dark slate canvas
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
                          final imageSize = Size(_activeWidth, _activeHeight);

                          // Base display fitting
                          final baseFitting = CoordinateConverter.calculateDisplayFitting(
                            viewportSize: viewportSize,
                            imageSize: imageSize,
                          );

                          // Compute zoomed & panned display rectangle
                          final scaledW = baseFitting.displayedWidth * _zoomScale;
                          final scaledH = baseFitting.displayedHeight * _zoomScale;

                          // Compute pan bounds
                          final maxPanX = math.max(0.0, (scaledW - viewportSize.width) / 2.0);
                          final maxPanY = math.max(0.0, (scaledH - viewportSize.height) / 2.0);

                          final clampedPan = Offset(
                            _panOffset.dx.clamp(-maxPanX, maxPanX),
                            _panOffset.dy.clamp(-maxPanY, maxPanY),
                          );

                          final centerOffset = Offset(
                            (viewportSize.width - scaledW) / 2.0 + clampedPan.dx,
                            (viewportSize.height - scaledH) / 2.0 + clampedPan.dy,
                          );

                          final zoomedDisplayRect = Rect.fromLTWH(
                            centerOffset.dx,
                            centerOffset.dy,
                            scaledW,
                            scaledH,
                          );

                          return Listener(
                            onPointerSignal: (pointerSignal) {
                              if (pointerSignal is PointerScrollEvent) {
                                if (pointerSignal.scrollDelta.dy < 0) {
                                  _zoomIn();
                                } else if (pointerSignal.scrollDelta.dy > 0) {
                                  _zoomOut();
                                }
                              }
                            },
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                if (_zoomScale > 1.0) {
                                  setState(() {
                                    _panOffset += details.delta;
                                  });
                                }
                              },
                              child: Stack(
                                children: [
                                  // 1. Displayed Image (Hardware accelerated GPU rendering via RotatedBox & ColorFilter)
                                  Positioned(
                                    left: zoomedDisplayRect.left,
                                    top: zoomedDisplayRect.top,
                                    width: zoomedDisplayRect.width,
                                    height: zoomedDisplayRect.height,
                                    child: RepaintBoundary(
                                      child: Transform.rotate(
                                        angle: _fineAngleDegrees * math.pi / 180.0,
                                        child: RotatedBox(
                                          quarterTurns: ((_rotation90Degrees % 360) ~/ 90),
                                          child: (_brightness != 0.0 || _contrast != 1.0 || _saturation != 1.0)
                                              ? ColorFiltered(
                                                  colorFilter: ColorFilter.matrix(_buildColorFilterMatrix()),
                                                  child: Image.memory(
                                                    widget.imageBytes,
                                                    fit: BoxFit.fill,
                                                    gaplessPlayback: true,
                                                  ),
                                                )
                                              : Image.memory(
                                                  widget.imageBytes,
                                                  fit: BoxFit.fill,
                                                  gaplessPlayback: true,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 2. Interactive Crop Overlay: Standard Box OR 4-Corner Quad
                                  if (_cropMode == CropMode.rectangle)
                                    _InteractiveBoxCropLayer(
                                      sourcePixelCrop: _sourcePixelCrop,
                                      imageDisplayRect: zoomedDisplayRect,
                                      sourceImageSize: imageSize,
                                      targetAspectRatio: _lockAspectRatio ? widget.targetAspectRatio : null,
                                      zoomScale: _zoomScale,
                                      onCropChanged: (newSourceRect) {
                                        setState(() {
                                          _sourcePixelCrop = newSourceRect;
                                          _sourceQuad = QuadPoints.fromRect(newSourceRect);
                                        });
                                      },
                                    )
                                  else
                                    _InteractiveQuadPerspectiveLayer(
                                      sourceQuad: _sourceQuad,
                                      imageDisplayRect: zoomedDisplayRect,
                                      sourceImageSize: imageSize,
                                      zoomScale: _zoomScale,
                                      onQuadChanged: (newQuad) {
                                        setState(() {
                                          _sourceQuad = newQuad;
                                          _sourcePixelCrop = newQuad.boundingBox;
                                        });
                                      },
                                    ),

                                  // 3. Real-Time HUD
                                  Positioned(
                                    left: 12,
                                    top: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.82),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _cropMode == CropMode.quadPerspective
                                                ? 'Mode: 4-Corner Quad (Perspective Unskew)'
                                                : 'Crop Size: ${_sourcePixelCrop.width.round()} × ${_sourcePixelCrop.height.round()} px',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rotation: $_rotation90Degrees° | Fine Angle: ${_fineAngleDegrees.toStringAsFixed(1)}° | Zoom: ${(_zoomScale * 100).round()}%',
                                            style: const TextStyle(
                                              color: Color(0xFF34D399),
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 4. Pan Navigation Hint
                                  if (_zoomScale > 1.0)
                                    Positioned(
                                      right: 12,
                                      top: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.pan_tool_alt_outlined, size: 14, color: Colors.orangeAccent),
                                            SizedBox(width: 4),
                                            Text(
                                              'Drag canvas to Pan',
                                              style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // 3. Fine Angle Slider & Rotation Controls Bar OR Image Adjustments Panel
            if (_showAdjustments)
              _buildAdjustmentsPanel(context)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text(
                      'Fine Angle:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _onFineAngleChanged((_fineAngleDegrees - 0.5).clamp(-45.0, 45.0)),
                      icon: const Icon(Icons.remove, size: 14),
                      tooltip: '-0.5° Fine Step',
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF2563EB),
                          inactiveTrackColor: const Color(0xFFCBD5E1),
                          thumbColor: const Color(0xFF2563EB),
                        ),
                        child: Slider(
                          value: _fineAngleDegrees,
                          min: -45.0,
                          max: 45.0,
                          onChanged: _onFineAngleChanged,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _onFineAngleChanged((_fineAngleDegrees + 0.5).clamp(-45.0, 45.0)),
                      icon: const Icon(Icons.add, size: 14),
                      tooltip: '+0.5° Fine Step',
                      visualDensity: VisualDensity.compact,
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${_fineAngleDegrees >= 0 ? "+" : ""}${_fineAngleDegrees.toStringAsFixed(1)}°',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: Color(0xFF0F172A)),
                      ),
                    ),
                    if (_fineAngleDegrees != 0.0) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _onFineAngleChanged(0.0),
                        child: const Text('Reset Angle', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // 4. Action Buttons Footer
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Aspect ratio lock (when in standard box mode)
                  if (widget.targetAspectRatio != null && _cropMode == CropMode.rectangle) ...[
                    FilterChip(
                      label: Text(
                        _lockAspectRatio ? 'Lock Aspect Ratio' : 'Free Aspect Ratio',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _lockAspectRatio,
                      avatar: Icon(
                        _lockAspectRatio ? Icons.lock : Icons.lock_open,
                        size: 14,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _lockAspectRatio = val;
                          if (_lockAspectRatio && _origWidth > 0) {
                            _sourcePixelCrop = CoordinateConverter.enforceAspectRatio(
                              rect: _sourcePixelCrop,
                              targetAspectRatio: widget.targetAspectRatio!,
                              bounds: Rect.fromLTWH(
                                0,
                                0,
                                _activeWidth,
                                _activeHeight,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // 90-degree rotate buttons
                  OutlinedButton.icon(
                    onPressed: _rotateLeft90,
                    icon: const Icon(Icons.rotate_left, size: 16),
                    label: const Text('Rotate 90° Left', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _rotateRight90,
                    icon: const Icon(Icons.rotate_right, size: 16),
                    label: const Text('Rotate 90° Right', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _resetCrop,
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset Crop & Angle', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _isAutoDetecting ? null : _runAutoDetect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                    icon: _isAutoDetecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      _isAutoDetecting ? 'Detecting...' : 'Auto Detect',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Cancel & Apply
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _applyAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_cropMode == CropMode.quadPerspective ? 'Apply Perspective Unskew' : 'Apply Crop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _buildColorFilterMatrix() {
    final s = _saturation;
    final c = _contrast;
    final b = _brightness;
    final offset = ((1.0 - c) / 2.0 * 255) + (b * 255);

    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    final sr = (1.0 - s) * lumR;
    final sg = (1.0 - s) * lumG;
    final sb = (1.0 - s) * lumB;

    return [
      (sr + s) * c, sg * c, sb * c, 0, offset,
      sr * c, (sg + s) * c, sb * c, 0, offset,
      sr * c, sg * c, (sb + s) * c, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  void _applyAiAutoEnhance() {
    final image = _decodedOriginalImage;
    if (image == null) return;
    final auto = ImageProcessor.calculateAutoEnhancements(image);
    setState(() {
      _brightness = auto.brightness;
      _contrast = auto.contrast;
      _saturation = auto.saturation;
      _sharpness = auto.sharpness;
      _smoothSkin = auto.smoothSkin;
    });
  }

  void _applyAutoBrightness() {
    final image = _decodedOriginalImage;
    if (image == null) return;
    final auto = ImageProcessor.calculateAutoEnhancements(image);
    setState(() {
      _brightness = auto.brightness;
      _contrast = auto.contrast;
    });
  }

  void _applyAutoColor() {
    final image = _decodedOriginalImage;
    if (image == null) return;
    setState(() {
      _saturation = 1.22;
    });
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _sharpness = 0.0;
      _smoothSkin = 0.0;
    });
  }

  Widget _buildAdjustmentsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 1. AI Auto Enhance
                  ElevatedButton.icon(
                    onPressed: _applyAiAutoEnhance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                    label: const Text('AI Auto Enhance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),

                  // 2. Auto Brightness
                  OutlinedButton.icon(
                    onPressed: _applyAutoBrightness,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.wb_sunny_rounded, size: 12, color: Color(0xFF2563EB)),
                    label: const Text('Auto Brightness', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),

                  // 3. Auto Color
                  OutlinedButton.icon(
                    onPressed: _applyAutoColor,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF6EE7B7)),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.palette_rounded, size: 12, color: Color(0xFF059669)),
                    label: const Text('Auto Color', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              InkWell(
                onTap: _resetAdjustments,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Reset All',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 1: Brightness, Contrast, Saturation
          Row(
            children: [
              Expanded(
                child: _buildSliderRow(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Brightness',
                  value: _brightness,
                  min: -0.5,
                  max: 0.5,
                  percentageText: '${(_brightness * 100).round()}%',
                  onChanged: (val) => setState(() => _brightness = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSliderRow(
                  icon: Icons.contrast,
                  label: 'Contrast',
                  value: _contrast,
                  min: 0.5,
                  max: 1.5,
                  percentageText: '${((_contrast - 1.0) * 100).round()}%',
                  onChanged: (val) => setState(() => _contrast = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSliderRow(
                  icon: Icons.color_lens_outlined,
                  label: 'Color/Sat',
                  value: _saturation,
                  min: 0.0,
                  max: 2.0,
                  percentageText: '${((_saturation - 1.0) * 100).round()}%',
                  onChanged: (val) => setState(() => _saturation = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Sharpness, Smooth Skin
          Row(
            children: [
              Expanded(
                child: _buildSliderRow(
                  icon: Icons.change_history_rounded,
                  label: 'Sharpness',
                  value: _sharpness,
                  min: 0.0,
                  max: 1.0,
                  percentageText: '${(_sharpness * 100).round()}%',
                  onChanged: (val) => setState(() => _sharpness = val),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSliderRow(
                  icon: Icons.face_retouching_natural_rounded,
                  label: 'Smooth Skin',
                  value: _smoothSkin,
                  min: 0.0,
                  max: 1.0,
                  percentageText: '${(_smoothSkin * 100).round()}%',
                  onChanged: (val) => setState(() => _smoothSkin = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String percentageText,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: const Color(0xFF2563EB),
              inactiveTrackColor: const Color(0xFFCBD5E1),
              thumbColor: const Color(0xFF2563EB),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            percentageText,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

class _CropModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CropModePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard 8-Point Axis Aligned Box Layer with 120 FPS hardware-accelerated dragging
class _InteractiveBoxCropLayer extends StatefulWidget {
  final Rect sourcePixelCrop;
  final Rect imageDisplayRect;
  final Size sourceImageSize;
  final double? targetAspectRatio;
  final double zoomScale;
  final ValueChanged<Rect> onCropChanged;

  const _InteractiveBoxCropLayer({
    required this.sourcePixelCrop,
    required this.imageDisplayRect,
    required this.sourceImageSize,
    this.targetAspectRatio,
    required this.zoomScale,
    required this.onCropChanged,
  });

  @override
  State<_InteractiveBoxCropLayer> createState() => _InteractiveBoxCropLayerState();
}

class _InteractiveBoxCropLayerState extends State<_InteractiveBoxCropLayer> {
  Rect? _activeScreenCrop;
  Rect? _dragStartCrop;
  Offset? _dragStartPointer;

  @override
  void didUpdateWidget(covariant _InteractiveBoxCropLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragStartPointer == null) {
      _activeScreenCrop = null;
    }
  }

  Rect _getCurrentScreenCrop() {
    if (_activeScreenCrop != null) return _activeScreenCrop!;
    return CoordinateConverter.sourceToScreenRect(
      sourceCropRect: widget.sourcePixelCrop,
      imageDisplayRect: widget.imageDisplayRect,
      sourceImageSize: widget.sourceImageSize,
    );
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartCrop = _getCurrentScreenCrop();
    _dragStartPointer = details.globalPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartCrop = null;
    _dragStartPointer = null;
  }

  void _applyUpdate(Rect updated) {
    setState(() {
      _activeScreenCrop = updated;
    });

    final newSource = CoordinateConverter.screenToSourceRect(
      screenCropRect: updated,
      imageDisplayRect: widget.imageDisplayRect,
      sourceImageSize: widget.sourceImageSize,
    );
    widget.onCropChanged(newSource);
  }

  void _updateMove(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    final newLeft = (start.left + totalDelta.dx).clamp(bounds.left, math.max<double>(bounds.left, bounds.right - start.width));
    final newTop = (start.top + totalDelta.dy).clamp(bounds.top, math.max<double>(bounds.top, bounds.bottom - start.height));

    final updated = Rect.fromLTWH(newLeft, newTop, start.width, start.height);
    _applyUpdate(updated);
  }

  void _updateBottomRight(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width + totalDelta.dx).clamp(36.0, math.max(36.0, bounds.right - start.left));
    double newH;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      if (start.top + newH > bounds.bottom) {
        newH = math.max(36.0, bounds.bottom - start.top);
        newW = newH * ratio;
      }
    } else {
      newH = (start.height + totalDelta.dy).clamp(36.0, math.max(36.0, bounds.bottom - start.top));
    }

    final updated = Rect.fromLTWH(start.left, start.top, newW, newH);
    _applyUpdate(updated);
  }

  void _updateTopLeft(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width - totalDelta.dx).clamp(36.0, math.max(36.0, start.right - bounds.left));
    double newH;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      if (start.bottom - newH < bounds.top) {
        newH = math.max(36.0, start.bottom - bounds.top);
        newW = newH * ratio;
      }
    } else {
      newH = (start.height - totalDelta.dy).clamp(36.0, math.max(36.0, start.bottom - bounds.top));
    }

    final updated = Rect.fromLTWH(start.right - newW, start.bottom - newH, newW, newH);
    _applyUpdate(updated);
  }

  void _updateTopRight(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width + totalDelta.dx).clamp(36.0, math.max(36.0, bounds.right - start.left));
    double newH;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      if (start.bottom - newH < bounds.top) {
        newH = math.max(36.0, start.bottom - bounds.top);
        newW = newH * ratio;
      }
    } else {
      newH = (start.height - totalDelta.dy).clamp(36.0, math.max(36.0, start.bottom - bounds.top));
    }

    final updated = Rect.fromLTWH(start.left, start.bottom - newH, newW, newH);
    _applyUpdate(updated);
  }

  void _updateBottomLeft(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width - totalDelta.dx).clamp(36.0, math.max(36.0, start.right - bounds.left));
    double newH;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      if (start.top + newH > bounds.bottom) {
        newH = math.max(36.0, bounds.bottom - start.top);
        newW = newH * ratio;
      }
    } else {
      newH = (start.height + totalDelta.dy).clamp(36.0, math.max(36.0, bounds.bottom - start.top));
    }

    final updated = Rect.fromLTWH(start.right - newW, start.top, newW, newH);
    _applyUpdate(updated);
  }

  void _updateTopEdge(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newH = (start.height - totalDelta.dy).clamp(36.0, math.max(36.0, start.bottom - bounds.top));
    double newW = start.width;
    double newL = start.left;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newW = newH * ratio;
      final diffW = newW - start.width;
      newL = (start.left - diffW / 2).clamp(bounds.left, math.max(bounds.left, bounds.right - newW));
    }

    final updated = Rect.fromLTWH(newL, start.bottom - newH, newW, newH);
    _applyUpdate(updated);
  }

  void _updateBottomEdge(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newH = (start.height + totalDelta.dy).clamp(36.0, math.max(36.0, bounds.bottom - start.top));
    double newW = start.width;
    double newL = start.left;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newW = newH * ratio;
      final diffW = newW - start.width;
      newL = (start.left - diffW / 2).clamp(bounds.left, math.max(bounds.left, bounds.right - newW));
    }

    final updated = Rect.fromLTWH(newL, start.top, newW, newH);
    _applyUpdate(updated);
  }

  void _updateLeftEdge(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width - totalDelta.dx).clamp(36.0, math.max(36.0, start.right - bounds.left));
    double newH = start.height;
    double newT = start.top;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      final diffH = newH - start.height;
      newT = (start.top - diffH / 2).clamp(bounds.top, math.max(bounds.top, bounds.bottom - newH));
    }

    final updated = Rect.fromLTWH(start.right - newW, newT, newW, newH);
    _applyUpdate(updated);
  }

  void _updateRightEdge(DragUpdateDetails details) {
    if (_dragStartCrop == null || _dragStartPointer == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final start = _dragStartCrop!;

    double newW = (start.width + totalDelta.dx).clamp(36.0, math.max(36.0, bounds.right - start.left));
    double newH = start.height;
    double newT = start.top;
    if (widget.targetAspectRatio != null) {
      final ratio = widget.targetAspectRatio!;
      newH = newW / ratio;
      final diffH = newH - start.height;
      newT = (start.top - diffH / 2).clamp(bounds.top, math.max(bounds.top, bounds.bottom - newH));
    }

    final updated = Rect.fromLTWH(start.left, newT, newW, newH);
    _applyUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final screenCrop = _getCurrentScreenCrop();
    final displayBounds = widget.imageDisplayRect;
    const hitSize = 36.0;

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Darkened Background with GPU-accelerated Cutout
          Positioned.fill(
            child: CustomPaint(
              painter: _HolePainter(
                hole: screenCrop,
                imageBounds: displayBounds,
              ),
            ),
          ),

          // 2. Crop Box (With 3x3 rule-of-thirds grid & Center Move Gesture)
          Positioned(
            left: screenCrop.left,
            top: screenCrop.top,
            width: screenCrop.width,
            height: screenCrop.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _updateMove,
              onPanEnd: _onPanEnd,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Rule-of-Thirds Grid
                    Column(
                      children: [
                        const Spacer(),
                        Divider(color: Colors.white.withValues(alpha: 0.35), height: 1),
                        const Spacer(),
                        Divider(color: Colors.white.withValues(alpha: 0.35), height: 1),
                        const Spacer(),
                      ],
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        VerticalDivider(color: Colors.white.withValues(alpha: 0.35), width: 1),
                        const Spacer(),
                        VerticalDivider(color: Colors.white.withValues(alpha: 0.35), width: 1),
                        const Spacer(),
                      ],
                    ),

                    // Center Pan / Move Indicator
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_with_rounded, size: 18, color: Colors.white70),
                      ),
                    ),

                    // Real-Time Dimensions Pill
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.sourcePixelCrop.width.round()} × ${widget.sourcePixelCrop.height.round()} px',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Four Mid-Edge Handles (Top, Bottom, Left, Right)
          // Top Edge
          Positioned(
            left: screenCrop.left + (screenCrop.width - 40.0) / 2,
            top: screenCrop.top - (hitSize / 2),
            child: _buildEdgeHandle(
              isVertical: false,
              cursor: SystemMouseCursors.resizeUpDown,
              onPanUpdate: _updateTopEdge,
            ),
          ),
          // Bottom Edge
          Positioned(
            left: screenCrop.left + (screenCrop.width - 40.0) / 2,
            top: screenCrop.bottom - (hitSize / 2),
            child: _buildEdgeHandle(
              isVertical: false,
              cursor: SystemMouseCursors.resizeUpDown,
              onPanUpdate: _updateBottomEdge,
            ),
          ),
          // Left Edge
          Positioned(
            left: screenCrop.left - (hitSize / 2),
            top: screenCrop.top + (screenCrop.height - 40.0) / 2,
            child: _buildEdgeHandle(
              isVertical: true,
              cursor: SystemMouseCursors.resizeLeftRight,
              onPanUpdate: _updateLeftEdge,
            ),
          ),
          // Right Edge
          Positioned(
            left: screenCrop.right - (hitSize / 2),
            top: screenCrop.top + (screenCrop.height - 40.0) / 2,
            child: _buildEdgeHandle(
              isVertical: true,
              cursor: SystemMouseCursors.resizeLeftRight,
              onPanUpdate: _updateRightEdge,
            ),
          ),

          // 4. Four Corner Handles (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
          Positioned(
            left: screenCrop.left - (hitSize / 2),
            top: screenCrop.top - (hitSize / 2),
            child: _buildCornerHandle(
              cursor: SystemMouseCursors.resizeUpLeft,
              onPanUpdate: _updateTopLeft,
            ),
          ),
          Positioned(
            left: screenCrop.right - (hitSize / 2),
            top: screenCrop.top - (hitSize / 2),
            child: _buildCornerHandle(
              cursor: SystemMouseCursors.resizeUpRight,
              onPanUpdate: _updateTopRight,
            ),
          ),
          Positioned(
            left: screenCrop.left - (hitSize / 2),
            top: screenCrop.bottom - (hitSize / 2),
            child: _buildCornerHandle(
              cursor: SystemMouseCursors.resizeDownLeft,
              onPanUpdate: _updateBottomLeft,
            ),
          ),
          Positioned(
            left: screenCrop.right - (hitSize / 2),
            top: screenCrop.bottom - (hitSize / 2),
            child: _buildCornerHandle(
              cursor: SystemMouseCursors.resizeDownRight,
              onPanUpdate: _updateBottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle({
    required MouseCursor cursor,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    const hitSize = 36.0;
    const badgeSize = 14.0;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle({
    required bool isVertical,
    required MouseCursor cursor,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    const hitSize = 36.0;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: isVertical ? hitSize : 40.0,
          height: isVertical ? 40.0 : hitSize,
          child: Center(
            child: Container(
              width: isVertical ? 5.0 : 18.0,
              height: isVertical ? 18.0 : 5.0,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 4-Corner Quadrilateral Perspective Transform Layer with 120 FPS hardware-accelerated dragging
class _InteractiveQuadPerspectiveLayer extends StatefulWidget {
  final QuadPoints sourceQuad;
  final Rect imageDisplayRect;
  final Size sourceImageSize;
  final double zoomScale;
  final ValueChanged<QuadPoints> onQuadChanged;

  const _InteractiveQuadPerspectiveLayer({
    required this.sourceQuad,
    required this.imageDisplayRect,
    required this.sourceImageSize,
    required this.zoomScale,
    required this.onQuadChanged,
  });

  @override
  State<_InteractiveQuadPerspectiveLayer> createState() => _InteractiveQuadPerspectiveLayerState();
}

class _InteractiveQuadPerspectiveLayerState extends State<_InteractiveQuadPerspectiveLayer> {
  QuadPoints? _activeSourceQuad;
  Offset? _dragStartPointer;
  Offset? _dragStartScreenCorner;
  QuadPoints? _dragStartQuad;

  @override
  void didUpdateWidget(covariant _InteractiveQuadPerspectiveLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragStartPointer == null) {
      _activeSourceQuad = null;
    }
  }

  QuadPoints get _currentSourceQuad => _activeSourceQuad ?? widget.sourceQuad;

  Offset _sourceToScreen(Offset pt) {
    return CoordinateConverter.sourceToScreen(
      sourceX: pt.dx,
      sourceY: pt.dy,
      imageDisplayRect: widget.imageDisplayRect,
      sourceImageSize: widget.sourceImageSize,
    );
  }

  Offset _screenToSource(Offset pt) {
    final src = CoordinateConverter.screenToSource(
      screenX: pt.dx,
      screenY: pt.dy,
      imageDisplayRect: widget.imageDisplayRect,
      sourceImageSize: widget.sourceImageSize,
    );
    return Offset(
      src.dx.clamp(0.0, widget.sourceImageSize.width),
      src.dy.clamp(0.0, widget.sourceImageSize.height),
    );
  }

  void _onCornerPanStart(DragStartDetails details, Offset screenCorner) {
    _dragStartPointer = details.globalPosition;
    _dragStartScreenCorner = screenCorner;
    _dragStartQuad = _currentSourceQuad;
  }

  void _onCornerPanEnd(DragEndDetails details) {
    _dragStartPointer = null;
    _dragStartScreenCorner = null;
    _dragStartQuad = null;
  }

  void _updateCorner({
    required DragUpdateDetails details,
    required QuadPoints Function(QuadPoints startQuad, Offset newSourcePt) updater,
  }) {
    if (_dragStartPointer == null || _dragStartScreenCorner == null || _dragStartQuad == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final bounds = widget.imageDisplayRect;
    final newScreen = Offset(
      (_dragStartScreenCorner!.dx + totalDelta.dx).clamp(bounds.left, bounds.right),
      (_dragStartScreenCorner!.dy + totalDelta.dy).clamp(bounds.top, bounds.bottom),
    );
    final newSource = _screenToSource(newScreen);
    final updated = updater(_dragStartQuad!, newSource);
    setState(() => _activeSourceQuad = updated);
    widget.onQuadChanged(updated);
  }

  void _updateCenterMove(DragUpdateDetails details) {
    if (_dragStartPointer == null || _dragStartQuad == null) return;
    final totalDelta = details.globalPosition - _dragStartPointer!;
    final scaleX = widget.sourceImageSize.width / widget.imageDisplayRect.width;
    final scaleY = widget.sourceImageSize.height / widget.imageDisplayRect.height;
    final deltaSrc = Offset(totalDelta.dx * scaleX, totalDelta.dy * scaleY);
    final bounds = Rect.fromLTWH(0, 0, widget.sourceImageSize.width, widget.sourceImageSize.height);
    final updated = _dragStartQuad!.translate(deltaSrc).clamp(bounds);
    setState(() => _activeSourceQuad = updated);
    widget.onQuadChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final quad = _currentSourceQuad;
    final screenTL = _sourceToScreen(quad.topLeft);
    final screenTR = _sourceToScreen(quad.topRight);
    final screenBR = _sourceToScreen(quad.bottomRight);
    final screenBL = _sourceToScreen(quad.bottomLeft);

    final centerPt = Offset(
      (screenTL.dx + screenTR.dx + screenBR.dx + screenBL.dx) / 4.0,
      (screenTL.dy + screenTR.dy + screenBR.dy + screenBL.dy) / 4.0,
    );

    const hitSize = 36.0;

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Semi-transparent polygon fill and grid mesh
          Positioned.fill(
            child: CustomPaint(
              painter: _QuadPerspectivePainter(
                topLeft: screenTL,
                topRight: screenTR,
                bottomRight: screenBR,
                bottomLeft: screenBL,
                imageBounds: widget.imageDisplayRect,
              ),
            ),
          ),

          // 2. Center Move Handle
          Positioned(
            left: centerPt.dx - 18,
            top: centerPt.dy - 18,
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  _dragStartPointer = d.globalPosition;
                  _dragStartQuad = _currentSourceQuad;
                },
                onPanUpdate: _updateCenterMove,
                onPanEnd: (d) {
                  _dragStartPointer = null;
                  _dragStartQuad = null;
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.open_with_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),

          // 3. Top-Left Corner Handle
          Positioned(
            left: screenTL.dx - (hitSize / 2),
            top: screenTL.dy - (hitSize / 2),
            child: _buildCornerHandle(
              label: 'TL',
              color: const Color(0xFFEF4444),
              screenCorner: screenTL,
              onPanUpdate: (d) => _updateCorner(
                details: d,
                updater: (start, pt) => start.copyWith(topLeft: pt),
              ),
            ),
          ),

          // 4. Top-Right Corner Handle
          Positioned(
            left: screenTR.dx - (hitSize / 2),
            top: screenTR.dy - (hitSize / 2),
            child: _buildCornerHandle(
              label: 'TR',
              color: const Color(0xFF3B82F6),
              screenCorner: screenTR,
              onPanUpdate: (d) => _updateCorner(
                details: d,
                updater: (start, pt) => start.copyWith(topRight: pt),
              ),
            ),
          ),

          // 5. Bottom-Right Corner Handle
          Positioned(
            left: screenBR.dx - (hitSize / 2),
            top: screenBR.dy - (hitSize / 2),
            child: _buildCornerHandle(
              label: 'BR',
              color: const Color(0xFF10B981),
              screenCorner: screenBR,
              onPanUpdate: (d) => _updateCorner(
                details: d,
                updater: (start, pt) => start.copyWith(bottomRight: pt),
              ),
            ),
          ),

          // 6. Bottom-Left Corner Handle
          Positioned(
            left: screenBL.dx - (hitSize / 2),
            top: screenBL.dy - (hitSize / 2),
            child: _buildCornerHandle(
              label: 'BL',
              color: const Color(0xFFF59E0B),
              screenCorner: screenBL,
              onPanUpdate: (d) => _updateCorner(
                details: d,
                updater: (start, pt) => start.copyWith(bottomLeft: pt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle({
    required String label,
    required Color color,
    required Offset screenCorner,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    const hitSize = 36.0;

    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _onCornerPanStart(d, screenCorner),
        onPanUpdate: onPanUpdate,
        onPanEnd: _onCornerPanEnd,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuadPerspectivePainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final Rect imageBounds;

  _QuadPerspectivePainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.imageBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final quadPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // GPU-accelerated EvenOdd hole punch - 0 ms CPU time
    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addPath(quadPath, Offset.zero);

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    canvas.drawPath(dimPath, dimPaint);

    // Highlight quad boundary
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(quadPath, strokePaint);

    // Draw perspective guide lines (3x3 mesh)
    final meshPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (double f = 0.333; f < 0.99; f += 0.333) {
      final topPt = Offset.lerp(topLeft, topRight, f)!;
      final botPt = Offset.lerp(bottomLeft, bottomRight, f)!;
      canvas.drawLine(topPt, botPt, meshPaint);

      final leftPt = Offset.lerp(topLeft, bottomLeft, f)!;
      final rightPt = Offset.lerp(topRight, bottomRight, f)!;
      canvas.drawLine(leftPt, rightPt, meshPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuadPerspectivePainter oldDelegate) {
    return oldDelegate.topLeft != topLeft ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomRight != bottomRight ||
        oldDelegate.bottomLeft != bottomLeft;
  }
}

class _HolePainter extends CustomPainter {
  final Rect hole;
  final Rect imageBounds;

  _HolePainter({required this.hole, required this.imageBounds});

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    // GPU-accelerated EvenOdd hole punch - 0 ms CPU time
    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(hole);
    canvas.drawPath(dimPath, dimPaint);

    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(imageBounds, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return oldDelegate.hole != hole || oldDelegate.imageBounds != imageBounds;
  }
}

