import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/session/session_manager.dart';

class DriverShell extends ConsumerWidget {
  final Widget child;
  const DriverShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/driver/rides')) return 1;
    if (location.startsWith('/driver/notifications')) return 2;
    if (location.startsWith('/driver/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/driver/home');
        break;
      case 1:
        context.go('/driver/rides');
        break;
      case 2:
        context.go('/driver/notifications');
        break;
      case 3:
        context.go('/driver/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final selectedIndex = _calculateSelectedIndex(context);

    return ResponsiveContainer(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE9ECEF), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: BrandConfig.accentYellow,
              backgroundColor: Colors.white,
              elevation: 0,
              height: 64,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: BrandConfig.textPrimaryBlack,
                  );
                }
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: BrandConfig.textPrimaryBlack,
                    size: 22,
                  );
                }
                return const IconThemeData(
                  color: AppColors.textSecondary,
                  size: 22,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard_rounded),
                  label: strings.tabDashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history_rounded),
                  label: isMr ? 'प्रवास व कमाई' : 'Rides & Earnings',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.notifications_none_rounded),
                  selectedIcon: const Icon(Icons.notifications_rounded),
                  label: strings.tabNotifications,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: isMr ? 'चालक व वाहन' : 'Profile & Auto',
                ),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
