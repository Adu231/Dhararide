import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/brand/brand_config.dart';
import '../../core/services/routing_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/dharashiv_map_widget.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/driver_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class FarePreviewScreen extends ConsumerStatefulWidget {
  final LocationPointModel pickup;
  final LocationPointModel destination;

  const FarePreviewScreen({
    super.key,
    required this.pickup,
    required this.destination,
  });

  @override
  ConsumerState<FarePreviewScreen> createState() => _FarePreviewScreenState();
}

class _FarePreviewScreenState extends ConsumerState<FarePreviewScreen> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  final RoutingService _routingService = const RoutingService();

  void _confirmBooking(double fare) {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(rideRepositoryProvider.notifier).createRideRequest(
        customer: user,
        pickup: widget.pickup,
        destination: widget.destination,
        suggestedFare: fare,
        paymentMethod: _selectedPayment,
      );
      context.pushReplacement('/customer/searching');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final allDrivers = ref.watch(driverRepositoryProvider);
    final h3Service = ref.watch(h3ServiceProvider);

    final pickupLatLng = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final destLatLng = LatLng(widget.destination.latitude, widget.destination.longitude);

    // Calculate route estimation using modular RoutingService
    final routeEstimate = _routingService.calculateEstimate(pickupLatLng, destLatLng);

    // Dynamic suggested fare calculation: base fare Rs 20 for first 1.5 km, then Rs 12/km
    final calculatedFare = (routeEstimate.distanceKm <= 1.5)
        ? 20.0
        : (20.0 + (routeEstimate.distanceKm - 1.5) * BrandConfig.baseFarePerKm);
    final roundedFare = (calculatedFare / 5).round() * 5.0; // round to nearest Rs 5

    // Query available drivers nearby using Uber H3 indexing & distance ranking
    final nearbyResults = h3Service.findNearbyDrivers(
      pickupLatitude: widget.pickup.latitude,
      pickupLongitude: widget.pickup.longitude,
      allDrivers: allDrivers,
      ringSize: 2, // 2-ring neighborhood coverage in Dharashiv
      maxDistanceKm: 6.0,
    );
    final nearbyDrivers = nearbyResults.map((r) => r.driver).toList();

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.suggestedFare),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive OpenStreetMap with Pickup, Destination, and H3-indexed Drivers
            DharashivMapWidget(
              pickup: pickupLatLng,
              destination: destLatLng,
              pickupLabel: widget.pickup.placeName,
              destinationLabel: widget.destination.placeName,
              nearbyDrivers: nearbyDrivers,
              routePolyline: routeEstimate.polylinePoints,
              height: 220,
              onDriverSelected: (driver) {
                _showDriverBottomSheet(context, driver);
              },
            ),
            const SizedBox(height: 12),

            // Distance & ETA Chips Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car, size: 16, color: BrandConfig.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${routeEstimate.distanceKm} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: BrandConfig.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '~${routeEstimate.estimatedDurationMinutes} mins',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electric_rickshaw, size: 16, color: BrandConfig.textPrimaryBlack),
                      const SizedBox(width: 4),
                      Text(
                        '${nearbyDrivers.length} auto',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.pickup.placeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 16,
                        child: VerticalDivider(color: AppColors.border, thickness: 2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.destination.placeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fare breakdown banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(strings.suggestedFare, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text(
                        '₹${roundedFare.toStringAsFixed(0)}.00',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.mutualFareNote,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment method selector
            Text(strings.paymentMethod, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentTile(
                    label: strings.cash,
                    icon: Icons.money,
                    method: PaymentMethod.cash,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentTile(
                    label: strings.onlineUpi,
                    icon: Icons.qr_code_scanner,
                    method: PaymentMethod.onlineUpi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              text: 'Confirm & Request Auto',
              icon: Icons.send,
              onClick: () => _confirmBooking(roundedFare),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile({required String label, required IconData icon, required PaymentMethod method}) {
    final isSelected = _selectedPayment == method;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showDriverBottomSheet(BuildContext context, DriverModel driver) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: BrandConfig.accentYellow,
                    radius: 22,
                    child: const Icon(Icons.person, color: BrandConfig.textPrimaryBlack),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(driver.autoNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${driver.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (driver.h3Index != null)
                Text(
                  'H3 Hex Cell: ${driver.h3Index}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }
}
