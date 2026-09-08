import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastprintstudio/features/id_card/id_card_screen.dart';
import 'package:fastprintstudio/features/passport_photo/passport_photo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Studio Keyboard Shortcuts Test Suite', () {
    testWidgets('IdCardScreen has CallbackShortcuts registered with all key combinations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IdCardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find CallbackShortcuts widget
      final shortcutFinder = find.byType(CallbackShortcuts);
      expect(shortcutFinder, findsWidgets);

      final callbackShortcutsWidget = tester.widget<CallbackShortcuts>(shortcutFinder.first);
      final bindings = callbackShortcutsWidget.bindings;

      // Verify all required shortcuts are present
      // Ctrl+P, Ctrl+S, Ctrl+E, Ctrl+O, Ctrl+N, Ctrl+Z, Ctrl+Y, Ctrl+Shift+Z
      final ctrlP = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyP &&
          k.control);
      final ctrlS = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyS &&
          k.control);
      final ctrlE = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyE &&
          k.control);
      final ctrlO = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyO &&
          k.control);
      final ctrlN = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyN &&
          k.control);
      final ctrlZ = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyZ &&
          k.control &&
          !k.shift);
      final ctrlY = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyY &&
          k.control);

      expect(ctrlP, isTrue, reason: 'Ctrl+P must be bound on IdCardScreen');
      expect(ctrlS, isTrue, reason: 'Ctrl+S must be bound on IdCardScreen');
      expect(ctrlE, isTrue, reason: 'Ctrl+E must be bound on IdCardScreen');
      expect(ctrlO, isTrue, reason: 'Ctrl+O must be bound on IdCardScreen');
      expect(ctrlN, isTrue, reason: 'Ctrl+N must be bound on IdCardScreen');
      expect(ctrlZ, isTrue, reason: 'Ctrl+Z must be bound on IdCardScreen');
      expect(ctrlY, isTrue, reason: 'Ctrl+Y must be bound on IdCardScreen');

      // Also verify macOS Meta/Cmd keys are bound
      final metaP = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyP &&
          k.meta);
      final metaS = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyS &&
          k.meta);
      expect(metaP, isTrue, reason: 'Meta+P must be bound on IdCardScreen for macOS');
      expect(metaS, isTrue, reason: 'Meta+S must be bound on IdCardScreen for macOS');
    });

    testWidgets('PassportPhotoScreen has CallbackShortcuts registered with all key combinations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PassportPhotoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find CallbackShortcuts widget
      final shortcutFinder = find.byType(CallbackShortcuts);
      expect(shortcutFinder, findsWidgets);

      final callbackShortcutsWidget = tester.widget<CallbackShortcuts>(shortcutFinder.first);
      final bindings = callbackShortcutsWidget.bindings;

      // Verify all required shortcuts are present
      final ctrlP = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyP &&
          k.control);
      final ctrlS = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyS &&
          k.control);
      final ctrlE = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyE &&
          k.control);
      final ctrlO = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyO &&
          k.control);
      final ctrlN = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyN &&
          k.control);
      final ctrlZ = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyZ &&
          k.control &&
          !k.shift);
      final ctrlY = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyY &&
          k.control);

      expect(ctrlP, isTrue, reason: 'Ctrl+P must be bound on PassportPhotoScreen');
      expect(ctrlS, isTrue, reason: 'Ctrl+S must be bound on PassportPhotoScreen');
      expect(ctrlE, isTrue, reason: 'Ctrl+E must be bound on PassportPhotoScreen');
      expect(ctrlO, isTrue, reason: 'Ctrl+O must be bound on PassportPhotoScreen');
      expect(ctrlN, isTrue, reason: 'Ctrl+N must be bound on PassportPhotoScreen');
      expect(ctrlZ, isTrue, reason: 'Ctrl+Z must be bound on PassportPhotoScreen');
      expect(ctrlY, isTrue, reason: 'Ctrl+Y must be bound on PassportPhotoScreen');

      // Also verify macOS Meta/Cmd keys are bound
      final metaP = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyP &&
          k.meta);
      final metaS = bindings.keys.any((k) =>
          k is SingleActivator &&
          k.trigger == LogicalKeyboardKey.keyS &&
          k.meta);
      expect(metaP, isTrue, reason: 'Meta+P must be bound on PassportPhotoScreen for macOS');
      expect(metaS, isTrue, reason: 'Meta+S must be bound on PassportPhotoScreen for macOS');
    });
  });
}
