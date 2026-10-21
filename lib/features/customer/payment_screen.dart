import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final activeRide = ref.watch(rideRepositoryProvider).activeRide;
    final upiId = activeRide?.driverUpiId ?? 'ramesh.shinde@ybl';
    final fare = activeRide?.finalFare ?? 20.0;

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.paymentMethod),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Amount Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(strings.finalFare, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${fare.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(strings.noCommissionNote, style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // UPI QR Mockup
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2, size: 140, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.scanQrToPay,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, size: 14, color: AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            PrimaryButton(
              text: strings.iHavePaid,
              icon: Icons.check_circle_outline,
              onClick: () {
                ref.read(rideRepositoryProvider.notifier).updatePayment(
                  PaymentMethod.onlineUpi,
                  PaymentStatus.confirmed,
                  fare,
                );
                context.pushReplacement('/customer/rating');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
