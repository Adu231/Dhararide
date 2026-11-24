import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/driver_model.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/session/session_manager.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final driver = ref.watch(currentDriverProvider);
    final user = ref.watch(currentUserProvider);

    final autoNumber = driver?.autoNumber ?? 'MH-25-AB-1234';
    final driverName = driver?.name ?? user?.name ?? 'Driver Partner';
    final phone = driver?.phone ?? user?.phone ?? '';

    final docs = driver?.documents;
    final uploadedCount = docs?.uploadedCount ?? 6;

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: BrandConfig.backgroundWhite,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const AutoRickshawIcon(size: 72, badgeColor: BrandConfig.accentYellow),
                const SizedBox(height: 18),
                Text(
                  strings.verificationPending,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BrandConfig.textPrimaryBlack),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.verificationPendingDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: BrandConfig.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 24),

                // Application Status Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BrandConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              driverName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BrandConfig.accentYellowLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: BrandConfig.accentYellowDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.hourglass_top_rounded, size: 14, color: BrandConfig.textPrimaryBlack),
                                const SizedBox(width: 4),
                                Text(
                                  isMr ? 'पडताळणी सुरू' : 'Under Review',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: BrandConfig.textPrimaryBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('🛺 Auto Number: $autoNumber', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('📱 Mobile: +91 $phone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const Divider(height: 20),

                      // Document Checklist
                      Text(
                        isMr ? 'सादर केलेली कागदपत्रे ($uploadedCount/६)' : 'Submitted Verification Documents ($uploadedCount/6)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _buildDocItem('Aadhaar Card – Front Side', isMr ? 'आधार कार्ड – पुढील बाजू' : null),
                      _buildDocItem('Aadhaar Card – Back Side', isMr ? 'आधार कार्ड – मागील बाजू' : null),
                      _buildDocItem('Driving Licence – Front Side', isMr ? 'ड्रायव्हिंग लायसन्स – पुढील बाजू' : null),
                      _buildDocItem('Driving Licence – Back Side', isMr ? 'ड्रायव्हिंग लायसन्स – मागील बाजू' : null),
                      _buildDocItem('Vehicle RC Book', isMr ? 'वाहन आरसी बुक' : null),
                      _buildDocItem('Driver Profile Photo', isMr ? 'चालक प्रोफाइल फोटो' : null),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Office Walk-in Helpdesk
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 22, color: BrandConfig.textPrimaryBlack),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? 'त्वरित पडताळणी केंद्र' : 'Express Physical Verification',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            Text(
                              isMr
                                  ? 'धाराशिव मध्यवर्ती बस स्थानक ऑफिसमध्ये त्वरित पडताळणी उपलब्ध.'
                                  : 'Visit DharRide Helpdesk at Dharashiv Central Bus Stand for instant approval.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  text: isMr ? 'स्थिती तपासा (Refresh Status)' : 'Refresh Verification Status',
                  onClick: () {
                    // Check if driver has been approved in repository
                    final drivers = ref.read(driverRepositoryProvider);
                    final updatedDriver = drivers.firstWhere(
                      (d) => d.id == driver?.id || d.phone == phone,
                      orElse: () => driver!,
                    );

                    if (updatedDriver.verificationStatus == DriverVerificationStatus.approved) {
                      ref.read(currentDriverProvider.notifier).setDriver(updatedDriver);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Congratulations! Your driver account has been approved!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.go('/driver/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isMr
                                ? 'कागदपत्रे तपासणी सुरू आहे. कृपया काही वेळ प्रतीक्षा करा.'
                                : 'Your application is still under review by DharRide admin.',
                          ),
                          backgroundColor: BrandConfig.textPrimaryBlack,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: strings.logout,
                  onClick: () {
                    ref.read(currentUserProvider.notifier).logout();
                    ref.read(currentDriverProvider.notifier).setDriver(null);
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocItem(String titleEn, String? titleMr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titleMr ?? titleEn,
              style: const TextStyle(fontSize: 12, color: BrandConfig.textPrimaryBlack),
            ),
          ),
          const Text('Received', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
