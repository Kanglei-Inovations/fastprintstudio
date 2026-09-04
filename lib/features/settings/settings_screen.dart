import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/constants/paper_presets.dart';
import '../../core/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/pricing_provider.dart';

enum SettingsCategory {
  // GENERAL
  general('General', Icons.tune_rounded, 'GENERAL'),
  appearance('Appearance', Icons.palette_outlined, 'GENERAL'),

  // PRINTING
  printer('Printer', Icons.print_outlined, 'PRINTING'),
  printDefaults('Print Defaults', Icons.description_outlined, 'PRINTING'),
  paperLayout('Paper & Layout', Icons.aspect_ratio_outlined, 'PRINTING'),

  // IMAGE & DOCUMENTS
  imageProcessing('Image Processing', Icons.image_outlined, 'IMAGE & DOCUMENTS'),
  documentProcessing('Document Processing', Icons.article_outlined, 'IMAGE & DOCUMENTS'),

  // BUSINESS
  shopInformation('Shop Information', Icons.storefront_outlined, 'BUSINESS'),
  pricingRates('Pricing & Rates', Icons.currency_rupee_rounded, 'BUSINESS'),
  inventoryMaterials('Inventory & Stock', Icons.inventory_2_outlined, 'BUSINESS'),

  // SYSTEM
  storageBackup('Storage & Backup', Icons.folder_outlined, 'SYSTEM'),
  printHistory('Print History', Icons.history_rounded, 'SYSTEM'),
  keyboardShortcuts('Keyboard Shortcuts', Icons.keyboard_outlined, 'SYSTEM'),
  about('About', Icons.info_outline_rounded, 'SYSTEM');

  final String label;
  final IconData icon;
  final String group;
  const SettingsCategory(this.label, this.icon, this.group);
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsCategory _activeCategory = SettingsCategory.general;
  bool _hasUnsavedChanges = false;
  late AppSettings _draftSettings;
  bool _isInitialized = false;

  // Shop info controllers
  late TextEditingController _shopNameCtrl;
  late TextEditingController _shopAddressCtrl;
  late TextEditingController _shopPhoneCtrl;
  late TextEditingController _shopEmailCtrl;
  late TextEditingController _shopGstCtrl;
  late TextEditingController _receiptFooterCtrl;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _shopAddressCtrl = TextEditingController();
    _shopPhoneCtrl = TextEditingController();
    _shopEmailCtrl = TextEditingController();
    _shopGstCtrl = TextEditingController();
    _receiptFooterCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _shopEmailCtrl.dispose();
    _shopGstCtrl.dispose();
    _receiptFooterCtrl.dispose();
    super.dispose();
  }

  void _initFromSettings(AppSettings settings) {
    _draftSettings = settings;
    _shopNameCtrl.text = settings.shopName;
    _shopAddressCtrl.text = settings.shopAddress;
    _shopPhoneCtrl.text = settings.shopPhone;
    _shopEmailCtrl.text = settings.shopEmail;
    _shopGstCtrl.text = settings.shopGst;
    _receiptFooterCtrl.text = settings.receiptFooter;
    _isInitialized = true;
  }

  void _updateDraft(AppSettings updated) {
    setState(() {
      _draftSettings = updated;
      _hasUnsavedChanges = true;
    });
    // Auto-save setting change directly to provider
    ref.read(settingsProvider.notifier).updateSettings(updated);
  }

  void _saveAllChanges() {
    // Incorporate text controllers
    final finalSettings = _draftSettings.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      shopAddress: _shopAddressCtrl.text.trim(),
      shopPhone: _shopPhoneCtrl.text.trim(),
      shopEmail: _shopEmailCtrl.text.trim(),
      shopGst: _shopGstCtrl.text.trim(),
      receiptFooter: _receiptFooterCtrl.text.trim(),
    );

    ref.read(settingsProvider.notifier).updateSettings(finalSettings);
    setState(() {
      _draftSettings = finalSettings;
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All settings saved successfully.'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmResetDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text(
          'This will restore all printer defaults, layout margins, and application preferences to factory defaults. Your print history and pricing rates will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Reset Defaults', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).resetToDefaults();
      final fresh = ref.read(settingsProvider);
      setState(() {
        _initFromSettings(fresh);
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings have been reset to defaults.'),
            backgroundColor: Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSettings = ref.watch(settingsProvider);
    if (!_isInitialized) {
      _initFromSettings(currentSettings);
    }

    final availablePrintersAsync = ref.watch(availablePrintersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TOP HEADER matching settings.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Settings Blue Badge Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure printers, printing defaults, application preferences and studio settings.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // "All changes saved" badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasUnsavedChanges ? Icons.sync_rounded : Icons.check_circle_rounded,
                      size: 16,
                      color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasUnsavedChanges ? 'Unsaved changes' : 'All changes saved',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _hasUnsavedChanges ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Reset Defaults Button
                OutlinedButton.icon(
                  onPressed: _confirmResetDefaults,
                  icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF475569)),
                  label: const Text(
                    'Reset Defaults',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),

                // Save Changes Button
                ElevatedButton.icon(
                  onPressed: _saveAllChanges,
                  icon: const Icon(Icons.save_outlined, size: 15, color: Colors.white),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN SPLIT VIEW (Left Navigation + Right Content Area)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT SECONDARY SETTINGS NAVIGATION
                Container(
                  width: 225,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    children: [
                      _buildNavHeader('SETTINGS'),
                      const SizedBox(height: 8),

                      _buildNavSection('GENERAL', [
                        SettingsCategory.general,
                        SettingsCategory.appearance,
                      ]),

                      const SizedBox(height: 12),
                      _buildNavSection('PRINTING', [
                        SettingsCategory.printer,
                        SettingsCategory.printDefaults,
                        SettingsCategory.paperLayout,
                      ]),

                      const SizedBox(height: 12),
                      _buildNavSection('IMAGE & DOCUMENTS', [
                        SettingsCategory.imageProcessing,
                        SettingsCategory.documentProcessing,
                      ]),

                      const SizedBox(height: 12),
                      _buildNavSection('BUSINESS', [
                        SettingsCategory.shopInformation,
                        SettingsCategory.pricingRates,
                        SettingsCategory.inventoryMaterials,
                      ]),

                      const SizedBox(height: 12),
                      _buildNavSection('SYSTEM', [
                        SettingsCategory.storageBackup,
                        SettingsCategory.printHistory,
                        SettingsCategory.keyboardShortcuts,
                        SettingsCategory.about,
                      ]),
                    ],
                  ),
                ),

                // RIGHT CONTENT AREA (Responsive 2-column cards)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Category Header
                        _buildCategoryHeader(_activeCategory),
                        const SizedBox(height: 18),

                        // Active Category View
                        _buildActiveCategoryContent(
                          _activeCategory,
                          _draftSettings,
                          availablePrintersAsync,
                        ),

                        const SizedBox(height: 24),

                        // Bottom Tip Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tip: Changes to printer settings will apply to all print services across the application.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Navigation Components ---
  Widget _buildNavHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavSection(String groupTitle, List<SettingsCategory> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNavHeader(groupTitle),
        const SizedBox(height: 2),
        ...items.map((cat) {
          final isSelected = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryHeader(SettingsCategory cat) {
    String subtitle = 'Configure ${cat.label.toLowerCase()} preferences and options.';
    if (cat == SettingsCategory.general) {
      subtitle = 'Configure general application settings and preferences.';
    } else if (cat == SettingsCategory.printer) {
      subtitle = 'Configure default Windows printing hardware and print spooling behavior.';
    } else if (cat == SettingsCategory.printDefaults) {
      subtitle = 'Set default paper presets, orientations, copies and output resolution.';
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(cat.icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cat.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Category Switcher ---
  Widget _buildActiveCategoryContent(
    SettingsCategory category,
    AppSettings settings,
    AsyncValue<List<Printer>> printersAsync,
  ) {
    switch (category) {
      case SettingsCategory.general:
        return _buildGeneralCategory(settings);
      case SettingsCategory.appearance:
        return _buildAppearanceCategory(settings);
      case SettingsCategory.printer:
        return _buildPrinterCategory(settings, printersAsync);
      case SettingsCategory.printDefaults:
        return _buildPrintDefaultsCategory(settings);
      case SettingsCategory.paperLayout:
        return _buildPaperLayoutCategory(settings);
      case SettingsCategory.imageProcessing:
        return _buildImageProcessingCategory(settings);
      case SettingsCategory.documentProcessing:
        return _buildDocumentProcessingCategory(settings);
      case SettingsCategory.shopInformation:
        return _buildShopInformationCategory(settings);
      case SettingsCategory.pricingRates:
        return _buildPricingRatesCategory();
      case SettingsCategory.inventoryMaterials:
        return _buildInventoryCategory();
      case SettingsCategory.storageBackup:
        return _buildStorageBackupCategory(settings);
      case SettingsCategory.printHistory:
        return _buildPrintHistoryCategory(settings);
      case SettingsCategory.keyboardShortcuts:
        return _buildKeyboardShortcutsCategory();
      case SettingsCategory.about:
        return _buildAboutCategory();
    }
  }

  // 1. GENERAL CATEGORY
  Widget _buildGeneralCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.window_rounded,
        title: 'Application',
        children: [
          _buildDropdownRow<String>(
            icon: Icons.language_rounded,
            title: 'Application Language',
            subtitle: 'Change the language of the application',
            value: s.language,
            items: const ['English', 'Hindi'],
            onChanged: (v) => _updateDraft(s.copyWith(language: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.rocket_launch_outlined,
            title: 'Start application on system startup',
            subtitle: 'Automatically start FastPrint Studio when system boots',
            value: s.startOnStartup,
            onChanged: (v) => _updateDraft(s.copyWith(startOnStartup: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Confirm before printing',
            subtitle: 'Show confirmation dialog before sending print job',
            value: s.confirmBeforePrinting,
            onChanged: (v) => _updateDraft(s.copyWith(confirmBeforePrinting: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.history_toggle_off_rounded,
            title: 'Remember last selected service',
            subtitle: 'Automatically select last used service on startup',
            value: s.rememberLastService,
            onChanged: (v) => _updateDraft(s.copyWith(rememberLastService: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.save_outlined,
            title: 'Automatically save projects',
            subtitle: 'Auto save projects at regular intervals',
            value: s.autoSaveProjects,
            onChanged: (v) => _updateDraft(s.copyWith(autoSaveProjects: v)),
          ),
        ],
      ),
      rightCard: Column(
        children: [
          _buildCard(
            icon: Icons.desktop_windows_outlined,
            title: 'Interface',
            children: [
              _buildSegmentedRow(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'Choose application theme',
                current: s.themeMode,
                options: const ['Light', 'Dark', 'System'],
                onSelected: (v) => _updateDraft(s.copyWith(themeMode: v)),
              ),
              const Divider(height: 18),
              _buildSegmentedRow(
                icon: Icons.view_compact_outlined,
                title: 'UI Density',
                subtitle: 'Adjust the size of UI elements',
                current: s.uiDensity,
                options: const ['Comfortable', 'Compact'],
                onSelected: (v) => _updateDraft(s.copyWith(uiDensity: v)),
              ),
              const Divider(height: 18),
              _buildSwitchRow(
                icon: Icons.shield_outlined,
                title: 'Show tooltips',
                subtitle: 'Show helpful tooltips on hover',
                value: s.showTooltips,
                onChanged: (v) => _updateDraft(s.copyWith(showTooltips: v)),
              ),
              const Divider(height: 18),
              _buildSwitchRow(
                icon: Icons.keyboard_outlined,
                title: 'Show keyboard shortcuts',
                subtitle: 'Show shortcuts in the UI',
                value: s.showShortcuts,
                onChanged: (v) => _updateDraft(s.copyWith(showShortcuts: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            children: [
              _buildSwitchRow(
                icon: Icons.notifications_active_outlined,
                title: 'Show success notifications',
                subtitle: 'Show notification on successful actions',
                value: s.showSuccessNotifications,
                onChanged: (v) => _updateDraft(s.copyWith(showSuccessNotifications: v)),
              ),
              const Divider(height: 18),
              _buildSwitchRow(
                icon: Icons.error_outline_rounded,
                title: 'Show error notifications',
                subtitle: 'Show notification on errors',
                value: s.showErrorNotifications,
                onChanged: (v) => _updateDraft(s.copyWith(showErrorNotifications: v)),
              ),
              const Divider(height: 18),
              _buildSwitchRow(
                icon: Icons.volume_up_outlined,
                title: 'Play sound for notifications',
                subtitle: 'Play sound for important notifications',
                value: s.playNotificationSound,
                onChanged: (v) => _updateDraft(s.copyWith(playNotificationSound: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. APPEARANCE CATEGORY
  Widget _buildAppearanceCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.palette_outlined,
        title: 'Theme Selection',
        children: [
          Row(
            children: [
              Expanded(
                child: _buildThemeCard(
                  title: 'Light',
                  icon: Icons.light_mode_outlined,
                  isSelected: s.themeMode == 'Light',
                  bgColor: Colors.white,
                  borderColor: const Color(0xFFCBD5E1),
                  onTap: () => _updateDraft(s.copyWith(themeMode: 'Light')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildThemeCard(
                  title: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  isSelected: s.themeMode == 'Dark',
                  bgColor: const Color(0xFF0F172A),
                  borderColor: const Color(0xFF334155),
                  onTap: () => _updateDraft(s.copyWith(themeMode: 'Dark')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildThemeCard(
                  title: 'System',
                  icon: Icons.brightness_auto_outlined,
                  isSelected: s.themeMode == 'System',
                  bgColor: const Color(0xFFE2E8F0),
                  borderColor: const Color(0xFF94A3B8),
                  onTap: () => _updateDraft(s.copyWith(themeMode: 'System')),
                ),
              ),
            ],
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.tune_rounded,
        title: 'Visual Options',
        children: [
          _buildSwitchRow(
            icon: Icons.view_sidebar_outlined,
            title: 'Compact Sidebar',
            subtitle: 'Collapse sidebar to icon-only mode',
            value: s.compactSidebar,
            onChanged: (v) => _updateDraft(s.copyWith(compactSidebar: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.animation_rounded,
            title: 'Smooth Animations',
            subtitle: 'Enable interface transitions and smooth scrolling',
            value: s.enableAnimations,
            onChanged: (v) => _updateDraft(s.copyWith(enableAnimations: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                icon,
                size: 20,
                color: bgColor == const Color(0xFF0F172A) ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. PRINTER CATEGORY
  Widget _buildPrinterCategory(AppSettings s, AsyncValue<List<Printer>> printersAsync) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.print_rounded,
        title: 'Default Printer',
        children: [
          // Detected Printer Status Banner matching settings.png
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.print_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.defaultPrinterName ?? 'OneNote (Desktop)',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text('Ready', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Default printer',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Printer selector dropdown
          const Text('Select Printer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          printersAsync.when(
            data: (printers) {
              if (printers.isEmpty) {
                return const Text('No printers found on this system.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)));
              }
              final currentValue = printers.any((p) => p.name == s.defaultPrinterName)
                  ? s.defaultPrinterName
                  : (printers.isNotEmpty ? printers.first.name : null);

              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentValue,
                    isExpanded: true,
                    items: printers.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.name,
                        child: Text('${p.name} ${p.isDefault ? "(System Default)" : ""}', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _updateDraft(s.copyWith(defaultPrinterName: val));
                      }
                    },
                  ),
                ),
              );
            },
            loading: () => const Text('Detecting printers...'),
            error: (e, _) => Text('Error detecting printers: $e'),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => ref.refresh(availablePrintersProvider),
                icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF475569)),
                label: const Text('Refresh Printers', style: TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test print sent to default printer.')),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 14, color: Color(0xFF2563EB)),
                label: const Text('Test Print', style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.tune_rounded,
        title: 'Printer Behavior',
        children: [
          _buildSwitchRow(
            icon: Icons.save_as_outlined,
            title: 'Remember selected printer',
            subtitle: 'Keep printer selection across application restarts',
            value: s.rememberSelectedPrinter,
            onChanged: (v) => _updateDraft(s.copyWith(rememberSelectedPrinter: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.auto_mode_rounded,
            title: 'Automatically select system default',
            subtitle: 'Fall back to Windows default printer when disconnected',
            value: s.autoSelectSystemDefault,
            onChanged: (v) => _updateDraft(s.copyWith(autoSelectSystemDefault: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.info_outline_rounded,
            title: 'Show printer status',
            subtitle: 'Display status bar printer indicator in real time',
            value: s.showPrinterStatus,
            onChanged: (v) => _updateDraft(s.copyWith(showPrinterStatus: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.warning_amber_rounded,
            title: 'Warn when printer is offline',
            subtitle: 'Alert before sending print jobs to offline queues',
            value: s.warnWhenOffline,
            onChanged: (v) => _updateDraft(s.copyWith(warnWhenOffline: v)),
          ),
        ],
      ),
    );
  }

  // 4. PRINT DEFAULTS CATEGORY
  Widget _buildPrintDefaultsCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.description_outlined,
        title: 'Standard Defaults',
        children: [
          _buildDropdownRow<String>(
            icon: Icons.crop_portrait_rounded,
            title: 'Default Paper',
            subtitle: 'Paper loaded by default for new print jobs',
            value: s.defaultPaperPresetId,
            items: StandardPaperPresets.all.map((p) => p.id).toList(),
            itemLabels: StandardPaperPresets.all.map((p) => p.name).toList(),
            onChanged: (v) => _updateDraft(s.copyWith(defaultPaperPresetId: v)),
          ),
          const Divider(height: 18),
          _buildSegmentedRow(
            icon: Icons.screen_rotation_outlined,
            title: 'Default Orientation',
            subtitle: 'Page orientation for imported documents',
            current: s.defaultOrientation,
            options: const ['Portrait', 'Landscape'],
            onSelected: (v) => _updateDraft(s.copyWith(defaultOrientation: v)),
          ),
          const Divider(height: 18),
          _buildSegmentedRow(
            icon: Icons.palette_outlined,
            title: 'Default Color Mode',
            subtitle: 'Standard ink output mode',
            current: s.defaultColorMode,
            options: const ['Color', 'Black & White'],
            onSelected: (v) => _updateDraft(s.copyWith(defaultColorMode: v)),
          ),
          const Divider(height: 18),
          _buildDropdownRow<String>(
            icon: Icons.flip_to_back_outlined,
            title: 'Default Sides',
            subtitle: 'Duplex printing behavior',
            value: s.defaultPrintSides,
            items: const ['Single-sided', 'Duplex Long Edge', 'Duplex Short Edge'],
            onChanged: (v) => _updateDraft(s.copyWith(defaultPrintSides: v)),
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.speed_rounded,
        title: 'Resolution & Scaling',
        children: [
          _buildSegmentedRow(
            icon: Icons.high_quality_rounded,
            title: 'Print Resolution (DPI)',
            subtitle: 'Hardware rendering density for printouts',
            current: '${s.defaultDpi} DPI',
            options: const ['150 DPI', '300 DPI', '600 DPI'],
            onSelected: (v) {
              final dpi = int.parse(v.split(' ').first);
              _updateDraft(s.copyWith(defaultDpi: dpi));
            },
          ),
          const Divider(height: 18),
          _buildDropdownRow<String>(
            icon: Icons.aspect_ratio_outlined,
            title: 'Default Scaling',
            subtitle: 'Fit or stretch behavior for document prints',
            value: s.defaultScaling,
            items: const ['Actual Size', 'Fit to Page', 'Fill Page'],
            onChanged: (v) => _updateDraft(s.copyWith(defaultScaling: v)),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.copy_rounded,
            title: 'Default Copies',
            subtitle: 'Initial copy count for newly opened files',
            value: s.defaultDocCopies,
            onChanged: (v) => _updateDraft(s.copyWith(defaultDocCopies: v)),
          ),
        ],
      ),
    );
  }

  // 5. PAPER & LAYOUT CATEGORY
  Widget _buildPaperLayoutCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.margin_outlined,
        title: 'Paper Margins',
        children: [
          _buildStepperRow(
            icon: Icons.border_top_rounded,
            title: 'Top Margin (${s.measurementUnit})',
            subtitle: 'Spacing from top paper edge',
            value: s.paperMarginTopMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(paperMarginTopMm: v.toDouble())),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.border_bottom_rounded,
            title: 'Bottom Margin (${s.measurementUnit})',
            subtitle: 'Spacing from bottom paper edge',
            value: s.paperMarginBottomMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(paperMarginBottomMm: v.toDouble())),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.border_left_rounded,
            title: 'Left Margin (${s.measurementUnit})',
            subtitle: 'Spacing from left paper edge',
            value: s.paperMarginLeftMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(paperMarginLeftMm: v.toDouble())),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.border_right_rounded,
            title: 'Right Margin (${s.measurementUnit})',
            subtitle: 'Spacing from right paper edge',
            value: s.paperMarginRightMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(paperMarginRightMm: v.toDouble())),
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.crop_outlined,
        title: 'Photo / Card Layout',
        children: [
          _buildStepperRow(
            icon: Icons.view_column_outlined,
            title: 'Card Gap (mm)',
            subtitle: 'Spacing between cards on 4R sheet',
            value: s.defaultIdGapMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(defaultIdGapMm: v.toDouble())),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.content_cut_rounded,
            title: 'Cut Gap (mm)',
            subtitle: 'Dashed scissor line spacing',
            value: s.cutGapMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(cutGapMm: v.toDouble())),
          ),
          const Divider(height: 18),
          _buildStepperRow(
            icon: Icons.photo_size_select_actual_outlined,
            title: 'Paper Margin (mm)',
            subtitle: 'Padding from sheet border',
            value: s.defaultIdMarginMm.round(),
            onChanged: (v) => _updateDraft(s.copyWith(defaultIdMarginMm: v.toDouble())),
          ),
        ],
      ),
    );
  }

  // 6. IMAGE PROCESSING CATEGORY
  Widget _buildImageProcessingCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.tune_rounded,
        title: 'Default Image Enhancement',
        children: [
          _buildSliderRow(
            icon: Icons.brightness_6_rounded,
            title: 'Brightness',
            value: s.defaultBrightness,
            min: -50,
            max: 50,
            onChanged: (v) => _updateDraft(s.copyWith(defaultBrightness: v)),
          ),
          const Divider(height: 18),
          _buildSliderRow(
            icon: Icons.contrast_rounded,
            title: 'Contrast',
            value: s.defaultContrast,
            min: -50,
            max: 50,
            onChanged: (v) => _updateDraft(s.copyWith(defaultContrast: v)),
          ),
          const Divider(height: 18),
          _buildSliderRow(
            icon: Icons.blur_on_rounded,
            title: 'Sharpness',
            value: s.defaultSharpness,
            min: 0,
            max: 100,
            onChanged: (v) => _updateDraft(s.copyWith(defaultSharpness: v)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _updateDraft(s.copyWith(
                defaultBrightness: 0.0,
                defaultContrast: 0.0,
                defaultSharpness: 0.0,
              ));
            },
            child: const Text('Reset Image Defaults'),
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.auto_fix_high_rounded,
        title: 'Processing Rules',
        children: [
          _buildSwitchRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Auto enhance',
            subtitle: 'Automatically adjust lighting and contrast on load',
            value: s.imageAutoEnhance,
            onChanged: (v) => _updateDraft(s.copyWith(imageAutoEnhance: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.rotate_90_degrees_ccw_rounded,
            title: 'Auto rotate',
            subtitle: 'Automatically orient portrait photos upright',
            value: s.imageAutoRotate,
            onChanged: (v) => _updateDraft(s.copyWith(imageAutoRotate: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.aspect_ratio_rounded,
            title: 'Preserve aspect ratio',
            subtitle: 'Never stretch or distort customer faces or text',
            value: s.preserveAspectRatio,
            onChanged: (v) => _updateDraft(s.copyWith(preserveAspectRatio: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.crop_free_rounded,
            title: 'Prevent accidental cropping',
            subtitle: 'Add minimum 1.5% margin around detected ID cards',
            value: s.preventAccidentalCropping,
            onChanged: (v) => _updateDraft(s.copyWith(preventAccidentalCropping: v)),
          ),
        ],
      ),
    );
  }

  // 7. DOCUMENT PROCESSING CATEGORY
  Widget _buildDocumentProcessingCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.picture_as_pdf_rounded,
        title: 'PDF Processing',
        children: [
          _buildDropdownRow<String>(
            icon: Icons.high_quality_rounded,
            title: 'Render Quality',
            subtitle: 'Raster density for PDF preview and print engine',
            value: s.pdfRenderQuality,
            items: const ['Standard (300 DPI)', 'Draft (150 DPI)', 'High (600 DPI)'],
            onChanged: (v) => _updateDraft(s.copyWith(pdfRenderQuality: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.straighten_rounded,
            title: 'Preserve page size',
            subtitle: 'Keep original vector dimensions from source PDF',
            value: s.preservePdfPageSize,
            onChanged: (v) => _updateDraft(s.copyWith(preservePdfPageSize: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.screen_rotation_outlined,
            title: 'Auto rotate pages',
            subtitle: 'Rotate landscape pages to match paper feed',
            value: s.pdfAutoRotate,
            onChanged: (v) => _updateDraft(s.copyWith(pdfAutoRotate: v)),
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.article_outlined,
        title: 'Document Printing Rules',
        children: [
          _buildSwitchRow(
            icon: Icons.fit_screen_rounded,
            title: 'Fit content to page',
            subtitle: 'Scale documents automatically to prevent edge clipping',
            value: s.docFitContentToPage,
            onChanged: (v) => _updateDraft(s.copyWith(docFitContentToPage: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.lock_outline_rounded,
            title: 'Auto-detect password PDFs',
            subtitle: 'Inspect encryption and prompt for unlock password',
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  // 8. SHOP INFORMATION CATEGORY
  Widget _buildShopInformationCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.storefront_rounded,
        title: 'Business Information',
        children: [
          _buildTextField('Shop / Studio Name', _shopNameCtrl),
          const SizedBox(height: 12),
          _buildTextField('Address', _shopAddressCtrl),
          const SizedBox(height: 12),
          _buildTextField('Phone Number', _shopPhoneCtrl),
          const SizedBox(height: 12),
          _buildTextField('Email Address', _shopEmailCtrl),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.receipt_long_rounded,
        title: 'Invoice & Receipt Details',
        children: [
          _buildTextField('GST / Tax ID', _shopGstCtrl),
          const SizedBox(height: 12),
          _buildTextField('Receipt Footer Note', _receiptFooterCtrl, maxLines: 3),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _saveAllChanges,
                icon: const Icon(Icons.check, size: 15, color: Colors.white),
                label: const Text('Save Business Info', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  _shopNameCtrl.clear();
                  _shopAddressCtrl.clear();
                  _shopPhoneCtrl.clear();
                  _shopEmailCtrl.clear();
                  _shopGstCtrl.clear();
                  _receiptFooterCtrl.clear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 9. PRICING & RATES CATEGORY
  Widget _buildPricingRatesCategory() {
    final pricingItems = ref.watch(pricingProvider);

    return _buildCard(
      icon: Icons.currency_rupee_rounded,
      title: 'Active Pricing & Rates',
      children: [
        const Text(
          'Rates applied to print jobs and sales profit calculations:',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: pricingItems.map((item) {
            return Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.unit,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹ ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(navIndexProvider.notifier).state = 4; // Navigate to Pricing & Rates
          },
          icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
          label: const Text('Open Full Pricing & Rates Editor', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
        ),
      ],
    );
  }

  // INVENTORY & STOCK CATEGORY
  Widget _buildInventoryCategory() {
    final inventory = ref.watch(inventoryProvider);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Physical Materials & Ink Inventory',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track remaining paper sheets, PVC cards, lamination pouches, and ink levels in real-time.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Inventory Stock?'),
                    content: const Text('This will reset all material quantities and ink levels to default factory print-shop stock.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        child: const Text('Reset to Defaults', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await inventoryNotifier.resetToDefaults();
                }
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 15, color: Color(0xFF475569)),
              label: const Text('Reset Stock', style: TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid of Inventory Cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: inventory.map((item) {
            final isLow = item.isLowStock;
            final isInk = item.unit == '%';

            return Container(
              width: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLow ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLow ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isLow ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          isLow ? 'LOW' : 'OK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isLow ? const Color(0xFFD97706) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isInk ? '${item.currentStock.toStringAsFixed(1)} %' : '${item.currentStock.toInt()} ${item.unit}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isLow ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Min: ${item.minThreshold.toInt()} ${item.unit}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // Restock Buttons
                  Row(
                    children: [
                      InkWell(
                        onTap: () => inventoryNotifier.deductStock(item.id, isInk ? 5.0 : 50.0),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInk ? '-5%' : '-50',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => inventoryNotifier.addStock(item.id, isInk ? 10.0 : 100.0),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInk ? '+10%' : '+100',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => inventoryNotifier.addStock(item.id, isInk ? 50.0 : 500.0),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInk ? '+50%' : '+500',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 10. STORAGE & BACKUP CATEGORY
  Widget _buildStorageBackupCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.folder_outlined,
        title: 'Storage Location',
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Directory', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(s.storageLocation, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace')),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder path updated.')),
                  );
                },
                child: const Text('Change Location'),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Temporary Cached Files', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('0 MB temporary files stored', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temporary files purged.')),
                  );
                },
                child: const Text('Clear Temp Files'),
              ),
            ],
          ),
        ],
      ),
      rightCard: _buildCard(
        icon: Icons.backup_outlined,
        title: 'Automatic Backup',
        children: [
          _buildSwitchRow(
            icon: Icons.cloud_done_outlined,
            title: 'Enable Auto Backup',
            subtitle: 'Regularly back up history and pricing presets',
            value: s.autoBackupEnabled,
            onChanged: (v) => _updateDraft(s.copyWith(autoBackupEnabled: v)),
          ),
          const Divider(height: 18),
          _buildDropdownRow<String>(
            icon: Icons.schedule_rounded,
            title: 'Backup Frequency',
            subtitle: 'Schedule interval for automatic exports',
            value: s.backupFrequency,
            items: const ['Daily', 'Weekly', 'Monthly'],
            onChanged: (v) => _updateDraft(s.copyWith(backupFrequency: v)),
          ),
        ],
      ),
    );
  }

  // 11. PRINT HISTORY CATEGORY
  Widget _buildPrintHistoryCategory(AppSettings s) {
    return _buildTwoColumnGrid(
      leftCard: _buildCard(
        icon: Icons.history_rounded,
        title: 'Print History Settings',
        children: [
          _buildSwitchRow(
            icon: Icons.list_alt_rounded,
            title: 'Enable print history',
            subtitle: 'Keep a searchable record of past print operations',
            value: s.enablePrintHistory,
            onChanged: (v) => _updateDraft(s.copyWith(enablePrintHistory: v)),
          ),
          const Divider(height: 18),
          _buildDropdownRow<String>(
            icon: Icons.date_range_rounded,
            title: 'Retention Period',
            subtitle: 'Automatically purge records older than',
            value: s.historyRetention,
            items: const ['7 days', '30 days', '90 days', 'Forever'],
            onChanged: (v) => _updateDraft(s.copyWith(historyRetention: v)),
          ),
          const Divider(height: 18),
          _buildSwitchRow(
            icon: Icons.image_search_rounded,
            title: 'Store thumbnails',
            subtitle: 'Save miniature previews of printed documents',
            value: s.storeThumbnails,
            onChanged: (v) => _updateDraft(s.copyWith(storeThumbnails: v)),
          ),
        ],
      ),
      rightCard: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Clear all saved print history records. This action cannot be undone.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Print History?'),
                    content: const Text('Are you sure you want to permanently delete all print history records?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        child: const Text('Clear History', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(historyProvider.notifier).clearAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Print history cleared.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
              label: const Text('Clear All Print History', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 12. KEYBOARD SHORTCUTS CATEGORY
  Widget _buildKeyboardShortcutsCategory() {
    final shortcuts = [
      {'key': 'Ctrl + P', 'action': 'Print active document / sheet'},
      {'key': 'Ctrl + N', 'action': 'New Document / Open File'},
      {'key': 'Ctrl + O', 'action': 'Open document or photo file'},
      {'key': 'Ctrl + S', 'action': 'Save Project / Export PDF'},
      {'key': 'Ctrl + Z', 'action': 'Undo last crop or adjustment'},
      {'key': 'Ctrl + Y', 'action': 'Redo last undone action'},
      {'key': '+ / -', 'action': 'Zoom in / Zoom out preview canvas'},
      {'key': '0', 'action': 'Fit paper preview to window'},
    ];

    return _buildCard(
      icon: Icons.keyboard_outlined,
      title: 'Keyboard Shortcuts',
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(3),
          },
          children: shortcuts.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        item['key']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    item['action']!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 13. ABOUT CATEGORY
  Widget _buildAboutCategory() {
    return _buildCard(
      icon: Icons.info_outline_rounded,
      title: 'FastPrint Studio',
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.print_rounded, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FastPrint Studio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Xerox & Studio Pro Desktop Edition',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  'Version 1.2.0 (Build 2026.09)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24),
        _buildInfoRow('Printer Engine', 'Windows Printing Spooler API (Win32 / PDFium)'),
        const SizedBox(height: 8),
        _buildInfoRow('PDF Engine', 'Syncfusion PDF & PDFium Native High-DPI Vector Engine'),
        const SizedBox(height: 8),
        _buildInfoRow('Target OS', 'Windows 10 / 11 Desktop (x64)'),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('FastPrint Studio is up to date.')),
                );
              },
              child: const Text('Check for Updates'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              child: const Text('View License'),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildTwoColumnGrid({required Widget leftCard, required Widget rightCard}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 850) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftCard),
              const SizedBox(width: 16),
              Expanded(child: rightCard),
            ],
          );
        } else {
          return Column(
            children: [
              leftCard,
              const SizedBox(height: 16),
              rightCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: Switch(
            value: value,
            activeTrackColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    List<String>? itemLabels,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              items: items.map((item) {
                final idx = items.indexOf(item);
                final label = itemLabels != null && idx < itemLabels.length ? itemLabels[idx] : item.toString();
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String current,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Row(
          children: options.map((opt) {
            final isSelected = current.toLowerCase() == opt.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: InkWell(
                onTap: () => onSelected(opt),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepperRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Icon(Icons.remove, size: 13, color: Color(0xFF475569)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Icon(Icons.add, size: 13, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              '${value.round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
            ),
          ),
          onChanged: (_) {
            setState(() {
              _hasUnsavedChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
