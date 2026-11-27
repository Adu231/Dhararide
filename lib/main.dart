import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/brand/brand_config.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/demo/demo_data.dart';
import 'data/models/enums.dart';
import 'data/repositories/driver_repository.dart';
import 'data/session/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  LocalNotificationService().setProviderContainer(container);
  await LocalNotificationService().initialize();
  await LocalNotificationService().checkLaunchNotification();

  // Restore persistent authenticated session securely from FlutterSecureStorage
  try {
    final sessionService = AuthSessionService();
    final storedUser = await sessionService.getStoredUser();
    if (storedUser != null) {
      container.read(currentUserProvider.notifier).login(storedUser, persist: false);
      container.read(languageProvider.notifier).setLanguage(storedUser.language);
      if (storedUser.role == UserRole.driver) {
        final drivers = container.read(driverRepositoryProvider);
        final driver = drivers.firstWhere(
          (d) => d.userId == storedUser.id || d.phone == storedUser.phone,
          orElse: () => DemoData.demoDriver,
        );
        container.read(currentDriverProvider.notifier).setDriver(driver);
      }
    }
  } catch (e) {
    debugPrint('Error restoring persistent session on app launch: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 56, color: BrandConfig.accentYellowDark),
                const SizedBox(height: 16),
                const Text(
                  BrandConfig.appName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BrandConfig.textPrimaryBlack),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unable to render screen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BrandConfig.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(UncontrolledProviderScope(container: container, child: const DharRideApp()));
}

class DharRideApp extends ConsumerStatefulWidget {
  const DharRideApp({super.key});

  @override
  ConsumerState<DharRideApp> createState() => _DharRideAppState();
}

class _DharRideAppState extends ConsumerState<DharRideApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService().processPendingLaunch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final activeLanguage = ref.watch(languageProvider);

    return MaterialApp.router(
      title: BrandConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: Locale(activeLanguage.code),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('mr', 'IN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
