import '../../data/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../brand/brand_config.dart';
import '../theme/app_colors.dart';
import '../../data/session/session_manager.dart';

class ResponsiveContainer extends ConsumerWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth > 600;

    if (!isDesktopWeb) {
      return Scaffold(
        backgroundColor: backgroundColor ?? AppColors.background,
        appBar: appBar,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: Center(
        child: Container(
          width: 440,
          height: 880,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.background,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFDEE2E6), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildDesktopTopHeader(context, ref),
              Expanded(
                child: Scaffold(
                  backgroundColor: backgroundColor ?? AppColors.background,
                  appBar: appBar,
                  body: child,
                  bottomNavigationBar: bottomNavigationBar,
                  floatingActionButton: floatingActionButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopHeader(BuildContext context, WidgetRef ref) {
    final activeLang = ref.watch(languageProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DharRide Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activeLang == AppLanguage.english ? 'मराठी' : 'EN',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
