import 'package:flutter/material.dart';
import '../../../core/models/l805_calibration.dart';
import '../theme/id_card_palette.dart';

class L805CalibrationDialog extends StatefulWidget {
  final IdCardPalette palette;
  final L805Calibration initialCalibration;
  final ValueChanged<L805Calibration> onSave;
  final VoidCallback onReset;

  const L805CalibrationDialog({
    super.key,
    required this.palette,
    required this.initialCalibration,
    required this.onSave,
    required this.onReset,
  });

  static Future<void> show({
    required BuildContext context,
    required IdCardPalette palette,
    required L805Calibration initialCalibration,
    required ValueChanged<L805Calibration> onSave,
    required VoidCallback onReset,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => L805CalibrationDialog(
        palette: palette,
        initialCalibration: initialCalibration,
        onSave: onSave,
        onReset: onReset,
      ),
    );
  }

  @override
  State<L805CalibrationDialog> createState() => _L805CalibrationDialogState();
}

class _L805CalibrationDialogState extends State<L805CalibrationDialog> {
  late double _cardWidth;
  late double _cardHeight;
  late double _slot1X;
  late double _slot1Y;
  late double _slot2X;
  late double _slot2Y;
  late double _globalOffsetX;
  late double _globalOffsetY;

  @override
  void initState() {
    super.initState();
    _cardWidth = widget.initialCalibration.cardWidthMm;
    _cardHeight = widget.initialCalibration.cardHeightMm;
    _slot1X = widget.initialCalibration.slot1XMm;
    _slot1Y = widget.initialCalibration.slot1YMm;
    _slot2X = widget.initialCalibration.slot2XMm;
    _slot2Y = widget.initialCalibration.slot2YMm;
    _globalOffsetX = widget.initialCalibration.globalOffsetX;
    _globalOffsetY = widget.initialCalibration.globalOffsetY;
  }

  L805Calibration get _current => L805Calibration(
        cardWidthMm: _cardWidth,
        cardHeightMm: _cardHeight,
        slot1XMm: _slot1X,
        slot1YMm: _slot1Y,
        slot2XMm: _slot2X,
        slot2YMm: _slot2Y,
        globalOffsetX: _globalOffsetX,
        globalOffsetY: _globalOffsetY,
      );

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Dialog(
      backgroundColor: palette.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.blueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune_rounded, color: palette.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Epson L805 PVC Tray Calibration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.textPrimary),
                      ),
                      Text(
                        'Calibrate physical slot coordinates on A4 carrier paper in millimeters',
                        style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, size: 20, color: palette.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: palette.divider),
            const SizedBox(height: 16),

            // Notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.isDark ? palette.blue.withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: palette.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Front and Back pages mathematically share these exact coordinates to guarantee perfect physical alignment.',
                      style: TextStyle(fontSize: 11, color: palette.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calibration Fields
            Row(
              children: [
                // Card Dimensions
                Expanded(
                  child: _buildSection(
                    title: 'Physical Card Dimensions',
                    children: [
                      _buildField('Width (mm)', _cardWidth, (v) => setState(() => _cardWidth = v)),
                      const SizedBox(height: 8),
                      _buildField('Height (mm)', _cardHeight, (v) => setState(() => _cardHeight = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Global Offset
                Expanded(
                  child: _buildSection(
                    title: 'Global Alignment Offset',
                    children: [
                      _buildField('Offset X (mm)', _globalOffsetX, (v) => setState(() => _globalOffsetX = v)),
                      const SizedBox(height: 8),
                      _buildField('Offset Y (mm)', _globalOffsetY, (v) => setState(() => _globalOffsetY = v)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                // Slot 1 (Top Card)
                Expanded(
                  child: _buildSection(
                    title: 'Slot 1 (Top Card Position)',
                    children: [
                      _buildField('Slot 1 X (mm)', _slot1X, (v) => setState(() => _slot1X = v)),
                      const SizedBox(height: 8),
                      _buildField('Slot 1 Y (mm)', _slot1Y, (v) => setState(() => _slot1Y = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Slot 2 (Bottom Card)
                Expanded(
                  child: _buildSection(
                    title: 'Slot 2 (Bottom Card Position)',
                    children: [
                      _buildField('Slot 2 X (mm)', _slot2X, (v) => setState(() => _slot2X = v)),
                      const SizedBox(height: 8),
                      _buildField('Slot 2 Y (mm)', _slot2Y, (v) => setState(() => _slot2Y = v)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom Actions
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onReset();
                    setState(() {
                      _cardWidth = L805Calibration.factoryDefault.cardWidthMm;
                      _cardHeight = L805Calibration.factoryDefault.cardHeightMm;
                      _slot1X = L805Calibration.factoryDefault.slot1XMm;
                      _slot1Y = L805Calibration.factoryDefault.slot1YMm;
                      _slot2X = L805Calibration.factoryDefault.slot2XMm;
                      _slot2Y = L805Calibration.factoryDefault.slot2YMm;
                      _globalOffsetX = 0.0;
                      _globalOffsetY = 0.0;
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 15),
                  label: const Text('Reset Defaults'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    side: BorderSide(color: palette.pillBorder),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onSave(_current);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text('Save Calibration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    final palette = widget.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardBgElevated : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.textPrimary),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, double value, ValueChanged<double> onChanged) {
    final palette = widget.palette;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        InkWell(
          onTap: () => onChanged(double.parse((value - 0.5).toStringAsFixed(1))),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.pillBorder),
            ),
            child: Icon(Icons.remove, size: 12, color: palette.textPrimary),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textPrimary, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => onChanged(double.parse((value + 0.5).toStringAsFixed(1))),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.pillBorder),
            ),
            child: Icon(Icons.add, size: 12, color: palette.textPrimary),
          ),
        ),
      ],
    );
  }
}
