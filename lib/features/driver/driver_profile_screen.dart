import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final driver = ref.watch(currentDriverProvider) ?? DemoData.demoDriver;
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final activeLang = ref.watch(languageProvider);
    final rideRepo = ref.watch(rideRepositoryProvider.notifier);

    final earnings = rideRepo.calculateDriverEarnings(driver.id);
    final totalEarnings = earnings['totalEarnings'] as double? ?? driver.totalEarnings;
    final completedCount = earnings['totalRidesCount'] as int? ?? driver.totalRides;

    final isVerified = driver.verificationStatus == DriverVerificationStatus.approved;

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(isMr ? 'चालक प्रोफाईल व वाहनाची माहिती' : 'Driver & Vehicle Profile'),
        centerTitle: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Driver Identity & Verification Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: BrandConfig.accentYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: BrandConfig.textPrimaryBlack, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              driver.phone,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isVerified ? AppColors.success : AppColors.warning,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified ? Icons.verified : Icons.pending_actions,
                                        size: 13,
                                        color: isVerified ? AppColors.success : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isVerified
                                            ? (isMr ? 'सत्यापित चालक' : 'Verified Driver')
                                            : (isMr ? 'पडताळणी प्रलंबित' : 'Pending Verification'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isVerified ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: ${driver.id.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
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
                    ],
                  ),
                  const Divider(height: 24),
                  // Rating & Completed Trips Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 18, color: Color(0xFFFFA000)),
                              const SizedBox(width: 4),
                              Text(
                                '${driver.rating}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'रेटिंग' : 'Rating',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      Column(
                        children: [
                          Text(
                            '$completedCount',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'एकूण प्रवास' : 'Completed Rides',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      Column(
                        children: [
                          Text(
                            '₹${totalEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.success),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMr ? 'एकूण कमाई' : 'Total Earned',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Vehicle Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AutoRickshawIcon(size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isMr ? 'ऑटो रिक्षा तपशील' : 'Auto-Rickshaw Details',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isMr ? 'नोंदणी क्रमांक' : 'Registration Number',
                    driver.autoNumber,
                    icon: Icons.confirmation_number_outlined,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    isMr ? 'वाहन मॉडेल' : 'Vehicle Model',
                    'Bajaj Compact RE (3-Seater)',
                    icon: Icons.electric_rickshaw_outlined,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    isMr ? 'परवाना व परमीट' : 'Permit Status',
                    'Dharashiv Municipal Auto Permit (Valid)',
                    icon: Icons.badge_outlined,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    isMr ? 'इंधन प्रकार' : 'Fuel Type',
                    'CNG / Petrol',
                    icon: Icons.local_gas_station_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Earnings & Direct Payout Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        isMr ? 'थेट बँक / UPI पेमेंट' : 'Direct Bank / UPI Payments',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isMr ? 'चालक UPI आयडी' : 'Driver UPI ID',
                    driver.upiId.isNotEmpty ? driver.upiId : 'ramesh.shinde@ybl',
                    icon: Icons.qr_code_2,
                  ),
                  const Divider(height: 16),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2E7D32)),
                    ),
                    title: Text(
                      isMr ? '०% कमिशन धोरण हमी' : '0% Platform Commission Guarantee',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    subtitle: Text(
                      isMr
                          ? 'DharRide वर कोणतेही मध्यस्थ किंवा कमिशन शुल्क नाही. प्रवाशांकडून मिळणारे १००% भाडे थेट चालकाचे असते.'
                          : '100% of customer fare goes directly to you. Zero cuts, zero commissions.',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Language Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        strings.languageSettings,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLangTile(
                          title: 'मराठी',
                          subtitle: 'Marathi',
                          isSelected: activeLang == AppLanguage.marathi,
                          onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.marathi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLangTile(
                          title: 'English',
                          subtitle: 'इंग्रजी',
                          isSelected: activeLang == AppLanguage.english,
                          onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.english),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Driver Support & Settings Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'चालक साहाय्य आणि सेटिंग्ज' : 'Driver Support & Settings',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined, size: 20),
                    title: Text(isMr ? 'सूचना सेटिंग्ज' : 'Notification Settings', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/notifications/settings'),
                  ),
                  const Divider(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.headset_mic_outlined, size: 20, color: BrandConfig.textPrimaryBlack),
                    title: Text(isMr ? 'धाराशिव ऑटो युनियन हेल्पलाइन' : 'Dharashiv Auto Driver Helpline', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(BrandConfig.supportPhone, style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Driver Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ref.read(currentUserProvider.notifier).logout();
                  ref.read(currentDriverProvider.notifier).setDriver(null);
                  ref.read(rideRepositoryProvider.notifier).clearActiveRide();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                label: Text(
                  isMr ? 'चालक लॉगआउट' : 'Driver Logout',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLangTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellowLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13.5,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

