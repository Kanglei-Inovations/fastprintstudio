import 'package:flutter/material.dart';
import '../../../core/models/id_card_preset.dart';
import '../theme/id_card_palette.dart';

class IdCardTopToolbar extends StatelessWidget {
  final IdCardPalette palette;
  final IDCardPreset preset;
  final bool hasSource;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onNewDocument;
  final VoidCallback onOpen;
  final VoidCallback onSaveProject;
  final VoidCallback? onExportPdf;
  final VoidCallback onPrint;
  final VoidCallback? onCloseProject;

  const IdCardTopToolbar({
    super.key,
    required this.palette,
    required this.preset,
    required this.hasSource,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onNewDocument,
    required this.onOpen,
    required this.onSaveProject,
    this.onExportPdf,
    required this.onPrint,
    this.onCloseProject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border(bottom: BorderSide(color: palette.divider)),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: ID Card Icon Badge + Title + Preset Dimensions Pill
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.blue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: palette.blue.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'ID Card Printing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.isDark ? palette.blue.withValues(alpha: 0.2) : palette.blueLight,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: palette.isDark ? palette.blue.withValues(alpha: 0.4) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        '${preset.name} (${preset.formattedDimensions})',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: palette.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Auto-detect front & back, align, resize, and print on 4R, L805 or Dragon Sheet',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Center/Right Tool Actions
          // 1. Undo
          IconButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icon(
              Icons.undo_rounded,
              size: 18,
              color: canUndo ? palette.textPrimary : palette.textMuted,
            ),
            tooltip: 'Undo (Ctrl+Z)',
            visualDensity: VisualDensity.compact,
          ),

          // 2. Redo
          IconButton(
            onPressed: canRedo ? onRedo : null,
            icon: Icon(
              Icons.redo_rounded,
              size: 18,
              color: canRedo ? palette.textPrimary : palette.textMuted,
            ),
            tooltip: 'Redo (Ctrl+Shift+Z)',
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 8),

          // 3. New
          OutlinedButton.icon(
            onPressed: onNewDocument,
            icon: Icon(Icons.document_scanner_outlined, size: 15, color: palette.textPrimary),
            label: Text(
              'New',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: BorderSide(color: palette.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: palette.cardBg,
            ),
          ),
          const SizedBox(width: 6),

          // 4. Open
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: Icon(Icons.folder_open_outlined, size: 15, color: palette.textPrimary),
            label: Text(
              'Open',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: BorderSide(color: palette.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: palette.cardBg,
            ),
          ),
          const SizedBox(width: 6),

          // 5. Save Project (.fps)
          OutlinedButton.icon(
            onPressed: hasSource ? onSaveProject : null,
            icon: Icon(Icons.save_outlined, size: 15, color: hasSource ? palette.textPrimary : palette.textMuted),
            label: Text(
              'Save .fps',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasSource ? palette.textPrimary : palette.textMuted,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: BorderSide(color: palette.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: palette.cardBg,
            ),
          ),
          const SizedBox(width: 6),

          // Close Project (Return to Recents)
          IconButton(
            onPressed: hasSource ? onCloseProject : null,
            icon: Icon(
              Icons.close_rounded,
              size: 19,
              color: hasSource ? palette.textPrimary : palette.textMuted,
            ),
            tooltip: 'Close Project (Return to Recents)',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),

          // 6. Export PDF
          OutlinedButton.icon(
            onPressed: hasSource && onExportPdf != null ? onExportPdf : null,
            icon: Icon(Icons.picture_as_pdf_outlined, size: 15, color: hasSource ? palette.textPrimary : palette.textMuted),
            label: Text(
              'Export PDF',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasSource ? palette.textPrimary : palette.textMuted,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: BorderSide(color: palette.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: palette.cardBg,
            ),
          ),
          const SizedBox(width: 10),

          // 7. Primary PRINT Action Button
          ElevatedButton.icon(
            onPressed: hasSource ? onPrint : null,
            icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
            label: const Text(
              'Print (Ctrl+P)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.isDark ? const Color(0xFF0284C7) : const Color(0xFF1D4ED8),
              disabledBackgroundColor: palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
