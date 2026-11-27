import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dharride/core/brand/brand_config.dart';
import 'package:dharride/core/services/auth_session_service.dart';
import 'package:dharride/core/theme/app_theme.dart';
import 'package:dharride/core/widgets/custom_buttons.dart';
import 'package:dharride/data/demo/demo_data.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/user_model.dart';
import 'package:dharride/data/repositories/user_repository.dart';
import 'package:dharride/data/session/session_manager.dart';
import 'package:dharride/features/auth/customer_register_screen.dart';
import 'package:dharride/features/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthSessionService (Secure Storage) Tests', () {
    test('Saves, retrieves, and clears user session securely without passwords/OTPs', () async {
      final sessionService = AuthSessionService();
      await sessionService.clearSession();

      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getStoredUser(), isNull);
      expect(await sessionService.getStoredToken(), isNull);

      const testUser = UserModel(
        id: 'usr_test_persistent_01',
        name: 'Suresh More',
        phone: '9822112233',
        role: UserRole.customer,
        language: AppLanguage.marathi,
      );

      await sessionService.saveSession(user: testUser, token: 'jwt_secure_test_token_abc123');

      expect(await sessionService.hasValidSession(), isTrue);
      expect(await sessionService.getStoredToken(), 'jwt_secure_test_token_abc123');

      final storedUser = await sessionService.getStoredUser();
      expect(storedUser, isNotNull);
      expect(storedUser!.id, 'usr_test_persistent_01');
      expect(storedUser.name, 'Suresh More');
      expect(storedUser.phone, '9822112233');
      expect(storedUser.role, UserRole.customer);
      expect(storedUser.language, AppLanguage.marathi);

      // Logout clears session
      await sessionService.clearSession();
      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getStoredUser(), isNull);
      expect(await sessionService.getStoredToken(), isNull);
    });
  });

  group('Common Customer Login Screen UI Tests', () {
    testWidgets('Renders DharRide logo, welcome heading, +91 prefix, Continue, Become a Driver, and NO passwords',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Branding & Header
      expect(find.text(BrandConfig.appName), findsOneWidget);
      expect(find.text('Welcome to DharRide'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);

      // 2. Mobile Number Input
      expect(find.text('Mobile Phone Number'), findsOneWidget);

      // 3. Action Buttons
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Become a DharRide Driver'), findsOneWidget);
      expect(find.text('Apply as Driver'), findsOneWidget);

      // 4. CRITICAL: Completely NO Password Fields
      expect(find.text('Password'), findsNothing);
      expect(find.text('Enter Password'), findsNothing);
      expect(find.text('password123'), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('Clicking Continue with valid phone triggers OTP verification UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify OTP Input Card appears
      expect(find.text('OTP Verification'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text('Change Number'), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
    });
  });

  group('New Customer Registration Screen Tests', () {
    testWidgets('Renders preverified mobile, full name, language selection, and NO email or password',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CustomerRegisterScreen(verifiedPhone: '9855511223'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // 2. Preverified Phone
      expect(find.text('+91 9855511223'), findsOneWidget);
      expect(find.text('Verified Mobile'), findsOneWidget);

      // 3. Full Name
      expect(find.text('Full Name'), findsWidgets);

      // 4. Preferred Language Options
      expect(find.text('Select Preferred Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);

      // 5. Submit Button
      expect(find.text('Get Started'), findsOneWidget);

      // 6. CRITICAL: NO Email and NO Password
      expect(find.text('Email Address (Optional)'), findsNothing);
      expect(find.text('Email (Optional)'), findsNothing);
      expect(find.text('Password'), findsNothing);

      // 7. Fill name and submit
      await tester.enterText(find.byType(TextField), 'Anil Kale');
      await tester.tap(find.text('मराठी'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isNotNull);
      expect(currentUser!.name, 'Anil Kale');
      expect(currentUser.phone, '9855511223');
      expect(currentUser.role, UserRole.customer);
      expect(currentUser.language, AppLanguage.marathi);
    });
  });

  group('UserRepository & Role-Based Lookup Tests', () {
    test('Backend identifies existing account by phone without trusting client role', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final userRepo = container.read(userRepositoryProvider.notifier);

      // Customer lookup
      final customer = userRepo.getUserByPhone('9822012345');
      expect(customer, isNotNull);
      expect(customer!.id, DemoData.demoCustomer.id);
      expect(customer.role, UserRole.customer);

      // Driver lookup
      final driver = userRepo.getUserByPhone('9422054321');
      expect(driver, isNotNull);
      expect(driver!.id, DemoData.demoDriverUser.id);
      expect(driver.role, UserRole.driver);

      // Admin lookup
      final admin = userRepo.getUserByPhone('9999900000');
      expect(admin, isNotNull);
      expect(admin!.id, DemoData.demoAdmin.id);
      expect(admin.role, UserRole.admin);

      // Non-existent phone returns null for new customer registration
      final nonExistent = userRepo.getUserByPhone('9111122222');
      expect(nonExistent, isNull);
    });

    test('Persistent Login saves session to storage on login and removes on logout', () async {
      final sessionService = AuthSessionService();
      await sessionService.clearSession();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await sessionService.hasValidSession(), isFalse);

      // User logs in with OTP
      container.read(currentUserProvider.notifier).login(DemoData.demoCustomer);
      expect(container.read(currentUserProvider), isNotNull);
      expect(container.read(currentUserProvider)!.name, DemoData.demoCustomer.name);

      // Verify persistent storage now has the session
      expect(await sessionService.hasValidSession(), isTrue);
      final stored = await sessionService.getStoredUser();
      expect(stored, isNotNull);
      expect(stored!.phone, DemoData.demoCustomer.phone);

      // Explicit logout terminates session completely
      container.read(currentUserProvider.notifier).logout();
      expect(container.read(currentUserProvider), isNull);
      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getStoredUser(), isNull);
    });
  });
}
