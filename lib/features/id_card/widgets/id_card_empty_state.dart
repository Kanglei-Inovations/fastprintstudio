import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage/recent_projects_service.dart';
import '../theme/id_card_palette.dart';

class IdCardEmptyState extends StatefulWidget {
  final IdCardPalette palette;
  final VoidCallback onUploadPdf;
  final VoidCallback onUploadImage;
  final VoidCallback onOpenFpsProject;
  final ValueChanged<RecentProjectItem> onOpenRecentProject;

  const IdCardEmptyState({
    super.key,
    required this.palette,
    required this.onUploadPdf,
    required this.onUploadImage,
    required this.onOpenFpsProject,
    required this.onOpenRecentProject,
  });

  @override
  State<IdCardEmptyState> createState() => _IdCardEmptyStateState();
}

class _IdCardEmptyStateState extends State<IdCardEmptyState> {
  List<RecentProjectItem> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final list = await RecentProjectsService.getRecentProjects(projectType: 'id_card');
    if (mounted) {
      setState(() {
        _recentProjects = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecent(String id) async {
    await RecentProjectsService.removeProject(id);
    _loadRecents();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m <= 1 ? 'Just now' : '$m mins ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hr${h > 1 ? "s" : ""} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago';
    } else {
      return DateFormat('dd MMM, yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Container(
      color: palette.canvasBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Quick Action Center Card
              Container(
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: palette.cardShadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Badge
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: palette.isDark ? palette.blue.withValues(alpha: 0.15) : palette.blueLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Icon(Icons.badge_outlined, size: 28, color: palette.blue),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'ID Card Printing Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Upload an Aadhaar, PAN, or ID card image/PDF to crop, align front/back, and print on Photo Paper or PVC.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Upload PDF, Upload Image, Open .fps)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: widget.onUploadPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
                          label: const Text(
                            'Upload PDF',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onUploadImage,
                          icon: Icon(Icons.image_outlined, size: 16, color: palette.textPrimary),
                          label: Text(
                            'Upload Image',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onOpenFpsProject,
                          icon: Icon(Icons.folder_open_rounded, size: 16, color: palette.textPrimary),
                          label: Text(
                            'Open .fps Project',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            side: BorderSide(color: palette.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: palette.cardBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Supported Formats
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _FormatBadge(palette, 'PDF'),
                        _FormatBadge(palette, 'JPG'),
                        _FormatBadge(palette, 'PNG'),
                        _FormatBadge(palette, 'WEBP'),
                        _FormatBadge(palette, '.FPS PROJECT'),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Photoshop-Style Recent Projects Section
              if (!_isLoading && _recentProjects.isNotEmpty) ...[
                const SizedBox(height: 36),
                Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history_rounded, size: 18, color: palette.textPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Recent ID Card Projects',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: palette.pillBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Text(
                                  '${_recentProjects.length}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await RecentProjectsService.clearAll(projectType: 'id_card');
                              _loadRecents();
                            },
                            icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                            label: const Text('Clear All', style: TextStyle(fontSize: 11.5)),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.textSecondary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Grid of Recent Projects
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 650 ? 3 : (constraints.maxWidth > 420 ? 2 : 1);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 185,
                            ),
                            itemCount: _recentProjects.length,
                            itemBuilder: (context, index) {
                              final item = _recentProjects[index];
                              return _RecentIdCard(
                                item: item,
                                palette: palette,
                                formattedDate: _formatDate(item.timestamp),
                                onTap: () => widget.onOpenRecentProject(item),
                                onDelete: () => _deleteRecent(item.id),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentIdCard extends StatefulWidget {
  final RecentProjectItem item;
  final IdCardPalette palette;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentIdCard({
    required this.item,
    required this.palette,
    required this.formattedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_RecentIdCard> createState() => _RecentIdCardState();
}

class _RecentIdCardState extends State<_RecentIdCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final palette = widget.palette;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? palette.blue : palette.cardBorder,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? palette.blue.withValues(alpha: 0.12) : palette.cardShadow,
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 5 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Area (Top 105px)
              Stack(
                children: [
                  Container(
                    height: 105,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.thumbnailBytes != null && item.thumbnailBytes!.isNotEmpty
                        ? Image.memory(
                            item.thumbnailBytes!,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
                        : Center(
                            child: Icon(
                              Icons.badge_outlined,
                              size: 32,
                              color: palette.textMuted,
                            ),
                          ),
                  ),

                  // Preset Mode Tag (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.presetMode.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Delete / Dismiss Button (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info Section (Bottom)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isHovered ? palette.blue : palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.paperName} • ${item.orientation}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          widget.formattedDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final IdCardPalette palette;
  final String label;

  const _FormatBadge(this.palette, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.pillBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
