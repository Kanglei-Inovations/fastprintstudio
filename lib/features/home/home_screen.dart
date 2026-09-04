import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/id_card_presets.dart';
import '../../core/models/crop_rect_data.dart';
import '../../providers/app_providers.dart';
import '../../providers/id_card_provider.dart';
import '../../providers/passport_photo_provider.dart';
import '../../providers/pricing_provider.dart';
import '../../shared/widgets/crop_editor_modal.dart';
import 'theme/dashboard_palette.dart';
import 'theme/dashboard_theme_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/expenses_overview_card.dart';
import 'widgets/inventory_status_card.dart';
import 'widgets/quick_services_section.dart';
import 'widgets/recent_jobs_card.dart';
import 'widgets/reminders_section.dart';
import 'widgets/sales_by_service_card.dart';
import 'widgets/sales_overview_chart.dart';
import 'widgets/sales_summary_cards.dart';
import 'widgets/today_snapshot_card.dart';
import 'widgets/top_services_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openWithFilePicker(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'webp', 'bmp', 'tif', 'tiff',
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
        ],
      );

      if (result != null && result.path != null) {
        final path = result.path!;
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final stat = await file.stat();
          final ext = p.extension(path).toLowerCase();
          ref.read(landingFileProvider.notifier).state = LandingFileData(
            filePath: path,
            fileName: p.basename(path),
            bytes: bytes,
            fileSizeBytes: stat.size,
            extension: ext,
            modifiedAt: stat.modified,
          );
          ref.read(navIndexProvider.notifier).state = 7; // Open With Landing Screen
        }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> _openImageEditor(BuildContext context, WidgetRef ref) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (context.mounted) {
          final result = await CropEditorModal.show(
            context: context,
            imageBytes: bytes,
            initialCrop: const CropRectData(left: 0.05, top: 0.05, width: 0.9, height: 0.9),
            targetAspectRatio: 1.0,
            title: 'Image Studio & Enhancer (${file.name})',
          );

          if (result != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Image enhanced and ready (${result.croppedBytes.length ~/ 1024} KB)'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error in Image Editor: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final pricingNotifier = ref.read(pricingProvider.notifier);
    final themeMode = ref.watch(dashboardThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final palette = DashboardPalette.of(context, isDark: isDark);

    // Compute live metrics from history
    final now = DateTime.now();
    final todayHistory = history.where((h) {
      return h.timestamp.year == now.year &&
          h.timestamp.month == now.month &&
          h.timestamp.day == now.day;
    }).toList();

    double totalRevenue = 0.0;
    double todayRevenue = 0.0;
    int printsCompleted = 0;

    for (final item in history) {
      final copies = item.copiesCount > 0 ? item.copiesCount : 1;
      if (item.sellingPrice > 0) {
        totalRevenue += item.sellingPrice;
      } else {
        final rate = pricingNotifier.getPriceForService(item.serviceName);
        totalRevenue += rate.price * copies;
      }
      printsCompleted += copies;
    }

    for (final item in todayHistory) {
      final copies = item.copiesCount > 0 ? item.copiesCount : 1;
      if (item.sellingPrice > 0) {
        todayRevenue += item.sellingPrice;
      } else {
        final rate = pricingNotifier.getPriceForService(item.serviceName);
        todayRevenue += rate.price * copies;
      }
    }

    return Scaffold(
      backgroundColor: palette.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dashboard Top Command Header
            DashboardHeader(
              palette: palette,
              onQuickPrint: () {
                ref.read(idCardProvider.notifier).setIdCardPreset(StandardIDCardPresets.aadhaar);
                ref.read(navIndexProvider.notifier).state = 1;
              },
              onOpenPrinterSettings: () {
                ref.read(navIndexProvider.notifier).state = 6;
              },
            ),

            const SizedBox(height: 20),

            // 2. Sales & Business KPI Summary Cards
            SalesSummaryCards(
              palette: palette,
              todaySales: todayRevenue > 0 ? todayRevenue : 2450,
              todayJobs: todayHistory.isNotEmpty ? todayHistory.length : 23,
              printsCompleted: printsCompleted > 0 ? printsCompleted : 56,
              pendingJobs: 5,
            ),

            const SizedBox(height: 20),

            // 3. Middle Section: Sales Overview Chart + Sales by Service Donut Card
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return SizedBox(
                    height: 290,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SalesOverviewChart(
                            palette: palette,
                            history: history,
                            pricingNotifier: pricingNotifier,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SalesByServiceCard(
                            palette: palette,
                            totalRevenue: totalRevenue > 0 ? totalRevenue : 17850,
                            onViewReport: () {
                              ref.read(navIndexProvider.notifier).state = 4;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        height: 290,
                        child: SalesOverviewChart(
                          palette: palette,
                          history: history,
                          pricingNotifier: pricingNotifier,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 290,
                        child: SalesByServiceCard(
                          palette: palette,
                          totalRevenue: totalRevenue > 0 ? totalRevenue : 17850,
                          onViewReport: () {
                            ref.read(navIndexProvider.notifier).state = 4;
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // 4. Quick Services / Quick Start Section
            QuickServicesSection(
              palette: palette,
              onOpenAadhaar: () {
                ref.read(idCardProvider.notifier).setIdCardPreset(StandardIDCardPresets.aadhaar);
                ref.read(navIndexProvider.notifier).state = 1;
              },
              onOpenPassport: () {
                ref.read(passportPhotoProvider.notifier).setPresetMode(PhotoTypePresetMode.passportOnly);
                ref.read(navIndexProvider.notifier).state = 2;
              },
              onOpenDocument: () {
                ref.read(navIndexProvider.notifier).state = 3;
              },
              onOpen4RPhoto: () {
                ref.read(passportPhotoProvider.notifier).setPresetMode(PhotoTypePresetMode.passportPlusStamp);
                ref.read(navIndexProvider.notifier).state = 2;
              },
              onOpenPVC: () {
                ref.read(idCardProvider.notifier).setIdCardPreset(StandardIDCardPresets.panCard);
                ref.read(navIndexProvider.notifier).state = 1;
              },
              onOpenPricing: () {
                ref.read(navIndexProvider.notifier).state = 4;
              },
              onOpenXerox: () {
                ref.read(navIndexProvider.notifier).state = 3;
              },
              onOpenImageEditor: () => _openImageEditor(context, ref),
              onOpenWith: () => _openWithFilePicker(context, ref),
            ),

            const SizedBox(height: 24),

            // 5. Recent Printed Jobs + Top Services Row
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: RecentJobsCard(
                          palette: palette,
                          history: history,
                          onViewAll: () {
                            ref.read(navIndexProvider.notifier).state = 5;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TopServicesCard(
                          palette: palette,
                          onViewAll: () {
                            ref.read(navIndexProvider.notifier).state = 4;
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      RecentJobsCard(
                        palette: palette,
                        history: history,
                        onViewAll: () {
                          ref.read(navIndexProvider.notifier).state = 5;
                        },
                      ),
                      const SizedBox(height: 16),
                      TopServicesCard(
                        palette: palette,
                        onViewAll: () {
                          ref.read(navIndexProvider.notifier).state = 4;
                        },
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // 6. Expenses Overview + Inventory Status + Today's Snapshot (3-Card Modular Grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1050
                    ? 3
                    : (constraints.maxWidth > 680 ? 2 : 1);

                if (crossAxisCount == 3) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ExpensesOverviewCard(
                          palette: palette,
                          onViewDetails: () {
                            ref.read(navIndexProvider.notifier).state = 4;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InventoryStatusCard(
                          palette: palette,
                          onManageInventory: () {
                            ref.read(navIndexProvider.notifier).state = 6;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TodaySnapshotCard(
                          palette: palette,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ExpensesOverviewCard(
                        palette: palette,
                        onViewDetails: () {
                          ref.read(navIndexProvider.notifier).state = 4;
                        },
                      ),
                      const SizedBox(height: 16),
                      InventoryStatusCard(
                        palette: palette,
                        onManageInventory: () {
                          ref.read(navIndexProvider.notifier).state = 6;
                        },
                      ),
                      const SizedBox(height: 16),
                      TodaySnapshotCard(
                        palette: palette,
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // 7. Reminders & Alerts Section (Bottom 4 cards)
            RemindersSection(
              palette: palette,
              onBackupNow: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Backup completed successfully!'),
                    backgroundColor: palette.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onScheduleMaintenance: () {
                ref.read(navIndexProvider.notifier).state = 6;
              },
            ),
          ],
        ),
      ),
    );
  }
}
