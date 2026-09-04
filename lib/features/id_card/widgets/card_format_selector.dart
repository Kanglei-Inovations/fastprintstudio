import 'package:flutter/material.dart';
import '../../../core/constants/id_card_presets.dart';
import '../../../core/models/id_card_preset.dart';
import '../../../core/models/id_card_workflow_type.dart';
import '../theme/id_card_palette.dart';

class CardFormatSelector extends StatelessWidget {
  final IdCardPalette palette;
  final IDCardPreset selectedPreset;
  final ValueChanged<IDCardPreset> onSelectPreset;
  final IdCardWorkflowType workflowType;
  final ValueChanged<IdCardWorkflowType> onSelectWorkflow;
  final PvcOutputMode pvcMode;
  final ValueChanged<PvcOutputMode> onSelectPvcMode;
  final int l805CardQuantity;
  final ValueChanged<int> onSelectL805CardQuantity;
  final VoidCallback? onOpenCalibration;

  const CardFormatSelector({
    super.key,
    required this.palette,
    required this.selectedPreset,
    required this.onSelectPreset,
    required this.workflowType,
    required this.onSelectWorkflow,
    required this.pvcMode,
    required this.onSelectPvcMode,
    this.l805CardQuantity = 1,
    required this.onSelectL805CardQuantity,
    this.onOpenCalibration,
  });

  String _getShortName(IDCardPreset p) {
    if (p.id == StandardIDCardPresets.aadhaar.id) return 'Aadhaar / ID';
    if (p.id == StandardIDCardPresets.panCard.id) return 'PAN Card';
    if (p.id == StandardIDCardPresets.voterId.id) return 'Voter ID';
    if (p.id == StandardIDCardPresets.drivingLicense.id) return 'Driving License';
    return p.name;
  }

  @override
  Widget build(BuildContext context) {
    final presets = StandardIDCardPresets.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. WORKFLOW MODE SELECTION (3 Distinct Output Modes)
        Text(
          'OUTPUT / PRODUCTION METHOD',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: palette.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // Mode 1: Photo Paper / 4R
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.photoPaperLamination,
                title: 'Photo Paper / 4R',
                price: '₹50',
                subtitle: 'Cut & Laminated',
                icon: Icons.layers_outlined,
                isSelected: workflowType == IdCardWorkflowType.photoPaperLamination,
              ),
            ),
            const SizedBox(width: 6),

            // Mode 2: Epson L805 Card
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.epsonL805,
                title: 'Epson L805 Card',
                price: '₹100',
                subtitle: 'A4 PVC Tray',
                icon: Icons.credit_card_rounded,
                isSelected: workflowType == IdCardWorkflowType.epsonL805,
              ),
            ),
            const SizedBox(width: 6),

            // Mode 3: Dragon Sheet
            Expanded(
              child: _buildWorkflowCard(
                type: IdCardWorkflowType.dragonSheet,
                title: 'Dragon Sheet',
                price: '₹100',
                subtitle: '200×300mm Sheet',
                icon: Icons.grid_view_rounded,
                isSelected: workflowType == IdCardWorkflowType.dragonSheet,
              ),
            ),
          ],
        ),

        // 2. EPSON L805 SETUP PANEL
        if (workflowType == IdCardWorkflowType.epsonL805) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.cardBgElevated : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: palette.blue),
                        const SizedBox(width: 6),
                        Text(
                          'Epson L805 Tray Setup',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                        ),
                      ],
                    ),
                    if (onOpenCalibration != null)
                      InkWell(
                        onTap: onOpenCalibration,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: palette.cardBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: palette.pillBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings_outlined, size: 12, color: palette.blue),
                              const SizedBox(width: 4),
                              Text('Calibration', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.blue)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Cards per A4 selection: 1 Card or 2 Cards
                Text('Cards per A4 Page:', style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildQtyChip(
                        qty: 1,
                        label: '1 Card (Slot 1)',
                        subtitle: 'Top tray slot only',
                        isSelected: l805CardQuantity == 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQtyChip(
                        qty: 2,
                        label: '2 Cards (Slot 1 & 2)',
                        subtitle: 'Full tray capacity',
                        isSelected: l805CardQuantity == 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Specs Summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.pillBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Template: A4 (210×297 mm)', style: TextStyle(fontSize: 10, color: palette.textSecondary)),
                      Text('Card: 85.6 × 54.0 mm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 100% Print Notice
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: palette.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Print at 100% / Actual Size. Do NOT use Fit to Page.',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // 3. DRAGON SHEET SUB-MODE SELECTOR
        if (workflowType == IdCardWorkflowType.dragonSheet) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.blue.withValues(alpha: 0.1) : palette.blueLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dragon Sheet Mode',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textPrimary),
                    ),
                    Text(
                      pvcMode == PvcOutputMode.dragonSheetDuplex ? '5 Duplex Pairs' : '10 Single Cards',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildPvcModeChip(
                        mode: PvcOutputMode.dragonSheetDuplex,
                        label: '5 Pairs',
                        subtitle: 'Front + Back',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPvcModeChip(
                        mode: PvcOutputMode.dragonSheetSingle,
                        label: '10 Cards',
                        subtitle: 'Single-Side',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // 4. ID CARD DOCUMENT TYPE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'CARD DOCUMENT TYPE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textSecondary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedPreset.formattedDimensions,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 5. Preset Dropdown Selector
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.pillBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPreset.id,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: palette.textSecondary),
              dropdownColor: palette.cardBg,
              items: presets.map((preset) {
                return DropdownMenuItem<String>(
                  value: preset.id,
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: palette.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: preset.id == selectedPreset.id ? FontWeight.w700 : FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${preset.widthMm.toInt()}×${preset.heightMm.toInt()} mm',
                        style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                final preset = presets.firstWhere((p) => p.id == id);
                onSelectPreset(preset);
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 6. Quick Preset Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.take(4).map((preset) {
            final isSelected = preset.id == selectedPreset.id;
            return InkWell(
              onTap: () => onSelectPreset(preset),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? palette.blueLight : palette.pillBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? palette.blue : palette.pillBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Text(
                  _getShortName(preset),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? palette.blue : palette.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkflowCard({
    required IdCardWorkflowType type,
    required String title,
    required String price,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSelectWorkflow(type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? palette.blueLight : palette.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? palette.blue : palette.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.blue.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: isSelected ? palette.blue : palette.textSecondary),
                const Spacer(),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? palette.blue : palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? palette.blue : palette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyChip({
    required int qty,
    required String label,
    required String subtitle,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSelectL805CardQuantity(qty),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.blueLight : palette.cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? palette.blue : palette.pillBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? palette.blue : palette.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9.5, color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPvcModeChip({
    required PvcOutputMode mode,
    required String label,
    required String subtitle,
  }) {
    final isSelected = pvcMode == mode;

    return InkWell(
      onTap: () => onSelectPvcMode(mode),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.blue : palette.cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? palette.blue : palette.pillBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : palette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white70 : palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
