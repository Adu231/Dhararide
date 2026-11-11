import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class CustomerRidesScreen extends ConsumerStatefulWidget {
  const CustomerRidesScreen({super.key});

  @override
  ConsumerState<CustomerRidesScreen> createState() => _CustomerRidesScreenState();
}

class _CustomerRidesScreenState extends ConsumerState<CustomerRidesScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Completed, 2: Cancelled

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final user = ref.watch(currentUserProvider);
    final customerId = user?.id ?? DemoData.demoCustomer.id;
    final rideRepo = ref.watch(rideRepositoryProvider.notifier);

    // Isolate rides specifically to this authenticated customer
    final allCustomerRides = rideRepo.getRidesForCustomer(customerId);
    final activeRide = rideRepo.getActiveRideForCustomer(customerId);

    // Apply status filter
    List<RideModel> displayedRides;
    if (_selectedFilterIndex == 1) {
      displayedRides = allCustomerRides.where((r) => r.status == RideStatus.rideCompleted).toList();
    } else if (_selectedFilterIndex == 2) {
      displayedRides = allCustomerRides.where((r) => r.status == RideStatus.cancelled).toList();
    } else {
      displayedRides = allCustomerRides;
    }

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.tabRides),
        centerTitle: false,
      ),
      child: Column(
        children: [
          // Active Ride Banner if customer has an ongoing ride
          if (activeRide != null &&
              activeRide.status != RideStatus.rideCompleted &&
              activeRide.status != RideStatus.cancelled) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandConfig.textPrimaryBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const AutoRickshawIcon(size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? 'चालू प्रवास (Active Ride)' : 'Ongoing Active Ride',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${activeRide.pickup.placeName} → ${activeRide.destination.placeName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandConfig.accentYellow,
                      foregroundColor: BrandConfig.textPrimaryBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push('/customer/active-ride'),
                    child: Text(
                      isMr ? 'थेट पहा' : 'Track',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Filter Chips (All / Completed / Cancelled)
          if (allCustomerRides.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip(0, isMr ? 'सर्व' : 'All (${allCustomerRides.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    1,
                    isMr
                        ? 'पूर्ण'
                        : 'Completed (${allCustomerRides.where((r) => r.status == RideStatus.rideCompleted).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, isMr ? 'रद्द' : 'Cancelled'),
                ],
              ),
            ),

          // Rides List or Empty State
          Expanded(
            child: displayedRides.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: BrandConfig.accentYellow),
                            ),
                            child: const Center(
                              child: AutoRickshawIcon(size: 44),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isMr ? 'कोणताही प्रवास इतिहास नाही' : 'No Ride History Yet',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isMr
                                ? 'तुम्ही धाराशिवमध्ये ऑटो बुक केल्यावर तुमचा प्रवास येथे दिसेल.'
                                : 'Book an auto in Dharashiv to see your ride details here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandConfig.accentYellow,
                              foregroundColor: BrandConfig.textPrimaryBlack,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => context.go('/customer/home'),
                            child: Text(
                              isMr ? 'ऑटो बुक करा' : 'Book Auto Now',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayedRides.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ride = displayedRides[index];
                      final isLive = ride.status != RideStatus.rideCompleted &&
                          ride.status != RideStatus.cancelled;

                      return InkWell(
                        onTap: () {
                          if (isLive) {
                            context.push('/customer/active-ride');
                          } else {
                            context.push('/ride-detail', extra: ride);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLive ? BrandConfig.accentYellowDark : AppColors.border,
                              width: isLive ? 1.8 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          ride.id,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (isLive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: BrandConfig.accentYellow,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isMr ? 'सक्रिय' : 'ACTIVE',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: BrandConfig.textPrimaryBlack,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  StatusBadge.fromRideStatus(ride.status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Route Column
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 1.5,
                                        height: 22,
                                        color: const Color(0xFFCED4DA),
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ride.pickup.placeName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          ride.destination.placeName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Driver & Fare Info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        ride.driverName ?? (isMr ? 'ऑटो चालक' : 'Auto Driver'),
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                      ),
                                      if (ride.autoNumber != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${ride.autoNumber})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '₹${ride.finalFare?.toStringAsFixed(0) ?? ride.suggestedFare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: BrandConfig.textPrimaryBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellow : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: BrandConfig.textPrimaryBlack,
          ),
        ),
      ),
    );
  }
}
