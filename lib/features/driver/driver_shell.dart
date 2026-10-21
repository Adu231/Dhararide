import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final selectedIndex = _calculateSelectedIndex(context);

    return ResponsiveContainer(
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary,
        elevation: 4,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: strings.tabDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: strings.tabRides,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: strings.tabNotifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.tabProfile,
          ),
        ],
      ),
      child: child,
    );
  }
}
