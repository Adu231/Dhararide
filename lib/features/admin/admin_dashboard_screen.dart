import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final users = ref.watch(userRepositoryProvider);
    final drivers = ref.watch(driverRepositoryProvider);
    final rides = ref.watch(rideRepositoryProvider).rides;
    final complaints = ref.watch(adminRepositoryProvider).complaints;

    final pendingDrivers = drivers.where((d) => d.verificationStatus == DriverVerificationStatus.pending).length;
    final approvedDrivers = drivers.where((d) => d.verificationStatus == DriverVerificationStatus.approved).length;

    return ResponsiveContainer(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.adminDashboard, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('${BrandConfig.appName} Central Control', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              ref.read(currentUserProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                StatCard(title: strings.totalUsers, value: '${users.length}', icon: Icons.people),
                StatCard(title: strings.approvedDrivers, value: '$approvedDrivers', icon: Icons.electric_rickshaw, iconColor: AppColors.success),
                StatCard(title: strings.pendingDrivers, value: '$pendingDrivers', icon: Icons.pending_actions, iconColor: AppColors.warning),
                StatCard(title: strings.activeRides, value: '${rides.length}', icon: Icons.route, iconColor: AppColors.info),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Management Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildNavTile(
              context,
              title: strings.driverManagement,
              subtitle: 'Review & approve driver registrations',
              icon: Icons.verified_user_outlined,
              route: '/admin/drivers',
            ),
            _buildNavTile(
              context,
              title: strings.userManagement,
              subtitle: 'View user accounts & status',
              icon: Icons.manage_accounts_outlined,
              route: '/admin/users',
            ),
            _buildNavTile(
              context,
              title: strings.rideManagement,
              subtitle: 'Audit all platform trips',
              icon: Icons.format_list_bulleted,
              route: '/admin/rides',
            ),
            _buildNavTile(
              context,
              title: strings.complaintsManagement,
              subtitle: '${complaints.length} tickets recorded',
              icon: Icons.support_agent_outlined,
              route: '/admin/complaints',
            ),
            _buildNavTile(
              context,
              title: strings.announcements,
              subtitle: 'Send bilingual broadcasts',
              icon: Icons.campaign_outlined,
              route: '/admin/announcements',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        onTap: () => context.push(route),
      ),
    );
  }
}
