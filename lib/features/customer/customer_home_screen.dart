import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/location_field.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/models/location_model.dart';
import '../../data/session/session_manager.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  PopularPlaceModel _pickup = DemoData.popularPlaces[0];
  PopularPlaceModel _destination = DemoData.popularPlaces[2];

  void _showPlacePicker({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final strings = ref.watch(stringsProvider);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPickup ? strings.pickupLocation : strings.destinationLocation,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...DemoData.popularPlaces.map((place) {
                final isMr = strings.isMr;
                return ListTile(
                  leading: const Icon(Icons.place_outlined, color: AppColors.primaryDark),
                  title: Text(place.getName(isMr), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(place.category, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    setState(() {
                      if (isPickup) {
                        _pickup = place;
                      } else {
                        _destination = place;
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              }),
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
                const Text(BrandConfig.appName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(BrandConfig.targetCity, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switch Pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              backgroundColor: AppColors.primaryLight,
              side: const BorderSide(color: AppColors.primary),
              label: Text(
                isMr ? 'English' : 'मराठी',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.greetingHello} ${user?.name ?? 'Customer'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.whereToGo,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking Selection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationField(
                    label: strings.pickupLocation,
                    address: _pickup.getName(isMr),
                    icon: Icons.my_location,
                    iconColor: AppColors.success,
                    onTap: () => _showPlacePicker(isPickup: true),
                  ),
                  const SizedBox(height: 12),
                  LocationField(
                    label: strings.destinationLocation,
                    address: _destination.getName(isMr),
                    icon: Icons.location_on,
                    iconColor: AppColors.error,
                    onTap: () => _showPlacePicker(isPickup: false),
                  ),
                  const SizedBox(height: 16),
                  // Suggested Fare & 0% commission badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.suggestedFare, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const Text(
                            '₹20',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              '0% Commission',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: strings.bookAuto,
                    icon: Icons.electric_rickshaw,
                    onClick: () {
                      context.push('/customer/fare-preview', extra: {
                        'pickup': _pickup.toLocationPoint(),
                        'destination': _destination.toLocationPoint(),
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Popular Dharashiv Places
            Text(strings.popularPlaces, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DemoData.popularPlaces.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = DemoData.popularPlaces[index];
                  return InkWell(
                    onTap: () => setState(() => _destination = place),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.place, size: 16, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          Text(
                            place.getName(isMr),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
