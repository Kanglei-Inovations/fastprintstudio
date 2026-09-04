import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/id_card_provider.dart';
import '../../providers/passport_photo_provider.dart';
import '../../features/documents/providers/document_provider.dart';

class DesktopScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const DesktopScaffold({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends ConsumerState<DesktopScaffold> {
  bool _isSidebarCollapsed = true;
  bool _showPrinterCard = true;

  void _handleKeyShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        // Ctrl + P -> Print
        _triggerActivePrint();
      } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (isShiftPressed) {
          // Ctrl + Shift + Z -> Redo
          _triggerActiveRedo();
        } else {
          // Ctrl + Z -> Undo
          _triggerActiveUndo();
        }
      }
    }
  }

  void _triggerActivePrint() {
    final navIndex = ref.read(navIndexProvider);
    if (navIndex == 1) {
      ref.read(idCardProvider.notifier).printDocument();
    } else if (navIndex == 2) {
      ref.read(passportPhotoProvider.notifier).printDocument();
    } else if (navIndex == 3) {
      ref.read(documentPrintProvider.notifier).printDocument();
    }
  }

  void _triggerActiveUndo() {
    final navIndex = ref.read(navIndexProvider);
    if (navIndex == 1) {
      ref.read(idCardProvider.notifier).undo();
    } else if (navIndex == 2) {
      ref.read(passportPhotoProvider.notifier).undo();
    }
  }

  void _triggerActiveRedo() {
    final navIndex = ref.read(navIndexProvider);
    if (navIndex == 1) {
      ref.read(idCardProvider.notifier).redo();
    } else if (navIndex == 2) {
      ref.read(passportPhotoProvider.notifier).redo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(navIndexProvider);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyShortcut,
      child: Scaffold(
        body: Row(
          children: [
            // Left Sidebar
            _buildSidebar(context, activeIndex),

            // Main Workspace
            Expanded(
              child: Container(
                color: AppColors.workspaceBg,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, int activeIndex) {
    final sidebarWidth = _isSidebarCollapsed ? 72.0 : 230.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      width: sidebarWidth,
      color: AppColors.sidebarBg,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222836))),
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: 198,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Xerox & Studio Pro',
                                style: TextStyle(
                                  color: AppColors.sidebarTextMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: activeIndex == 0,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 1,
                  icon: Icons.badge_outlined,
                  label: 'Aadhaar / ID Card',
                  isSelected: activeIndex == 1,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 2,
                  icon: Icons.portrait_rounded,
                  label: 'Photo Printing',
                  isSelected: activeIndex == 2,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 3,
                  icon: Icons.description_outlined,
                  label: 'Document Printing',
                  isSelected: activeIndex == 3,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 4,
                  icon: Icons.sell_rounded,
                  label: 'Pricing & Rates',
                  isSelected: activeIndex == 4,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 5,
                  icon: Icons.history_rounded,
                  label: 'Print History',
                  isSelected: activeIndex == 5,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  index: 6,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: activeIndex == 6,
                ),
                if (ref.watch(landingFileProvider) != null || activeIndex == 7) ...[
                  const SizedBox(height: 4),
                  _buildNavItem(
                    index: 7,
                    icon: Icons.open_in_new_rounded,
                    label: 'Open With...',
                    isSelected: activeIndex == 7,
                  ),
                ],
              ],
            ),
          ),

          // Bottom Printer Card Widget
          if (!_isSidebarCollapsed && _showPrinterCard)
            ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: 210,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131824),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF232B3E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Printer',
                            style: TextStyle(fontSize: 11, color: AppColors.sidebarTextMuted, fontWeight: FontWeight.w600),
                          ),
                          InkWell(
                            onTap: () => setState(() => _showPrinterCard = false),
                            child: const Icon(Icons.close, size: 14, color: AppColors.sidebarTextMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'OneNote (Desktop)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Ready',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(navIndexProvider.notifier).state = 5; // Settings
                          },
                          icon: const Icon(Icons.settings_outlined, size: 12, color: Colors.white70),
                          label: const Text('Printer Settings', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: const BorderSide(color: Color(0xFF2D3748)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Collapse Sidebar Toggle & Version
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF222836))),
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: _isSidebarCollapsed ? 56 : 214,
                  child: Row(
                    mainAxisAlignment:
                        _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isSidebarCollapsed)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(color: AppColors.sidebarTextMuted, fontSize: 11),
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                        icon: Icon(
                          _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                          color: AppColors.sidebarTextMuted,
                          size: 20,
                        ),
                        tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(navIndexProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(8),
      hoverColor: AppColors.sidebarItemHover,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRect(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: 190,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.sidebarText,
                  ),
                  if (!_isSidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.sidebarText,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
