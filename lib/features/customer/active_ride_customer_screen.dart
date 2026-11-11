import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand/brand_config.dart';
import '../../core/services/customer_driver_location_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/dharashiv_map_widget.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class ActiveRideCustomerScreen extends ConsumerStatefulWidget {
  const ActiveRideCustomerScreen({super.key});

  @override
  ConsumerState<ActiveRideCustomerScreen> createState() => _ActiveRideCustomerScreenState();
}

class _ActiveRideCustomerScreenState extends ConsumerState<ActiveRideCustomerScreen> {
  final RoutingService _routingService = const RoutingService();
  bool _isOpeningMaps = false;

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate phone call to $phone')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone dialer: $phone')),
      );
    }
  }

  /// Prominent "Where is my driver?" action:
  /// 1. Queries customer-side driver location service for assigned driver's coordinates.
  /// 2. If valid coordinates are available, opens official Google Maps directions URL without API key.
  /// 3. If unavailable, shows an honest dialog informing user that GPS coordinates haven't been received yet.
  Future<void> _handleWhereIsMyDriver(RideModel ride) async {
    if (_isOpeningMaps) return;

    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;
    final locationService = ref.read(customerDriverLocationServiceProvider);

    final locationResult = locationService.getAssignedDriverLocation(ride.driverId);

    if (!locationResult.isValid) {
      // Coordinates not available yet from backend/driver device
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_off_outlined, color: AppColors.error, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.driverLocationUnavailable,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.driverLocationUnavailableDesc,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMr
                            ? 'ड्रायव्हरचे थेट स्थान ड्रायव्हर ॲपमधून प्रसारित झाल्यावर उपलब्ध होईल.'
                            : "Live driver location updates will appear once broadcasted from the driver's phone.",
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isMr ? 'ठीक आहे' : 'Close',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            if (ride.driverPhone != null && ride.driverPhone!.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandConfig.accentYellow,
                  foregroundColor: BrandConfig.textPrimaryBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _makePhoneCall(ride.driverPhone!);
                },
                icon: const Icon(Icons.phone, size: 16),
                label: Text(strings.callDriver),
              ),
          ],
        ),
      );
      return;
    }

    setState(() => _isOpeningMaps = true);

    try {
      final success = await locationService.openDriverLocationInGoogleMaps(ride.driverId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMr
                  ? 'Google Maps उघडण्यात अडचण आली. कृपया पुन्हा प्रयत्न करा.'
                  : 'Could not launch Google Maps. Please ensure a browser or Maps app is available.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningMaps = false);
      }
    }
  }

  /// Open external Google Maps to navigate to pickup or destination.
  Future<void> _openLocationInGoogleMaps(double latitude, double longitude) async {
    final locationService = ref.read(customerDriverLocationServiceProvider);
    await locationService.openLocationInGoogleMaps(latitude: latitude, longitude: longitude);
  }

  void _confirmCancelRide(RideModel ride) {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isMr ? 'सवारी रद्द करावी का?' : 'Cancel Active Ride?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          isMr
              ? 'तुम्हाला खात्री आहे की तुम्हाला ही सक्रिय सवारी रद्द करायची आहे?'
              : 'Are you sure you want to cancel this booking? The assigned driver will be notified.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isMr ? 'नाही' : 'Keep Ride',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(rideRepositoryProvider.notifier).cancelActiveRide('Customer cancelled');
              context.go('/customer/home');
            },
            child: Text(isMr ? 'होय, रद्द करा' : 'Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final user = ref.watch(currentUserProvider);
    final activeRide = ref.watch(rideRepositoryProvider).activeRide;
    final allDrivers = ref.watch(driverRepositoryProvider);

    final isCustomerOwner = user == null || activeRide?.customerId == user.id;

    if (activeRide == null || !isCustomerOwner) {
      return ResponsiveContainer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AutoRickshawIcon(size: 64),
                const SizedBox(height: 16),
                Text(
                  isMr ? 'कोणतीही सक्रिय सवारी नाही' : 'No active ride found',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isMr
                      ? 'नवीन ऑटो बुक करण्यासाठी मुख्य पानावर जा.'
                      : 'Return to home to book an auto-rickshaw.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                    isMr ? 'मुख्य पानावर जा' : 'Return Home',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pickupLatLng = LatLng(activeRide.pickup.latitude, activeRide.pickup.longitude);
    final destLatLng = LatLng(activeRide.destination.latitude, activeRide.destination.longitude);
    final routeEstimate = _routingService.calculateEstimate(pickupLatLng, destLatLng);

    final assignedDriver = activeRide.driverId != null
        ? allDrivers.cast<dynamic>().firstWhere(
              (d) => d.id == activeRide.driverId,
              orElse: () => null,
            )
        : null;

    final isDriverAssigned = activeRide.status != RideStatus.searching && activeRide.status != RideStatus.cancelled;
    final isRideCompleted = activeRide.status == RideStatus.rideCompleted;
    final isRideCancelled = activeRide.status == RideStatus.cancelled;
    final isRideStarted = activeRide.status == RideStatus.rideStarted;

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(isMr ? 'सक्रिय सवारी' : 'Active Ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customer/home'),
        ),
        actions: [
          StatusBadge.fromRideStatus(activeRide.status),
          const SizedBox(width: 16),
          
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ride ID and Status Headline
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
                        activeRide.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeRide.createdAt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        isMr ? '०% कमिशन' : '0% Commission',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Lifecycle Visual Stepper
            _buildLifecycleStepper(activeRide.status, isMr),
            const SizedBox(height: 16),

            // 3. Driver Profile Card (when driver is assigned)
            if (isDriverAssigned) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: BrandConfig.accentYellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: BrandConfig.textPrimaryBlack, width: 2),
                          ),
                          child: const Icon(Icons.electric_rickshaw, color: BrandConfig.textPrimaryBlack, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeRide.driverName ?? (assignedDriver?.name ?? 'Ramesh Shinde'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeRide.autoNumber ?? (assignedDriver?.autoNumber ?? 'MH-25-AZ-4589'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activeRide.driverRating} ★',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isMr ? '• धाराशिव स्थानिक चालक' : '• Dharashiv Local Driver',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Call Driver Action
                        Material(
                          color: AppColors.primaryLight,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _makePhoneCall(
                              activeRide.driverPhone ?? (assignedDriver?.phone ?? BrandConfig.supportPhone),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: BrandConfig.accentYellow),
                              ),
                              child: const Icon(Icons.phone, color: BrandConfig.textPrimaryBlack, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // -------------------------------------------------------------
            // 4. PROMINENT “Where is my driver?” / “माझा ड्रायव्हर कुठे आहे?” BUTTON
            // -------------------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    BrandConfig.accentYellow,
                    BrandConfig.accentYellowDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandConfig.accentYellow.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isDriverAssigned && !_isOpeningMaps
                      ? () => _handleWhereIsMyDriver(activeRide)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                            ],
                          ),
                          child: _isOpeningMaps
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: BrandConfig.textPrimaryBlack),
                                )
                              : const Icon(Icons.explore_rounded, color: BrandConfig.textPrimaryBlack, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.whereIsMyDriver,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: BrandConfig.textPrimaryBlack,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMr
                                    ? 'Google Maps दिशानिर्देशांमध्ये चालकाचे स्थान पहा'
                                    : "View driver's latest coordinates in Google Maps",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: BrandConfig.textPrimaryBlack),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5. In-App OpenStreetMap Route Preview (No Google Maps API Key)
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
                  pickupLabel: activeRide.pickup.placeName,
                  destinationLabel: activeRide.destination.placeName,
                  routePolyline: routeEstimate.polylinePoints,
                  height: 180,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 6. Connected Route Details & Customer External Navigation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Pickup Row
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
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              activeRide.pickup.placeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            if (activeRide.pickup.address.isNotEmpty)
                              Text(
                                activeRide.pickup.address,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      // External Maps Button for Pickup
                      IconButton(
                        icon: const Icon(Icons.directions_outlined, color: AppColors.success, size: 20),
                        tooltip: strings.navigateToPickup,
                        onPressed: () => _openLocationInGoogleMaps(
                          activeRide.pickup.latitude,
                          activeRide.pickup.longitude,
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
                  // Destination Row
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
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              activeRide.destination.placeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            if (activeRide.destination.address.isNotEmpty)
                              Text(
                                activeRide.destination.address,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      // External Maps Button for Destination
                      IconButton(
                        icon: const Icon(Icons.directions_outlined, color: AppColors.error, size: 20),
                        tooltip: strings.navigateToDestination,
                        onPressed: () => _openLocationInGoogleMaps(
                          activeRide.destination.latitude,
                          activeRide.destination.longitude,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: AppColors.border),

                  // Fare & Distance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRideCompleted ? strings.finalFare : strings.estimatedFare,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${(activeRide.finalFare ?? activeRide.suggestedFare).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${routeEstimate.distanceKm} km • ~${routeEstimate.estimatedDurationMinutes}m',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7. Dynamic Action (Proceed to Payment when completed / Cancel before start)
            if (isRideCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandConfig.accentYellow,
                    foregroundColor: BrandConfig.textPrimaryBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.push('/customer/payment'),
                  icon: const Icon(Icons.payment, size: 20),
                  label: Text(
                    isMr ? 'पेमेंटकडे पुढे जा (₹${activeRide.finalFare?.toStringAsFixed(0) ?? '20'})' : 'Proceed to Payment (₹${activeRide.finalFare?.toStringAsFixed(0) ?? '20'})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (!isRideCancelled && !isRideStarted) ...[
              // Cancel button (only allowed before ride has started)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _confirmCancelRide(activeRide),
                  child: Text(
                    strings.cancelRide,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _getStepIndex(RideStatus status) {
    switch (status) {
      case RideStatus.searching:
        return -1;
      case RideStatus.driverAccepted:
        return 0; // Driver Assigned
      case RideStatus.driverArriving:
        return 1; // Driver Arriving
      case RideStatus.driverArrived:
        return 2; // Driver Arrived
      case RideStatus.rideStarted:
        return 3; // Ride Started
      case RideStatus.rideCompleted:
        return 4; // Ride Completed
      case RideStatus.cancelled:
        return -1;
    }
  }

  Widget _buildLifecycleStepper(RideStatus status, bool isMr) {
    if (status == RideStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMr ? 'सवारी रद्द करण्यात आली आहे.' : 'Ride has been cancelled.',
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final currentStep = _getStepIndex(status);

    final steps = [
      {'label': isMr ? 'चालक\nनियुक्त' : 'Driver\nAssigned', 'full': isMr ? 'चालक नियुक्त' : 'Driver Assigned'},
      {'label': isMr ? 'चालक\nयेत आहे' : 'Driver\nArriving', 'full': isMr ? 'चालक येत आहे' : 'Driver Arriving'},
      {'label': isMr ? 'चालक\nपोहोचला' : 'Driver\nArrived', 'full': isMr ? 'चालक पोहोचला' : 'Driver Arrived'},
      {'label': isMr ? 'प्रवास\nसुरू' : 'Ride\nStarted', 'full': isMr ? 'प्रवास सुरू' : 'Ride Started'},
      {'label': isMr ? 'प्रवास\nपूर्ण' : 'Ride\nCompleted', 'full': isMr ? 'प्रवास पूर्ण' : 'Ride Completed'},
    ];

    String liveStatusTitle;
    String liveStatusDesc;
    IconData liveStatusIcon;
    Color liveStatusColor;

    switch (status) {
      case RideStatus.searching:
        liveStatusTitle = isMr ? 'चालकाचा शोध घेत आहोत' : 'Searching for nearby driver';
        liveStatusDesc = isMr ? 'कृपया थोडा वेळ प्रतीक्षा करा.' : 'Please wait while we connect you to an auto.';
        liveStatusIcon = Icons.search;
        liveStatusColor = AppColors.warning;
        break;
      case RideStatus.driverAccepted:
        liveStatusTitle = isMr ? 'चालक नियुक्त (Driver Assigned)' : 'Driver Assigned';
        liveStatusDesc = isMr ? 'चालकाने तुमचे बुकिंग स्वीकारले आहे.' : 'Driver has accepted your ride request.';
        liveStatusIcon = Icons.how_to_reg;
        liveStatusColor = AppColors.info;
        break;
      case RideStatus.driverArriving:
        liveStatusTitle = isMr ? 'चालक येत आहे (Driver Arriving)' : 'Driver Arriving';
        liveStatusDesc = isMr ? 'चालक पिकअप स्थानाकडे येत आहे.' : 'Driver is on the way to your pickup spot.';
        liveStatusIcon = Icons.near_me;
        liveStatusColor = AppColors.info;
        break;
      case RideStatus.driverArrived:
        liveStatusTitle = isMr ? 'चालक पोहोचला (Driver Arrived)' : 'Driver Arrived';
        liveStatusDesc = isMr ? 'ऑटो तुमच्या पिकअप स्थानावर थांबली आहे.' : 'Driver is waiting at your pickup spot.';
        liveStatusIcon = Icons.pin_drop;
        liveStatusColor = AppColors.warning;
        break;
      case RideStatus.rideStarted:
        liveStatusTitle = isMr ? 'प्रवास सुरू (Ride Started)' : 'Ride Started';
        liveStatusDesc = isMr ? 'गंतव्य स्थानाकडे प्रवास सुरू आहे.' : 'Trip in progress to your destination.';
        liveStatusIcon = Icons.electric_rickshaw;
        liveStatusColor = BrandConfig.textPrimaryBlack;
        break;
      case RideStatus.rideCompleted:
        liveStatusTitle = isMr ? 'प्रवास पूर्ण (Ride Completed)' : 'Ride Completed';
        liveStatusDesc = isMr ? 'प्रवास पूर्ण झाला. कृपया पैसे द्या.' : 'Ride completed. Please proceed to payment.';
        liveStatusIcon = Icons.check_circle;
        liveStatusColor = AppColors.success;
        break;
      case RideStatus.cancelled:
        liveStatusTitle = isMr ? 'सवारी रद्द झाली' : 'Ride Cancelled';
        liveStatusDesc = isMr ? 'सवारी रद्द करण्यात आली आहे.' : 'This ride was cancelled.';
        liveStatusIcon = Icons.cancel;
        liveStatusColor = AppColors.error;
        break;
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Status Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: liveStatusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: liveStatusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(liveStatusIcon, size: 20, color: liveStatusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveStatusTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: liveStatusColor),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        liveStatusDesc,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5-Step Progress Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isPassed = currentStep >= 0 && index < currentStep;
              final isCurrent = currentStep >= 0 && index == currentStep;

              final Color circleBg = isPassed
                  ? AppColors.success
                  : (isCurrent ? BrandConfig.accentYellow : const Color(0xFFF1F3F5));
              final Color circleBorder = isPassed
                  ? AppColors.success
                  : (isCurrent ? BrandConfig.textPrimaryBlack : const Color(0xFFCED4DA));
              final Color textColor = isCurrent
                  ? BrandConfig.textPrimaryBlack
                  : (isPassed ? AppColors.success : AppColors.textMuted);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: circleBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: circleBorder, width: isCurrent ? 2 : 1.5),
                            ),
                            child: Center(
                              child: isPassed
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : (isCurrent
                                      ? const Icon(Icons.radio_button_checked, size: 14, color: BrandConfig.textPrimaryBlack)
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                        )),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            steps[index]['label'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.15,
                              fontWeight: isCurrent ? FontWeight.w800 : (isPassed ? FontWeight.w600 : FontWeight.normal),
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 10,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: index < currentStep ? AppColors.success : const Color(0xFFDEE2E6),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
