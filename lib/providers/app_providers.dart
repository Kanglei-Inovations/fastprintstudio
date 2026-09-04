import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../core/models/app_settings.dart';
import '../core/models/print_history_item.dart';
import '../services/printing/printer_service.dart';
import '../services/printing/printing_service_impl.dart';
import '../services/storage/history_storage.dart';
import '../services/storage/settings_storage.dart';
import 'inventory_provider.dart';

/// Holds a file that was opened with FastPrint Studio or dragged into the landing hub
class LandingFileData {
  final String filePath;
  final String fileName;
  final Uint8List bytes;
  final int fileSizeBytes;
  final String extension;
  final DateTime modifiedAt;

  const LandingFileData({
    required this.filePath,
    required this.fileName,
    required this.bytes,
    required this.fileSizeBytes,
    required this.extension,
    required this.modifiedAt,
  });

  bool get isImage => ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tif', '.tiff']
      .contains(extension.toLowerCase());
  bool get isPdf => extension.toLowerCase() == '.pdf';
  bool get isWord => ['.doc', '.docx'].contains(extension.toLowerCase());
  bool get isExcel => ['.xls', '.xlsx'].contains(extension.toLowerCase());
  bool get isPowerPoint => ['.ppt', '.pptx'].contains(extension.toLowerCase());
  bool get isDocument => isPdf || isWord || isExcel || isPowerPoint || extension.toLowerCase() == '.txt';

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(modifiedAt);
  }

  String get formatBadge {
    final clean = extension.replaceAll('.', '').toUpperCase();
    if (clean.isEmpty) return 'FILE';
    return clean;
  }
}

/// Navigation index provider (0: Home, 1: Aadhaar/ID, 2: Passport, 3: Stamp, 4: History, 5: Settings, 7: Open With Landing)
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Active file waiting for studio destination selection
final landingFileProvider = StateProvider<LandingFileData?>((ref) => null);

/// Flag to automatically trigger the Edit Image modal upon landing in Photo Printing
final shouldAutoOpenPhotoEditProvider = StateProvider<bool>((ref) => false);

/// Pending photo data waiting to be opened with Edit Image in Photo Printing
final pendingPhotoImportProvider = StateProvider<({Uint8List bytes, String fileName})?>((ref) => null);

/// App Settings Notifier
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsStorage.loadSettings();
    state = settings;
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await SettingsStorage.saveSettings(newSettings);
  }

  Future<void> updateDefaultPrinter(String? printerName) async {
    final updated = state.copyWith(defaultPrinterName: printerName);
    await updateSettings(updated);
  }

  Future<void> updateDefaultDpi(int dpi) async {
    final updated = state.copyWith(defaultDpi: dpi);
    await updateSettings(updated);
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await SettingsStorage.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

/// Printer service provider
final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrintingServiceImpl();
});

/// Available printers on the current system
final availablePrintersProvider = FutureProvider<List<Printer>>((ref) async {
  final printerService = ref.watch(printerServiceProvider);
  return await printerService.getPrinters();
});

/// Print History Notifier
class PrintHistoryNotifier extends StateNotifier<List<PrintHistoryItem>> {
  final Ref _ref;

  PrintHistoryNotifier(this._ref) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = await HistoryStorage.loadHistory();
  }

  Future<void> addRecord(PrintHistoryItem item) async {
    await HistoryStorage.addHistoryItem(item);
    state = [item, ...state];
    try {
      await _ref.read(inventoryProvider.notifier).deductForPrintJob(item);
    } catch (_) {}
  }

  Future<void> updateRecord(PrintHistoryItem updated) async {
    state = [
      for (final it in state)
        if (it.id == updated.id) updated else it,
    ];
    await HistoryStorage.saveAll(state);
  }

  Future<void> togglePaymentStatus(String id) async {
    final item = state.firstWhere((it) => it.id == id, orElse: () => state.first);
    final nextStatus = item.paymentStatus == 'Paid' ? 'Due' : 'Paid';
    await updateRecord(item.copyWith(paymentStatus: nextStatus));
  }

  Future<void> clearAll() async {
    await HistoryStorage.clearHistory();
    state = [];
  }
}

final historyProvider = StateNotifierProvider<PrintHistoryNotifier, List<PrintHistoryItem>>((ref) {
  return PrintHistoryNotifier(ref);
});
