import '../../data/demo/demo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/dharashiv_map_widget.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';
import '../../core/widgets/status_badge.dart';
import 'pending_approval_screen.dart';

enum MockRideStage {
  pendingRequest,
  accepted,
  arrivedAtPickup,
  rideStarted,
  completed,
  rejected,
}

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = true;
  MockRideStage _mockRideStage = MockRideStage.pendingRequest;

  Future<void> _openGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final uri = Uri.parse('${BrandConfig.deepLinkMapsUrl}$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCustomerLocationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.error, size: 24),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Live Location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Rahul Deshmukh • Dharashiv Central Bus Stand',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup Spot: Dharashiv Central Bus Stand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Platform 2 Exit, Shivaji Chowk side • 0.6 km from your auto', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('0.6 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const DharashivMapWidget(
                  pickup: LatLng(18.1865, 76.0410),
                  destination: LatLng(18.1810, 76.0380),
                  userLocation: LatLng(18.1870, 76.0415),
                  pickupLabel: 'Rahul Deshmukh (Customer Current Location)',
                  destinationLabel: 'Civil Hospital & College',
                  height: 280,
                  isFullScreen: false,
                  showControls: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Open in Google Maps',
                    icon: Icons.navigation_outlined,
                    onClick: () {
                      _openGoogleMaps('Dharashiv Central Bus Stand, Dharashiv');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoStepper(int currentStep) {
    final steps = ['Accepted', 'Arrived', 'In Ride', 'Completed'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isPast = index < currentStep;
          final isCurrent = index == currentStep;

          final Color circleBg = isPast
              ? AppColors.success
              : (isCurrent ? AppColors.primary : Colors.transparent);
          final Color circleBorder = isPast
              ? AppColors.success
              : (isCurrent ? AppColors.primaryDark : AppColors.border);
          final Color iconColor = isPast
              ? Colors.white
              : (isCurrent ? AppColors.textPrimary : AppColors.textMuted);
          final Color textColor = isCurrent
              ? AppColors.textPrimary
              : (isPast ? AppColors.success : AppColors.textMuted);

          return Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: circleBorder, width: 1.5),
                    ),
                    child: Center(
                      child: isPast
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Container(
                  width: 18,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  color: index < currentStep ? AppColors.success : AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMockRideRequestCard(BuildContext context) {
    switch (_mockRideStage) {
      case MockRideStage.pendingRequest:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Demo Request badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notification_important, color: AppColors.warning, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'New Ride Request',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'REQUEST',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rahul Deshmukh',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.star, size: 14, color: AppColors.primaryDark),
                              SizedBox(width: 4),
                              Text('4.8 ★ • Cash Payment', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCustomerLocationModal(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryDark.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.error),
                            SizedBox(width: 3),
                            Text('Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Route Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _showCustomerLocationModal(context),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.my_location, color: AppColors.success, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Pickup Location:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Row(
                                      children: [
                                        const Icon(Icons.near_me, size: 11, color: AppColors.info),
                                        const SizedBox(width: 2),
                                        const Text('See on Map >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Text('Dharashiv Central Bus Stand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Text('Platform 2, Shivaji Chowk Exit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.more_vert, size: 14, color: AppColors.textMuted),
                      ),
                    ),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: AppColors.error, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Destination Drop:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text('Government Civil Hospital & College', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Main OPD Gate, Hospital Road', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Distance & Fare Details
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Column(
                      children: [
                        Text('Distance', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        SizedBox(height: 2),
                        Text('2.4 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.border),
                    const Column(
                      children: [
                        Text('Est. Time', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        SizedBox(height: 2),
                        Text('8 mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.border),
                    const Column(
                      children: [
                        Text('Sample Fare', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        SizedBox(height: 2),
                        Text('₹25', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '0% Platform Fee • 100% fare directly to you in Cash',
                  style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // Option to see customer current location
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textPrimary, width: 1.2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.location_searching_rounded, size: 18, color: AppColors.error),
                  label: const Text(
                    'See Customer Current Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  onPressed: () => _showCustomerLocationModal(context),
                ),
              ),
              const SizedBox(height: 10),

              // Accept & Reject Buttons
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Accept',
                      icon: Icons.check_circle_outline,
                      onClick: () {
                        setState(() => _mockRideStage = MockRideStage.accepted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mock Ride Accepted - Drive to Pickup'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      text: 'Reject',
                      icon: Icons.cancel_outlined,
                      borderColor: AppColors.error,
                      onClick: () {
                        setState(() => _mockRideStage = MockRideStage.rejected);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mock Ride Request Rejected'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case MockRideStage.accepted:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_car, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ride Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Heading to Pickup',
                      style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDemoStepper(0),
              const SizedBox(height: 12),

              // Customer info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rahul Deshmukh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('+91 98220 99881', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_on, color: AppColors.error),
                      tooltip: 'See Customer Location',
                      onPressed: () => _showCustomerLocationModal(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.success),
                      tooltip: 'Call Customer',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling Rahul Deshmukh: +91 98220 99881')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Route & Distance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showCustomerLocationModal(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup Location:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text('Dharashiv Central Bus Stand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Icon(Icons.near_me, size: 16, color: AppColors.info),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Destination Drop:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const Text('Government Civil Hospital & College', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Divider(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trip Distance: 2.4 km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Fare: ₹25 (Cash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Functional Button: Arrived at Pickup
              PrimaryButton(
                text: 'Arrived at Pickup',
                icon: Icons.pin_drop_rounded,
                onClick: () {
                  setState(() => _mockRideStage = MockRideStage.arrivedAtPickup);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status updated: Arrived at Pickup'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _mockRideStage = MockRideStage.rejected),
                  child: const Text('Decline / Cancel Ride', style: TextStyle(color: AppColors.error, fontSize: 11)),
                ),
              ),
            ],
          ),
        );

      case MockRideStage.arrivedAtPickup:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.how_to_reg, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ride Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'At Pickup',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDemoStepper(1),
              const SizedBox(height: 12),

              // Alert Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arrived at Central Bus Stand. Customer notified. Board passenger and start ride.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: Rahul Deshmukh (+91 98220 99881)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('Destination: Government Civil Hospital & College', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Distance: 2.4 km • Fare: ₹25 (Cash)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_on, color: AppColors.error),
                      tooltip: 'See Customer Location',
                      onPressed: () => _showCustomerLocationModal(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Functional Button: Start Ride
              PrimaryButton(
                text: 'Start Ride',
                icon: Icons.play_arrow_rounded,
                onClick: () {
                  setState(() => _mockRideStage = MockRideStage.rideStarted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride in Progress - Heading to Civil Hospital'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case MockRideStage.rideStarted:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.electric_rickshaw, color: AppColors.primaryDark, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Ride Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Trip in Progress',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDemoStepper(2),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.navigation, color: AppColors.primaryDark, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'En route to Government Civil Hospital & College',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('Sample Distance: 2.4 km remaining • Est. 8 mins', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cash to Collect at Drop: ₹25', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                        Text('0% Commission', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Functional Button: Complete Ride
              PrimaryButton(
                text: 'Complete Ride',
                icon: Icons.check_circle_rounded,
                onClick: () {
                  setState(() => _mockRideStage = MockRideStage.completed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride Completed! ₹25 cash received'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case MockRideStage.completed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.task_alt, color: AppColors.success, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Ride Completed!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDemoStepper(3),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fare Received:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('₹25 (Cash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform Fee:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('₹0 (0% Fee - 100% to Driver)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trip Route:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Bus Stand → Hospital (2.4 km)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Button to show mock request again
              PrimaryButton(
                text: 'Show Mock Request Again',
                icon: Icons.replay_rounded,
                onClick: () {
                  setState(() => _mockRideStage = MockRideStage.pendingRequest);
                },
              ),
            ],
          ),
        );

      case MockRideStage.rejected:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Mock Request Rejected',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'REJECTED',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'You declined the ride request. You can re-trigger and test it again anytime below.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Button to show mock request again
              PrimaryButton(
                text: 'Show Mock Request Again',
                icon: Icons.refresh_rounded,
                onClick: () {
                  setState(() => _mockRideStage = MockRideStage.pendingRequest);
                },
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(currentDriverProvider);
    final strings = ref.watch(stringsProvider);
    final rideState = ref.watch(rideRepositoryProvider);

    if (driver?.verificationStatus == DriverVerificationStatus.pending) {
      return const PendingApprovalScreen();
    }

    final activeRide = rideState.activeRide;
    final currentDriverId = driver?.id ?? DemoData.demoDriver.id;
    final hasSearchingRide = _isOnline && activeRide != null && activeRide.status == RideStatus.searching;
    final hasActiveOngoingRide = _isOnline &&
        activeRide != null &&
        activeRide.driverId == currentDriverId &&
        activeRide.status != RideStatus.searching &&
        activeRide.status != RideStatus.cancelled &&
        activeRide.status != RideStatus.rideCompleted;

    final earnings = ref.watch(rideRepositoryProvider.notifier).calculateDriverEarnings(currentDriverId);
    final todayEarnings = (earnings['todayEarnings'] as double? ?? 0.0).toStringAsFixed(0);
    final todayRides = (earnings['todayRidesCount'] as int? ?? 0).toString();
    final driverRating = driver?.rating ?? 4.9;
    final totalRides = driver?.totalRides ?? (earnings['totalRidesCount'] as int? ?? 0);

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

            // Mock Ride Simulation Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primaryDark, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Mock Ride Simulation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (_mockRideStage != MockRideStage.pendingRequest)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.refresh, size: 14, color: AppColors.textPrimary),
                    label: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    onPressed: () {
                      setState(() => _mockRideStage = MockRideStage.pendingRequest);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // The Interactive Mock Ride Card
            _buildMockRideRequestCard(context),
            const SizedBox(height: 16),

            // Real Searching Ride Request Card (if customer booked concurrently)
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

            // Real Ongoing Active Ride Card (allows driver to return to active ride control)
            if (hasActiveOngoingRide) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_car, color: AppColors.info, size: 20),
                            SizedBox(width: 8),
                            Text('Ongoing Customer Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        StatusBadge.fromRideStatus(activeRide.status),
                      ],
                    ),
                    const Divider(height: 18),
                    Text('Customer: ${activeRide.customerName} (${activeRide.customerPhone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Pickup: ${activeRide.pickup.placeName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('Drop: ${activeRide.destination.placeName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      text: 'Manage Live Ride (${activeRide.status.label})',
                      icon: Icons.navigation_outlined,
                      onClick: () => context.push('/driver/active-ride'),
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
                    value: '₹$todayEarnings',
                    icon: Icons.account_balance_wallet,
                    subtitle: '100% directly to you (0% fee)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: strings.todaysRides,
                    value: todayRides,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$driverRating Rating', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Based on $totalRides total rides in Dharashiv', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
