import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/documents/document_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/id_card/id_card_screen.dart';
import 'features/landing/open_with_landing_screen.dart';
import 'features/passport_photo/passport_photo_screen.dart';
import 'features/pricing/pricing_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers/app_providers.dart';
import 'features/documents/providers/document_provider.dart';
import 'providers/id_card_provider.dart';
import 'providers/passport_photo_provider.dart';
import 'services/project/fps_project_service.dart';
import 'shared/widgets/desktop_scaffold.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Windows file associations for .fps project files & photos in background
  if (Platform.isWindows) {
    Future.microtask(() => FpsProjectService.registerWindowsFileAssociation());
  }

  runApp(ProviderScope(child: FastPrintApp(initialArgs: args)));
}

class FastPrintApp extends ConsumerWidget {
  final List<String> initialArgs;
  const FastPrintApp({super.key, this.initialArgs = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode.toLowerCase()) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: MainShellScreen(initialArgs: initialArgs),
    );
  }
}

class MainShellScreen extends ConsumerStatefulWidget {
  final List<String> initialArgs;
  const MainShellScreen({super.key, this.initialArgs = const []});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialFile());
  }

  Future<void> _handleInitialFile() async {
    if (widget.initialArgs.isEmpty) return;
    try {
      final filePath = widget.initialArgs.first;
      final ext = p.extension(filePath).toLowerCase();
      final file = File(filePath);
      if (await file.exists()) {
        if (ext == '.fps') {
          // Open FastPrint Studio project file according to its projectType
          final data = await FpsProjectService.loadFpsFromFile(filePath);
          if (data != null) {
            final type = data['projectType'] as String? ?? 'photo';
            if (type == 'id_card') {
              ref.read(navIndexProvider.notifier).state = 1; // ID Card Screen
              await ref.read(idCardProvider.notifier).loadProjectFromFps(filePath: filePath);
            } else if (type == 'document') {
              ref.read(navIndexProvider.notifier).state = 3; // Document Screen
              await ref.read(documentPrintProvider.notifier).loadProjectFromFps(filePath: filePath);
            } else {
              ref.read(navIndexProvider.notifier).state = 2; // Photo Screen
              await ref.read(passportPhotoProvider.notifier).loadProjectFromFps(filePath: filePath);
            }
          }
        } else {
          // File opened via "Open With FastPrint Studio" or double-click in Windows!
          // Land it on the new "Open With" Landing Screen and let user choose where to continue
          final bytes = await file.readAsBytes();
          final stat = await file.stat();
          final landingData = LandingFileData(
            filePath: filePath,
            fileName: p.basename(filePath),
            bytes: bytes,
            fileSizeBytes: stat.size,
            extension: ext,
            modifiedAt: stat.modified,
          );
          ref.read(landingFileProvider.notifier).state = landingData;
          ref.read(navIndexProvider.notifier).state = 7; // Open With Landing Screen
        }
      }
    } catch (e) {
      debugPrint('Error opening file passed from arguments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);

    Widget activeScreen;
    switch (navIndex) {
      case 0:
        activeScreen = const KeyedSubtree(key: ValueKey(0), child: HomeScreen());
        break;
      case 1:
        activeScreen = const KeyedSubtree(key: ValueKey(1), child: IdCardScreen());
        break;
      case 2:
        activeScreen = const KeyedSubtree(key: ValueKey(2), child: PassportPhotoScreen());
        break;
      case 3:
        activeScreen = const KeyedSubtree(key: ValueKey(3), child: DocumentScreen());
        break;
      case 4:
        activeScreen = const KeyedSubtree(key: ValueKey(4), child: PricingScreen());
        break;
      case 5:
        activeScreen = const KeyedSubtree(key: ValueKey(5), child: HistoryScreen());
        break;
      case 6:
        activeScreen = const KeyedSubtree(key: ValueKey(6), child: SettingsScreen());
        break;
      case 7:
        activeScreen = const KeyedSubtree(key: ValueKey(7), child: OpenWithLandingScreen());
        break;
      default:
        activeScreen = const KeyedSubtree(key: ValueKey(0), child: HomeScreen());
    }

    return DesktopScaffold(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 140),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.topLeft,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.014),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: activeScreen,
      ),
    );
  }
}
