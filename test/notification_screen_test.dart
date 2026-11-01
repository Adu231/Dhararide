import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/core/theme/app_theme.dart';
import 'package:dharride/features/customer/customer_notifications_screen.dart';
import 'package:dharride/features/notifications/notification_settings_screen.dart';
import 'package:dharride/features/notifications/widgets/notification_card.dart';

void main() {
  testWidgets('NotificationsScreen renders templates and interacts properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CustomerNotificationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Tabs
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);

    // Verify Notification Cards are rendered
    expect(find.byType(NotificationCard), findsWidgets);

    // Verify UI Templates
    expect(find.text('New Ride Request Available'), findsOneWidget);
    expect(find.text('Driver Has Arrived!'), findsOneWidget);

    // Filter to Alerts
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();

    expect(find.text('0% Commission Active in Dharashiv'), findsOneWidget);
    expect(find.text('New Ride Request Available'), findsNothing);

    // Filter back to Rides
    await tester.tap(find.text('Rides'));
    await tester.pumpAndSettle();

    expect(find.text('New Ride Request Available'), findsOneWidget);
    expect(find.text('0% Commission Active in Dharashiv'), findsNothing);

    // Test Mark all as read button
    final markAllButton = find.byIcon(Icons.done_all_rounded);
    if (markAllButton.evaluate().isNotEmpty) {
      await tester.tap(markAllButton);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('NotificationSettingsScreen renders all switches and controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Settings Screen title
    expect(find.text('Notification Settings'), findsOneWidget);

    // Verify Switch Tiles
    expect(find.text('Ride Updates'), findsOneWidget);
    expect(find.text('Booking Alerts'), findsOneWidget);
    expect(find.text('Notification Sounds'), findsOneWidget);
    expect(find.text('Vibration Alerts'), findsOneWidget);
    expect(find.text('System & Service Announcements'), findsOneWidget);

    // Verify Switches are present
    expect(find.byType(Switch), findsNWidgets(5));

    // Toggle a switch
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Verify Simulation button
    final simButton = find.text('Simulate Test Alert');
    await tester.scrollUntilVisible(simButton, 200);
    await tester.pumpAndSettle();
    expect(simButton, findsOneWidget);
    await tester.tap(simButton);
    await tester.pumpAndSettle();
    expect(find.text('Test notification generated!'), findsOneWidget);
  });
}
