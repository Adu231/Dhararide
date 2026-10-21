import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/brand/brand_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/session/session_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ProviderScope(child: DharRideApp()));
}

class DharRideApp extends ConsumerWidget {
  const DharRideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
