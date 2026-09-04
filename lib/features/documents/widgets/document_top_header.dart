import 'package:flutter/material.dart';
import '../models/document_print_state.dart';

class DocumentTopHeader extends StatelessWidget {
  final DocumentPrintState state;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onNewDocument;
  final VoidCallback onOpenFile;
  final VoidCallback onSaveProject;
  final VoidCallback onExportPdf;
  final VoidCallback onFirstPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onLastPage;
  final VoidCallback onPrint;
  final VoidCallback? onCloseProject;

  const DocumentTopHeader({
    super.key,
    required this.state,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onNewDocument,
    required this.onOpenFile,
    required this.onSaveProject,
    required this.onExportPdf,
    required this.onFirstPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onLastPage,
    required this.onPrint,
    this.onCloseProject,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoc = state.hasDocument;
    final totalPages = state.totalPages > 0 ? state.totalPages : 1;
    final currentPage = state.hasDocument ? state.activePageIndex + 1 : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Icon Badge + Title + Preset Dimensions Pill
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
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
                    const Text(
                      'Document Printing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        '${state.paperPreset.name} (${state.orientation.displayName})',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Multi-format print: PDF, Word, Excel, PowerPoint, and images with paper scaling',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Tools:
          // 1. Undo
          IconButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icon(
              Icons.undo_rounded,
              size: 19,
              color: canUndo ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
            tooltip: 'Undo (Ctrl+Z)',
            visualDensity: VisualDensity.compact,
          ),

          // 2. Redo
          IconButton(
            onPressed: canRedo ? onRedo : null,
            icon: Icon(
              Icons.redo_rounded,
              size: 19,
              color: canRedo ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
            tooltip: 'Redo (Ctrl+Shift+Z / Ctrl+Y)',
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 8),

          // 3. New Document
          OutlinedButton.icon(
            onPressed: onNewDocument,
            icon: const Icon(Icons.document_scanner_outlined, size: 15, color: Color(0xFF1E293B)),
            label: const Text(
              'New',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 6),

          // 4. Open
          OutlinedButton.icon(
            onPressed: onOpenFile,
            icon: const Icon(Icons.folder_open_outlined, size: 15, color: Color(0xFF1E293B)),
            label: const Text(
              'Open',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 6),

          // 5. Save Project (.fps)
          OutlinedButton.icon(
            onPressed: hasDoc ? onSaveProject : null,
            icon: Icon(
              Icons.save_outlined,
              size: 15,
              color: hasDoc ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
            label: Text(
              'Save .fps',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasDoc ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 6),

          // Close Project (Return to Recents)
          IconButton(
            onPressed: hasDoc ? onCloseProject : null,
            icon: Icon(
              Icons.close_rounded,
              size: 19,
              color: hasDoc ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
            tooltip: 'Close Project (Return to Recents)',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),

          // 6. Export PDF
          OutlinedButton.icon(
            onPressed: hasDoc ? onExportPdf : null,
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              size: 15,
              color: hasDoc ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
            label: Text(
              'Export PDF',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasDoc ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: Colors.white,
            ),
          ),

          // 7. Multi-page pagination controls
          if (hasDoc && totalPages > 1) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 8),
            _IconNavButton(
              icon: Icons.first_page_rounded,
              tooltip: 'First Page',
              onTap: state.activePageIndex > 0 ? onFirstPage : null,
            ),
            const SizedBox(width: 2),
            _IconNavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous Page',
              onTap: state.activePageIndex > 0 ? onPreviousPage : null,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 4),
            _IconNavButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next Page',
              onTap: state.activePageIndex < totalPages - 1 ? onNextPage : null,
            ),
            const SizedBox(width: 2),
            _IconNavButton(
              icon: Icons.last_page_rounded,
              tooltip: 'Last Page',
              onTap: state.activePageIndex < totalPages - 1 ? onLastPage : null,
            ),
          ],

          const SizedBox(width: 10),

          // 8. Primary PRINT Action Button
          ElevatedButton.icon(
            onPressed: hasDoc ? onPrint : null,
            icon: const Icon(Icons.print_rounded, size: 17, color: Colors.white),
            label: const Text(
              'Print (Ctrl+P)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
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

class _IconNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: onTap != null ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}
