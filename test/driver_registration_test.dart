import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/core/theme/app_theme.dart';
import 'package:dharride/data/models/driver_model.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/user_model.dart';
import 'package:dharride/data/repositories/driver_repository.dart';
import 'package:dharride/data/repositories/user_repository.dart';
import 'package:dharride/data/session/session_manager.dart';
import 'package:dharride/features/auth/register_screen.dart';

void main() {
  group('Driver Registration & Document Upload Tests', () {
    testWidgets('Driver Registration renders all updated form fields without email or prefix', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Full Name field is present
      expect(find.text('Full Name'), findsWidgets);

      // 2. Verify Mobile Phone field and Verify button are present
      expect(find.text('Mobile Phone Number'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);

      // Verify entering phone and tapping Verify triggers OTP verification dialog
      final phoneField = find.widgetWithText(TextField, '').at(1);
      await tester.enterText(phoneField, '9822012345');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Verify OTP'), findsOneWidget);
      await tester.tap(find.text('Confirm OTP'));
      await tester.pumpAndSettle();

      expect(find.text('OTP Verified'), findsOneWidget);

      // 3. Verify Email field is completely removed
      expect(find.text('Email Address (Optional)'), findsNothing);
      expect(find.text('Email (Optional)'), findsNothing);
      expect(find.text('user@example.com'), findsNothing);

      // 4. Verify Vehicle Number allows complete manual entry without hardcoded prefix
      final autoTextField = find.widgetWithText(TextField, '');
      expect(find.text('MH-25-AB-1234'), findsWidgets);

      // 5. Verify UPI ID is optional with clean label
      expect(find.text('UPI ID (Optional)'), findsOneWidget);
      expect(find.text('Enter UPI ID'), findsOneWidget);

      // 6. Verify 6 Required Document Cards are rendered
      expect(find.text('Aadhaar Card – Front Side'), findsOneWidget);
      expect(find.text('Aadhaar Card – Back Side'), findsOneWidget);
      expect(find.text('Driving Licence – Front Side'), findsOneWidget);
      expect(find.text('Driving Licence – Back Side'), findsOneWidget);
      expect(find.text('Vehicle RC Book'), findsOneWidget);
      expect(find.text('Driver Profile Photo'), findsOneWidget);

      // 7. Verify Camera and Gallery buttons are available on each card
      expect(find.text('Camera'), findsNWidgets(6));
      expect(find.text('Gallery'), findsNWidgets(6));

      // 8. Verify General Document Submission & Verification Consent
      expect(find.text('Document Submission & Verification Consent'), findsOneWidget);
      expect(
        find.text('I have read and understood the above information and voluntarily agree to these terms.'),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsOneWidget);
      final checkboxWidget = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkboxWidget.value, isFalse, reason: 'Consent checkbox must be unchecked by default');

      // 9. Verify Submit for Verification button
      expect(find.text('Submit for Verification'), findsOneWidget);
    });

    test('DriverRepository registers driver with 6 documents in pending status without duplicates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final docItem = DriverDocumentItem(
        type: DocumentType.aadhaarFront,
        fileName: 'aadhaar_front.jpg',
        fileSizeBytes: 1024 * 1024,
        uploadedAt: DateTime.now(),
        isMasked: true,
        secureStorageKey: 'secure_storage://drivers/9822012345/aadhaar_front.jpg',
      );

      final documents = DriverDocuments(
        aadhaarFront: docItem,
        aadhaarBack: docItem,
        drivingLicenceFront: docItem,
        drivingLicenceBack: docItem,
        rcBook: docItem,
        driverPhoto: docItem,
        documentConsentGiven: true,
        consentTimestamp: DateTime.now(),
      );

      expect(documents.uploadedCount, 6);
      expect(documents.isComplete, true);

      final driver = container.read(driverRepositoryProvider.notifier).registerDriver(
            userId: 'usr_existing_cust_1',
            name: 'Rahul Deshmukh',
            phone: '9822012345',
            autoNumber: 'MH-25-AB-4589',
            upiId: 'rahul@upi',
            documents: documents,
          );

      expect(driver.verificationStatus, DriverVerificationStatus.pending);
      expect(driver.documents, isNotNull);
      expect(driver.documents!.uploadedCount, 6);
      expect(driver.autoNumber, 'MH-25-AB-4589');

      // Re-registering the same driver updates instead of duplicating
      container.read(driverRepositoryProvider.notifier).registerDriver(
            userId: 'usr_existing_cust_1',
            name: 'Rahul Deshmukh',
            phone: '9822012345',
            autoNumber: 'MH-25-CD-9999',
            upiId: 'rahul@okhdfcbank',
            documents: documents,
          );

      final drivers = container.read(driverRepositoryProvider).where((d) => d.userId == 'usr_existing_cust_1').toList();
      expect(drivers.length, 1);
      expect(drivers.first.autoNumber, 'MH-25-CD-9999');
    });

    testWidgets('Existing customer pre-fills name, phone and upgrades without creating duplicate account', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingCustomer = UserModel(
        id: 'usr_cust_test_101',
        name: 'Sachin Patil',
        phone: '9422054321',
        role: UserRole.customer,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(currentUserProvider.notifier).login(existingCustomer);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check prefilled name and phone
      expect(find.text('Sachin Patil'), findsOneWidget);
      expect(find.text('9422054321'), findsOneWidget);
      expect(find.text('Customer Account Connected: Sachin Patil (+91 9422054321)'), findsOneWidget);
    });
  });
}
