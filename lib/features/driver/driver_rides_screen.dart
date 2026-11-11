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

class DriverRidesScreen extends ConsumerStatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  ConsumerState<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends ConsumerState<DriverRidesScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Completed, 2: Cancelled

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final driver = ref.watch(currentDriverProvider) ?? DemoData.demoDriver;
    final rideRepo = ref.watch(rideRepositoryProvider.notifier);

    // Filter rides specifically by authenticated driver ID
    final allDriverRides = rideRepo.getRidesForDriver(driver.id);
    final activeRide = rideRepo.getActiveRideForDriver(driver.id);

    // Compute dynamic driver earnings
    final earnings = rideRepo.calculateDriverEarnings(driver.id);
    final totalEarnings = earnings['totalEarnings'] as double? ?? 0.0;
    final completedCount = earnings['totalRidesCount'] as int? ?? 0;

    // Apply status filter
    List<RideModel> displayedRides;
    if (_selectedFilterIndex == 1) {
      displayedRides = allDriverRides.where((r) => r.status == RideStatus.rideCompleted).toList();
    } else if (_selectedFilterIndex == 2) {
      displayedRides = allDriverRides.where((r) => r.status == RideStatus.cancelled).toList();
    } else {
      displayedRides = allDriverRides;
    }

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(isMr ? 'माझे प्रवास आणि कमाई' : 'My Rides & Earnings'),
        centerTitle: false,
      ),
      child: Column(
        children: [
          // Top Stats Summary: Earnings & Completed Trips
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMr ? 'एकूण कमाई (१००% थेट)' : 'Total Earnings (100% Direct)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B5800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: BrandConfig.textPrimaryBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '०% कमिशन • Zero Platform Fee',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 46,
                  color: const Color(0xFFE0C475),
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isMr ? 'पूर्ण प्रवास' : 'Completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B5800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: BrandConfig.textPrimaryBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMr ? 'ऑटो ट्रिप्स' : 'Auto Trips',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active Ongoing Ride Banner (if assigned driver has active trip)
          if (activeRide != null &&
              activeRide.status != RideStatus.rideCompleted &&
              activeRide.status != RideStatus.cancelled) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandConfig.textPrimaryBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_outlined, color: BrandConfig.accentYellow, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? 'सक्रिय प्रवास सुरू आहे' : 'Active Ride In Progress',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${activeRide.customerName} • ${activeRide.destination.placeName}',
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
                    onPressed: () => context.push('/driver/active-ride'),
                    child: Text(
                      isMr ? 'पहा' : 'View',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Filter Segment Tabs: All / Completed / Cancelled
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(0, isMr ? 'सर्व' : 'All (${allDriverRides.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(1, isMr ? 'पूर्ण' : 'Completed ($completedCount)'),
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
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: BrandConfig.accentYellow),
                            ),
                            child: const Center(
                              child: AutoRickshawIcon(size: 40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isMr ? 'कोणतेही प्रवास नाहीत' : 'No Driver Trips Found',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isMr
                              ? 'धाराशिवमध्ये नवीन राइड विनंत्या मिळवण्यासाठी ऑनलाइन जा. १००% भाडे थेट तुम्हाला मिळते.'
                              : 'Go Online on the Dashboard to receive ride requests across Dharashiv.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandConfig.accentYellow,
                              foregroundColor: BrandConfig.textPrimaryBlack,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => context.go('/driver/home'),
                            icon: const Icon(Icons.dashboard_outlined, size: 16),
                            label: Text(
                              isMr ? 'डॅशबोर्डवर जा' : 'Go to Dashboard',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: displayedRides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ride = displayedRides[index];
                      final isLive = ride.status != RideStatus.rideCompleted &&
                          ride.status != RideStatus.cancelled;
                      final fare = (ride.finalFare ?? ride.suggestedFare).toStringAsFixed(0);

                      return InkWell(
                        onTap: () {
                          if (isLive) {
                            context.push('/driver/active-ride');
                          } else {
                            context.push('/ride-detail', extra: ride);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLive ? BrandConfig.accentYellowDark : AppColors.border,
                              width: isLive ? 1.6 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Ride ID + Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          ride.id,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ride.createdAt,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  StatusBadge.fromRideStatus(ride.status),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Passenger info (driver only sees customer details for assigned rides)
                              Row(
                                children: [
                                  const Icon(Icons.person_pin, size: 16, color: BrandConfig.textPrimaryBlack),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${isMr ? 'प्रवासी: ' : 'Passenger: '}${ride.customerName}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹$fare',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: BrandConfig.textPrimaryBlack,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Route pickup & drop
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(width: 1, height: 16, color: const Color(0xFFCED4DA)),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ride.pickup.placeName,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          ride.destination.placeName,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Bottom info bar: 0% Platform Fee guarantee
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isMr
                                          ? '१००% थेट चालक कमाई (०% कमिशन)'
                                          : '100% direct driver share (₹0 fee)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      ride.paymentMethod == PaymentMethod.cash ? 'Cash' : 'UPI',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
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

