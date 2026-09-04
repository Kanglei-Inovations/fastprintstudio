import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage/recent_projects_service.dart';

class DocumentEmptyState extends StatefulWidget {
  final VoidCallback onChooseFile;
  final VoidCallback onOpenFpsProject;
  final ValueChanged<RecentProjectItem> onOpenRecentProject;

  const DocumentEmptyState({
    super.key,
    required this.onChooseFile,
    required this.onOpenFpsProject,
    required this.onOpenRecentProject,
  });

  @override
  State<DocumentEmptyState> createState() => _DocumentEmptyStateState();
}

class _DocumentEmptyStateState extends State<DocumentEmptyState> {
  List<RecentProjectItem> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final list = await RecentProjectsService.getRecentProjects(projectType: 'document');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final blueColor = const Color(0xFF2563EB);

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                        color: isDark ? blueColor.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Icon(Icons.description_outlined, size: 28, color: blueColor),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'Document Printing Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Upload a PDF, Word, Excel, PowerPoint, or text document to configure page ranges, N-up layout, color modes, and duplex printing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Choose File, Open .fps)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: widget.onChooseFile,
                          icon: const Icon(Icons.file_open_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Choose Document',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueColor,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onOpenFpsProject,
                          icon: Icon(Icons.folder_open_rounded, size: 16, color: textPrimary),
                          label: Text(
                            'Open .fps Project',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            side: BorderSide(color: cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: cardBg,
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
                        _FormatBadge(context, 'PDF'),
                        _FormatBadge(context, 'DOCX'),
                        _FormatBadge(context, 'XLSX'),
                        _FormatBadge(context, 'PPTX'),
                        _FormatBadge(context, 'TXT'),
                        _FormatBadge(context, 'IMAGES'),
                        _FormatBadge(context, '.FPS PROJECT'),
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
                              Icon(Icons.history_rounded, size: 18, color: textPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Document Projects',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  '${_recentProjects.length}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await RecentProjectsService.clearAll(projectType: 'document');
                              _loadRecents();
                            },
                            icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                            label: const Text('Clear All', style: TextStyle(fontSize: 11.5)),
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
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
                              return _RecentDocCard(
                                item: item,
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

class _RecentDocCard extends StatefulWidget {
  final RecentProjectItem item;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentDocCard({
    required this.item,
    required this.formattedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_RecentDocCard> createState() => _RecentDocCardState();
}

class _RecentDocCardState extends State<_RecentDocCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final blue = const Color(0xFF2563EB);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? blue : cardBorder,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? blue.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
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
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
                              Icons.description_outlined,
                              size: 36,
                              color: textSecondary,
                            ),
                          ),
                  ),

                  // Mode Tag (Top Left)
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
                        color: _isHovered ? blue : textPrimary,
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
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          widget.formattedDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary.withValues(alpha: 0.7),
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
  final BuildContext context;
  final String label;

  const _FormatBadge(this.context, this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
