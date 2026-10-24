import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/brand/brand_config.dart';
import '../../core/map/map_config.dart';
import '../../core/services/location_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/dharashiv_map_widget.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/driver_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/session/session_manager.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  late final MapController _mapController;
  final RoutingService _routingService = const RoutingService();

  PopularPlaceModel _pickup = DemoData.popularPlaces[0];
  PopularPlaceModel _destination = DemoData.popularPlaces[2];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final temp = _pickup;
      _pickup = _destination;
      _destination = temp;
    });
    _mapController.move(
      LatLng(_pickup.latitude, _pickup.longitude),
      MapConfig.defaultZoom,
    );
  }

  void _recenterMap() {
    final locationState = ref.read(locationProvider);
    final target = locationState.isGranted ? locationState.userLocation : LatLng(_pickup.latitude, _pickup.longitude);
    _mapController.move(target, MapConfig.defaultZoom);
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    if (zoom <= MapConfig.maxZoom) {
      _mapController.move(_mapController.camera.center, zoom);
    }
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1;
    if (zoom >= MapConfig.minZoom) {
      _mapController.move(_mapController.camera.center, zoom);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bus Stand':
        return Icons.directions_bus_filled;
      case 'Railway Station':
        return Icons.train;
      case 'Hospital':
        return Icons.local_hospital;
      case 'Market':
        return Icons.storefront;
      case 'College':
        return Icons.school;
      case 'Temple':
        return Icons.temple_hindu;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bus Stand':
        return Colors.blue.shade700;
      case 'Railway Station':
        return Colors.indigo.shade700;
      case 'Hospital':
        return Colors.red.shade700;
      case 'Market':
        return Colors.orange.shade800;
      case 'College':
        return Colors.purple.shade700;
      case 'Temple':
        return Colors.amber.shade900;
      default:
        return AppColors.textPrimary;
    }
  }

  void _showPlacePicker({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PlaceSearchSheet(
          isPickup: isPickup,
          currentSelection: isPickup ? _pickup : _destination,
          onSelected: (place) {
            setState(() {
              if (isPickup) {
                _pickup = place;
              } else {
                _destination = place;
              }
            });
            _mapController.move(
              LatLng(place.latitude, place.longitude),
              MapConfig.defaultZoom,
            );
          },
        );
      },
    );
  }

  void _showDriverDetails(DriverModel driver) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                          driver.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver.autoNumber,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BrandConfig.accentYellowLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrandConfig.accentYellow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Verified Local Auto Driver of Dharashiv • 0% Commission',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final allDrivers = ref.watch(driverRepositoryProvider);
    final locationState = ref.watch(locationProvider);

    final pickupLatLng = LatLng(_pickup.latitude, _pickup.longitude);
    final destLatLng = LatLng(_destination.latitude, _destination.longitude);

    // Calculate realistic route estimation using tortuosity service
    final routeEstimate = _routingService.calculateEstimate(pickupLatLng, destLatLng);

    // Dynamic suggested fare calculation: base fare Rs 20 for first 1.5 km, then Rs 12/km
    final calculatedFare = (routeEstimate.distanceKm <= 1.5)
        ? 20.0
        : (20.0 + (routeEstimate.distanceKm - 1.5) * BrandConfig.baseFarePerKm);
    final roundedFare = (calculatedFare / 5).round() * 5.0; // round to nearest Rs 5

    // Filter online and approved drivers to display on map
    final onlineDrivers = allDrivers
        .where((d) =>
            d.availability == DriverAvailability.online &&
            d.verificationStatus == DriverVerificationStatus.approved)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // -------------------------------------------------------------
          // 1. PRIMARY VISUAL AREA: Interactive OpenStreetMap Backdrop
          // -------------------------------------------------------------
          Positioned.fill(
            child: DharashivMapWidget(
              pickup: pickupLatLng,
              destination: destLatLng,
              userLocation: locationState.isGranted ? locationState.userLocation : null,
              pickupLabel: _pickup.getName(isMr),
              destinationLabel: _destination.getName(isMr),
              nearbyDrivers: onlineDrivers,
              routePolyline: routeEstimate.polylinePoints,
              isFullScreen: true,
              showControls: false,
              externalController: _mapController,
              attributionBottomOffset: 12,
              onDriverSelected: _showDriverDetails,
            ),
          ),

          // -------------------------------------------------------------
          // 2. FLOATING MAP ACTION BUTTONS (Right Side)
          // -------------------------------------------------------------
          Positioned(
            right: 16,
            top: 74,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.my_location,
                  tooltip: 'Recenter / My Location',
                  iconColor: locationState.isGranted ? Colors.blue.shade700 : AppColors.textPrimary,
                  onTap: _recenterMap,
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // 3. SLEEK FLOATING ISLAND BRANDING & QUICK ACTIONS
          // -------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Left: Sleek Floating Brand Capsule (comfortably sized)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.border.withOpacity(0.8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AutoRickshawIcon(size: 24),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      BrandConfig.appName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: BrandConfig.accentYellow,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isMr ? 'धाराशिव' : 'Dharashiv',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: BrandConfig.textPrimaryBlack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Floating Language Pill & Profile Shortcut
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Language Toggle Pill
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: AppColors.border.withOpacity(0.8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language, size: 16, color: AppColors.textPrimary),
                                      const SizedBox(width: 5),
                                      Text(
                                        isMr ? 'English' : 'मराठी',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Profile Avatar
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.go('/customer/profile'),
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border.withOpacity(0.8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 17,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'C',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Graceful Location Permission Banner (shown if permission not granted)
                    if (!locationState.isGranted) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE082)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_outlined, size: 16, color: Color(0xFFF57F17)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings.locationPermissionDisabled,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.read(locationProvider.notifier).requestPermission(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isMr ? 'चालू करा' : 'Enable',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------
          // 4. POLISHED RAPIDO/UBER-INSPIRED DRAGGABLE BOTTOM SHEET
          // -------------------------------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.44,
            minChildSize: 0.30,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.30, 0.44, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    // Top Drag Pill
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEE2E6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Greeting & Dharashiv Subtitle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${strings.greetingHello} ${user?.name ?? (isMr ? 'ग्राहक' : 'Customer')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.whereToGo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                isMr ? '०% कमिशन' : '0% Commission',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Rapido/Uber-Style Route Selection Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Left Route Indicator Column
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 32,
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                color: const Color(0xFFCED4DA),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(2.5),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Middle Pickup and Destination Fields
                          Expanded(
                            child: Column(
                              children: [
                                // Pickup Field
                                InkWell(
                                  onTap: () => _showPlacePicker(isPickup: true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          strings.pickupLocation.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _pickup.getName(isMr),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 10, color: AppColors.border),
                                // Destination Field
                                InkWell(
                                  onTap: () => _showPlacePicker(isPickup: false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          strings.destinationLocation.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _destination.getName(isMr),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right Swap Button (Clearly visible with subtle accent and shadow)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert, size: 22, color: AppColors.textPrimary),
                              tooltip: strings.swapLocations,
                              onPressed: _swapLocations,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fare Preview & Distance Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.suggestedFare,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '₹${roundedFare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        '${routeEstimate.distanceKm} km • ~${routeEstimate.estimatedDurationMinutes}m',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMr ? '०% कमिशन' : '0% Commission',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  strings.directToDriver,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Yellow Primary Action: Book Auto Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandConfig.accentYellow,
                        foregroundColor: BrandConfig.textPrimaryBlack,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        context.push('/customer/fare-preview', extra: {
                          'pickup': _pickup.toLocationPoint(),
                          'destination': _destination.toLocationPoint(),
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.electric_rickshaw, size: 22, color: BrandConfig.textPrimaryBlack),
                          const SizedBox(width: 8),
                          Text(
                            strings.bookAuto,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recently Visited Places Section (Replaced Popular Places as requested)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: BrandConfig.accentYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.recentlyVisitedPlaces,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            isMr ? 'अलीकडील' : 'Recent',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Recently Visited Place Cards
                    SizedBox(
                      height: 122,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: DemoData.popularPlaces.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final place = DemoData.popularPlaces[index];
                          final isSelected = place.id == _destination.id;
                          final categoryColor = _getCategoryColor(place.category);

                          return InkWell(
                            onTap: () {
                              setState(() => _destination = place);
                              _mapController.move(
                                LatLng(place.latitude, place.longitude),
                                MapConfig.defaultZoom,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 195,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(place.category),
                                          size: 15,
                                          color: categoryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          isMr ? 'अलीकडील ड्रॉप' : 'Recent drop',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          size: 15,
                                          color: AppColors.primaryDark,
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    place.getName(isMr),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    place.address,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trust Footnote
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.mutualFareNote,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 22, color: iconColor ?? BrandConfig.textPrimaryBlack),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}

/// Dedicated, polished Place Search Sheet with search filter and categories.
class _PlaceSearchSheet extends ConsumerStatefulWidget {
  final bool isPickup;
  final PopularPlaceModel currentSelection;
  final Function(PopularPlaceModel) onSelected;

  const _PlaceSearchSheet({
    required this.isPickup,
    required this.currentSelection,
    required this.onSelected,
  });

  @override
  ConsumerState<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends ConsumerState<_PlaceSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bus Stand':
        return Icons.directions_bus_filled;
      case 'Railway Station':
        return Icons.train;
      case 'Hospital':
        return Icons.local_hospital;
      case 'Market':
        return Icons.storefront;
      case 'College':
        return Icons.school;
      case 'Temple':
        return Icons.temple_hindu;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bus Stand':
        return Colors.blue.shade700;
      case 'Railway Station':
        return Colors.indigo.shade700;
      case 'Hospital':
        return Colors.red.shade700;
      case 'Market':
        return Colors.orange.shade800;
      case 'College':
        return Colors.purple.shade700;
      case 'Temple':
        return Colors.amber.shade900;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;

    final filteredPlaces = DemoData.popularPlaces.where((place) {
      final matchesCategory = _filterCategory == 'All' || place.category == _filterCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameEn = place.nameEn.toLowerCase();
      final nameMr = place.nameMr.toLowerCase();
      final addr = place.address.toLowerCase();
      final cat = place.category.toLowerCase();
      return nameEn.contains(q) || nameMr.contains(q) || addr.contains(q) || cat.contains(q);
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    widget.isPickup ? Icons.my_location : Icons.location_on,
                    color: widget.isPickup ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isPickup ? strings.pickupLocation : strings.destinationLocation,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: strings.searchPlaces,
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips in Search
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildSearchChip('All', isMr ? 'सर्व' : 'All'),
                const SizedBox(width: 8),
                _buildSearchChip('Bus Stand', isMr ? 'बस स्थानक' : 'Bus Stand'),
                const SizedBox(width: 8),
                _buildSearchChip('Railway Station', isMr ? 'रेल्वे' : 'Railway'),
                const SizedBox(width: 8),
                _buildSearchChip('Hospital', isMr ? 'रुग्णालय' : 'Hospital'),
                const SizedBox(width: 8),
                _buildSearchChip('Market', isMr ? 'बाजार' : 'Market'),
                const SizedBox(width: 8),
                _buildSearchChip('College', isMr ? 'महाविद्यालय' : 'College'),
                const SizedBox(width: 8),
                _buildSearchChip('Temple', isMr ? 'मंदिर' : 'Temple'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Use Current Location Option (for Pickup)
          if (widget.isPickup && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: InkWell(
                onTap: () {
                  final busStand = DemoData.popularPlaces[0];
                  widget.onSelected(busStand);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.useCurrentLocation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              isMr ? 'धाराशिव केंद्र (GPS सक्रिय)' : 'Dharashiv Center (GPS Active)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Divider(height: 14, color: AppColors.border),

          // Filtered Places List
          Expanded(
            child: filteredPlaces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          isMr ? 'कोणतेही ठिकाण सापडले नाही' : 'No landmarks found',
                          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredPlaces.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      final isCurrent = place.id == widget.currentSelection.id;
                      final categoryColor = _getCategoryColor(place.category);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getCategoryIcon(place.category), color: categoryColor, size: 20),
                        ),
                        title: Text(
                          place.getName(isMr),
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 14,
                            color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          place.address,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle, color: AppColors.primaryDark, size: 20)
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  place.getCategoryName(isMr),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                        onTap: () {
                          widget.onSelected(place);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSearchChip(String key, String label) {
    final isSelected = _filterCategory == key;
    return InkWell(
      onTap: () => setState(() => _filterCategory = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellow : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? BrandConfig.textPrimaryBlack : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
