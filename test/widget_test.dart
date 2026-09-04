import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fastprintstudio/main.dart';

void main() {
  testWidgets('FastPrintApp smoke test and service navigation', (WidgetTester tester) async {
    // Configure tester window to desktop standard dimensions
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: FastPrintApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard rendered
    expect(find.text('Dashboard'), findsWidgets);

    // Expand sidebar to verify branding and labels
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('FastPrint Studio'), findsWidgets);
    expect(find.text('Aadhaar / ID Card'), findsWidgets);
    expect(find.text('Photo Printing'), findsWidgets);

    // Navigate to Photo Printing via first matching icon
    await tester.tap(find.byIcon(Icons.portrait_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Photo Printing Studio'), findsWidgets);

    // Navigate to Aadhaar / ID Card via first matching icon
    await tester.tap(find.byIcon(Icons.badge_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('No ID card selected'), findsWidgets);
  });
}
