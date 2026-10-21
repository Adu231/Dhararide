import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/main.dart';

void main() {
  testWidgets('DharRide smoke test on desktop size', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const ProviderScope(child: DharRideApp()));
    expect(find.byType(DharRideApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('DharRide mobile screen test (prevents blank screen crash)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const ProviderScope(child: DharRideApp()));
    expect(find.byType(DharRideApp), findsOneWidget);
    // Verify splash screen or initial elements render without throwing exception
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
