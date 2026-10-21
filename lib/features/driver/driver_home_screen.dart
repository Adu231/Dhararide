import '../../data/demo/demo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';
import 'pending_approval_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(currentDriverProvider);
    final strings = ref.watch(stringsProvider);
    final rideState = ref.watch(rideRepositoryProvider);

    if (driver?.verificationStatus == DriverVerificationStatus.pending) {
      return const PendingApprovalScreen();
    }

    final activeRide = rideState.activeRide;
    final hasSearchingRide = _isOnline && activeRide != null && activeRide.status == RideStatus.searching;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const AutoRickshawIcon(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver?.name ?? 'Ramesh Shinde', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(driver?.autoNumber ?? 'MH-25-AZ-4589', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/driver/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online/Offline Toggle Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isOnline ? AppColors.success.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? AppColors.success.withOpacity(0.3) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isOnline ? AppColors.success : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? strings.statusOnline : strings.statusOffline,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isOnline ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _isOnline ? strings.driverOnlineDesc : strings.driverOfflineDesc,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: AppColors.success,
                    onChanged: (val) {
                      setState(() => _isOnline = val);
                      if (driver != null) {
                        ref.read(driverRepositoryProvider.notifier).toggleOnlineStatus(driver.id, val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Incoming Ride Request Card (if available)
            if (hasSearchingRide) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryDark.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notification_important, color: AppColors.warning, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              strings.newRideRequest,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(activeRide.pickup.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(activeRide.destination.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Suggested Fare: ₹${activeRide.suggestedFare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Text('0% Fee', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: strings.accept,
                            onClick: () {
                              ref.read(rideRepositoryProvider.notifier).driverAcceptRide(activeRide.id, driver ?? DemoData.demoDriver);
                              context.push('/driver/active-ride');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SecondaryButton(
                            text: strings.reject,
                            onClick: () {
                              ref.read(rideRepositoryProvider.notifier).cancelActiveRide('Driver declined');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Daily Earnings Card
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: strings.todaysEarnings,
                    value: '₹3,840',
                    icon: Icons.account_balance_wallet,
                    subtitle: '100% directly to you (0% fee)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: strings.todaysRides,
                    value: '14',
                    icon: Icons.electric_rickshaw,
                    subtitle: 'Completed rides',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Driver rating & stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 36, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('4.9 Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Based on 142 total rides in Dharashiv', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
