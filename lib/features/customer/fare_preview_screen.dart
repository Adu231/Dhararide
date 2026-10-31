import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/brand/brand_config.dart';
import '../../core/services/fare_calculation_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/theme/app_colors.dart';
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
  bool _isSubmitting = false;

  RouteEstimateResult? _roadRoute;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRoadRoute();
  }

  Future<void> _fetchRoadRoute() async {
    final pickupLatLng = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final destLatLng = LatLng(widget.destination.latitude, widget.destination.longitude);
    setState(() => _isLoadingRoute = true);

    try {
      final route = await _routingService.calculateRoadRoute(pickupLatLng, destLatLng);
      if (!mounted) return;
      setState(() {
        _roadRoute = route;
        _isLoadingRoute = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _roadRoute = _routingService.calculateEstimate(pickupLatLng, destLatLng);
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _confirmBooking(double fare) async {
    if (_isSubmitting) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a ride.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      ref.read(rideRepositoryProvider.notifier).createRideRequest(
        customer: user,
        pickup: widget.pickup,
        destination: widget.destination,
        suggestedFare: fare,
        paymentMethod: _selectedPayment,
      );

      if (mounted) {
        context.pushReplacement('/customer/searching');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final allDrivers = ref.watch(driverRepositoryProvider);
    final h3Service = ref.watch(h3ServiceProvider);

    final pickupLatLng = LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final destLatLng = LatLng(widget.destination.latitude, widget.destination.longitude);

    // Calculate real road route estimation via modular RoutingService
    final effectiveRoute = _roadRoute ?? _routingService.calculateEstimate(pickupLatLng, destLatLng);

    // Dynamic suggested fare calculation using centralized FareCalculationService
    final fareService = ref.watch(fareCalculationServiceProvider);
    final fareBreakdown = fareService.calculateFare(distanceKm: effectiveRoute.distanceKm);
    final roundedFare = fareBreakdown.cashRoundedFare;
    final distanceKm = effectiveRoute.distanceKm;

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
        title: Text(strings.reviewBooking),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => context.pop(),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive Route Map Preview (OSM - No Google API key required)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DharashivMapWidget(
                  pickup: pickupLatLng,
                  destination: destLatLng,
                  pickupLabel: widget.pickup.placeName,
                  destinationLabel: widget.destination.placeName,
                  nearbyDrivers: nearbyDrivers,
                  routePolyline: effectiveRoute.polylinePoints,
                  height: 200,
                  onDriverSelected: (driver) => _showDriverBottomSheet(context, driver),
                ),
              ),
            ),
            if (_isLoadingRoute)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(BrandConfig.accentYellow),
                ),
              ),
            const SizedBox(height: 12),

            // Distance, ETA & Nearby Autos Indicator
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.route, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '$distanceKm km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (effectiveRoute.isRealRoadRoute) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Road',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '~${effectiveRoute.estimatedDurationMinutes} min',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BrandConfig.accentYellow),
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
            const SizedBox(height: 14),

            // 2. Clear Location Relationship Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.pickupLocation.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.pickup.placeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.pickup.address.isNotEmpty && widget.pickup.address != widget.pickup.placeName)
                              Text(
                                widget.pickup.address,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 18,
                        child: VerticalDivider(color: Color(0xFFCED4DA), thickness: 1.5),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(2.5),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.destinationLocation.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.destination.placeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.destination.address.isNotEmpty && widget.destination.address != widget.destination.placeName)
                              Text(
                                widget.destination.address,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Transparent Fare Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.estimatedFare,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${roundedFare.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              isMr ? '०% कमिशन' : '0% Commission',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),

                  // Itemized Breakdown
                  _buildFareLine(
                    isMr
                        ? 'बेस भाडे (पहिल्या ${fareBreakdown.baseDistanceKm.toStringAsFixed(1)} किमीपर्यंत)'
                        : 'Base Fare (first ${fareBreakdown.baseDistanceKm.toStringAsFixed(1)} km)',
                    '₹${fareBreakdown.baseFare.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _buildFareLine(
                    isMr
                        ? 'अंतर भाडे (${fareBreakdown.billableDistanceKm.toStringAsFixed(1)} किमी @ ₹${fareBreakdown.ratePerKm.toStringAsFixed(0)}/किमी)'
                        : 'Distance Fare (${fareBreakdown.billableDistanceKm.toStringAsFixed(1)} km @ ₹${fareBreakdown.ratePerKm.toStringAsFixed(0)}/km)',
                    '₹${fareBreakdown.distanceFare.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _buildFareLine(
                    isMr ? 'धाराशिव प्लॅटफॉर्म फी' : 'DharRide Platform Fee',
                    isMr ? '₹० (०% कमिशन)' : '₹0 (0% Commission)',
                    isHighlight: true,
                  ),
                  const Divider(height: 20, color: AppColors.border),

                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strings.mutualFareNote,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Payment Method Selector
            Text(
              strings.paymentMethod,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentTile(
                    label: strings.cash,
                    sublabel: isMr ? 'ड्रायव्हरला थेट द्या' : 'Pay driver directly',
                    icon: Icons.payments_outlined,
                    method: PaymentMethod.cash,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentTile(
                    label: strings.onlineUpi,
                    sublabel: isMr ? 'सवारीनंतर QR स्कॅन करा' : 'Scan QR on ride end',
                    icon: Icons.qr_code_scanner,
                    method: PaymentMethod.onlineUpi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Primary Action: Confirm & Request Auto
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandConfig.accentYellow,
                  foregroundColor: BrandConfig.textPrimaryBlack,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : () => _confirmBooking(roundedFare),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: BrandConfig.textPrimaryBlack,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20, color: BrandConfig.textPrimaryBlack),
                          const SizedBox(width: 8),
                          Text(
                            strings.confirmBooking,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFareLine(String label, String amount, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isHighlight ? AppColors.success : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String label,
    required String sublabel,
    required IconData icon,
    required PaymentMethod method,
  }) {
    final isSelected = _selectedPayment == method;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = method),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.8 : 1,
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
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? BrandConfig.textPrimaryBlack : AppColors.textSecondary,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: BrandConfig.textPrimaryBlack),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? BrandConfig.textPrimaryBlack : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
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
