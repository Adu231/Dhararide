import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/session/session_manager.dart';

class CustomerShell extends ConsumerWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/customer/rides')) return 1;
    if (location.startsWith('/customer/notifications')) return 2;
    if (location.startsWith('/customer/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customer/home');
        break;
      case 1:
        context.go('/customer/rides');
        break;
      case 2:
        context.go('/customer/notifications');
        break;
      case 3:
        context.go('/customer/profile');
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
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.tabHome,
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
