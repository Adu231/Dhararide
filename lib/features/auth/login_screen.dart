import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '9822012345');
  final _otpController = TextEditingController(text: '1234');

  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _cleanPhone =>
      _phoneController.text.trim().replaceAll('+91', '').replaceAll(' ', '').replaceAll('-', '');

  void _handleSendOtp() {
    final phone = _cleanPhone;
    final strings = ref.read(stringsProvider);

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.invalidMobileError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network call to send OTP to backend
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _otpController.text = '1234'; // Default simulation OTP
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.isMr
                ? '+91 $phone वर ४-अंकी OTP पाठवला आहे (चाचणी कोड: 1234)'
                : '4-digit OTP sent to +91 $phone (Test code: 1234)',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    final phone = _cleanPhone;
    final strings = ref.read(stringsProvider);

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.isMr ? 'कृपया ४-अंकी OTP प्रविष्ट करा' : 'Please enter a 4-digit OTP',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Backend identifies user by phone number
      final userRepo = ref.read(userRepositoryProvider.notifier);
      final existingUser = userRepo.getUserByPhone(phone);

      if (existingUser != null) {
        // 1. Existing Account Flow: Restore authenticated session
        // Clear previous state to prevent leakage
        ref.read(currentDriverProvider.notifier).setDriver(null);
        ref.read(rideRepositoryProvider.notifier).clearActiveRide();

        // Save persistent session securely
        ref.read(currentUserProvider.notifier).login(existingUser, persist: true);
        if (existingUser.language != ref.read(languageProvider)) {
          ref.read(languageProvider.notifier).setLanguage(existingUser.language);
        }

        // Role-based routing determined strictly by backend user record
        if (existingUser.role == UserRole.driver) {
          final drivers = ref.read(driverRepositoryProvider);
          final driver = drivers.firstWhere(
            (d) => d.userId == existingUser.id || d.phone == existingUser.phone,
            orElse: () => DemoData.demoDriver,
          );
          ref.read(currentDriverProvider.notifier).setDriver(driver);
          if (driver.verificationStatus == DriverVerificationStatus.pending) {
            context.go('/driver/pending');
          } else {
            context.go('/driver/home');
          }
        } else if (existingUser.role == UserRole.admin) {
          context.go('/admin/dashboard');
        } else {
          context.go('/customer/home');
        }
      } else {
        // 2. New Customer Flow: Navigate to minimal registration (Name + Language)
        context.push('/customer-register?phone=$phone');
      }
    });
  }

  void _selectDemoAccount(String phone) {
    setState(() {
      _phoneController.text = phone;
      _isOtpSent = false;
      _otpController.text = '1234';
    });
    _handleSendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Brand Header with DharRide Logo
                Center(
                  child: Column(
                    children: [
                      const AutoRickshawIcon(size: 68),
                      const SizedBox(height: 14),
                      Text(
                        BrandConfig.appName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: BrandConfig.textPrimaryBlack,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.welcomeToDharRide,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrandConfig.textPrimaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.enterMobilePrompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BrandConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Common Entry Phone Number Input
                Text(
                  strings.mobileNumber,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  onChanged: (val) {
                    if (_isOtpSent) {
                      setState(() => _isOtpSent = false);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_android, size: 20, color: BrandConfig.textPrimaryBlack),
                          const SizedBox(width: 8),
                          const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 20, color: AppColors.border),
                        ],
                      ),
                    ),
                    hintText: isMr ? '९८२२०१२३४५' : '9822012345',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted.withOpacity(0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),

                // Interactive OTP Input Card when OTP is sent
                if (_isOtpSent) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BrandConfig.accentYellowLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                strings.enterOtpTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BrandConfig.textPrimaryBlack,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => setState(() => _isOtpSent = false),
                              child: Text(
                                strings.changeMobileText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strings.otpSentToNotice} +91 $_cleanPhone',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BrandConfig.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '1234',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withOpacity(0.5),
                              letterSpacing: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _handleSendOtp,
                              child: Text(
                                strings.resendOtpText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BrandConfig.textPrimaryBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Primary Action Button (Continue / Verify & Continue)
                PrimaryButton(
                  text: _isLoading
                      ? (isMr ? 'कृपया प्रतीक्षा करा...' : 'Please wait...')
                      : (_isOtpSent ? strings.verifyAndContinue : strings.continueText),
                  onClick: _isLoading
                      ? () {}
                      : (_isOtpSent ? _handleVerifyOtp : _handleSendOtp),
                ),

                const SizedBox(height: 28),

                // Become a Driver Option
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: BrandConfig.accentYellowLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.electric_rickshaw,
                          color: BrandConfig.textPrimaryBlack,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.becomeDriver,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: BrandConfig.textPrimaryBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.becomeDriverSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: BrandConfig.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandConfig.accentYellow,
                          foregroundColor: BrandConfig.textPrimaryBlack,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.go('/register'),
                        child: Text(
                          strings.applyAsDriver,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Quick Demo Accounts for Testing
                Center(
                  child: Text(
                    strings.loginDemoHint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BrandConfig.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickDemoChip(
                        label: strings.demoCustomerBtn,
                        phone: DemoData.demoCustomer.phone,
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickDemoChip(
                        label: strings.demoDriverBtn,
                        phone: DemoData.demoDriverUser.phone,
                        icon: Icons.electric_rickshaw_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickDemoChip(
                        label: strings.demoAdminBtn,
                        phone: DemoData.demoAdmin.phone,
                        icon: Icons.shield_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDemoChip({
    required String label,
    required String phone,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _selectDemoAccount(phone),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: BrandConfig.textPrimaryBlack),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: BrandConfig.textPrimaryBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
