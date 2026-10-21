import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/models/location_model.dart';
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

  void _confirmBooking() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(rideRepositoryProvider.notifier).createRideRequest(
        customer: user,
        pickup: widget.pickup,
        destination: widget.destination,
        suggestedFare: 20.0,
        paymentMethod: _selectedPayment,
      );
      context.pushReplacement('/customer/searching');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.suggestedFare),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.pickup.placeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 9),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 20,
                        child: VerticalDivider(color: AppColors.border, thickness: 2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.destination.placeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fare breakdown banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(strings.suggestedFare, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      const Text(
                        '₹20.00',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.mutualFareNote,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment method selector
            Text(strings.paymentMethod, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
            const Spacer(),

            PrimaryButton(
              text: 'Confirm & Request Auto',
              icon: Icons.send,
              onClick: _confirmBooking,
            ),
            const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            Icon(icon, size: 20, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
