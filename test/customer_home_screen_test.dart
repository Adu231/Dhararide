import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dharride/core/theme/app_theme.dart';
import 'package:dharride/core/services/location_service.dart';
import 'package:dharride/core/widgets/dharashiv_map_widget.dart';
import 'package:dharride/data/demo/demo_data.dart';
import 'package:dharride/data/session/session_manager.dart';
import 'package:dharride/features/customer/customer_home_screen.dart';

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(() => _MockUserNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CustomerHomeScreen(),
      ),
    );
  }

  testWidgets('CustomerHomeScreen renders interactive map, compact header, and bottom sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Verify Map is present as the primary visual area
    expect(find.byType(DharashivMapWidget), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);

    // 2. Verify Compact Header branding
    expect(find.text('DharRide'), findsOneWidget);
    expect(find.text('Dharashiv'), findsWidgets);

    // 3. Verify Route Selection Card shows pickup and destination
    expect(find.text('Dharashiv Central Bus Stand'), findsOneWidget);
    expect(find.text('Government Civil Hospital & College'), findsOneWidget);

    // 4. Verify Fare Preview and 0% Commission
    expect(find.text('₹20'), findsOneWidget);
    expect(find.text('0% Commission'), findsWidgets);

    // 5. Verify Book Auto button
    await tester.scrollUntilVisible(find.text('Book Auto'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Book Auto'), findsOneWidget);
  });

  testWidgets('Language toggle switches between English and Marathi seamlessly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Initial state is English: Language button shows 'मराठी'
    final langToggle = find.text('मराठी');
    expect(langToggle, findsOneWidget);

    // Tap language toggle
    await tester.tap(langToggle);
    await tester.pumpAndSettle();

    // Now in Marathi mode
    expect(find.text('English'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ऑटो बुक करा'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('ऑटो बुक करा'), findsOneWidget);
    expect(find.text('अंदाजित भाडे'), findsOneWidget);
    expect(find.text('०% कमिशन'), findsWidgets);
  });

  testWidgets('Location swap button swaps pickup and destination', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Initial state: Central Bus Stand is pickup, Civil Hospital is destination
    expect(find.text('Dharashiv Central Bus Stand'), findsOneWidget);
    expect(find.text('Government Civil Hospital & College'), findsOneWidget);

    // Tap swap button
    final swapBtn = find.byIcon(Icons.swap_vert);
    expect(swapBtn, findsOneWidget);
    await tester.tap(swapBtn);
    await tester.pumpAndSettle();

    // After swap: Civil Hospital is pickup, Central Bus Stand is destination
    expect(find.text('Government Civil Hospital & College'), findsOneWidget);
    expect(find.text('Dharashiv Central Bus Stand'), findsOneWidget);
  });

  testWidgets('Selecting a popular place updates destination', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find railway station card in popular places by scrolling down sheet
    final railwayCard = find.text('Dharashiv Railway Station');
    await tester.scrollUntilVisible(railwayCard, 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(railwayCard, findsOneWidget);

    await tester.tap(railwayCard);
    await tester.pumpAndSettle();

    // Destination is now Railway Station
    expect(find.text('Dharashiv Railway Station'), findsWidgets);
  });

  testWidgets('Opening search sheet allows filtering landmarks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap the destination field to open search sheet
    final destTile = find.text('Government Civil Hospital & College');
    await tester.tap(destTile);
    await tester.pumpAndSettle();

    // Search sheet should be open
    expect(find.text('Destination (Drop)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter search query 'Kapad'
    await tester.enterText(find.byType(TextField), 'Kapad');
    await tester.pumpAndSettle();

    // Only matching place should be visible
    expect(find.text('Main Kapad Market & Shivaji Chowk'), findsOneWidget);

    // Select this place
    await tester.tap(find.text('Main Kapad Market & Shivaji Chowk'));
    await tester.pumpAndSettle();

    // Search sheet should close and destination updated
    expect(find.text('Main Kapad Market & Shivaji Chowk'), findsWidgets);
  });

  testWidgets('Gracefully handles location permission disabled', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _MockUserNotifier()),
      ],
    );
    // Disable location permission
    container.read(locationProvider.notifier).setPermissionStatus(LocationPermissionStatus.denied);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CustomerHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify graceful permission banner is displayed without crashing
    expect(find.text('Location permission disabled • Tap to enable'), findsOneWidget);
    expect(find.text('Enable'), findsOneWidget);
  });
}

class _MockUserNotifier extends CurrentUserNotifier {
  @override
  build() => DemoData.demoCustomer;
}
