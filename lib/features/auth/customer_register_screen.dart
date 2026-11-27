import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class CustomerRegisterScreen extends ConsumerStatefulWidget {
  final String verifiedPhone;

  const CustomerRegisterScreen({
    super.key,
    required this.verifiedPhone,
  });

  @override
  ConsumerState<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends ConsumerState<CustomerRegisterScreen> {
  final _nameController = TextEditingController();
  late AppLanguage _selectedLanguage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(languageProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final strings = ref.read(stringsProvider);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.isMr ? 'कृपया तुमचे पूर्ण नाव प्रविष्ट करा' : 'Please enter your full name',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Create the new customer account in repository
    final userRepo = ref.read(userRepositoryProvider.notifier);
    final newUser = userRepo.registerCustomer(
      name: name,
      phone: widget.verifiedPhone,
      language: _selectedLanguage,
    );

    // 2. Save language preference
    ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);

    // 3. Create persistent authenticated session and update state
    ref.read(currentUserProvider.notifier).login(newUser, persist: true);

    // 4. Navigate directly to Customer Dashboard
    try {
      context.go('/customer/home');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandConfig.textPrimaryBlack),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          BrandConfig.appName,
          style: const TextStyle(
            color: BrandConfig.textPrimaryBlack,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ResponsiveContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const AutoRickshawIcon(size: 52),
                      const SizedBox(height: 12),
                      Text(
                        strings.completeCustomerProfile,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: BrandConfig.textPrimaryBlack,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.completeProfileSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BrandConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preverified Mobile Number Card (Read-only, no re-entry)
                Text(
                  strings.mobileNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, size: 18, color: BrandConfig.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '+91 ${widget.verifiedPhone}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              strings.preverifiedMobileBadge,
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
                ),
                const SizedBox(height: 18),

                // Full Name Input Field
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BrandConfig.textPrimaryBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    hintText: isMr ? 'पूर्ण नाव' : 'Full Name',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
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
                const SizedBox(height: 20),

                // Preferred Language Selection
                Text(
                  strings.preferredLanguagePrompt,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageOption(
                        language: AppLanguage.english,
                        label: 'English',
                        subLabel: 'इंग्रजी',
                        isSelected: _selectedLanguage == AppLanguage.english,
                        onTap: () {
                          setState(() => _selectedLanguage = AppLanguage.english);
                          ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLanguageOption(
                        language: AppLanguage.marathi,
                        label: 'मराठी',
                        subLabel: 'Marathi',
                        isSelected: _selectedLanguage == AppLanguage.marathi,
                        onTap: () {
                          setState(() => _selectedLanguage = AppLanguage.marathi);
                          ref.read(languageProvider.notifier).setLanguage(AppLanguage.marathi);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit / Get Started Button
                PrimaryButton(
                  text: _isSubmitting ? (isMr ? 'सुरू होत आहे...' : 'Starting...') : strings.getStartedText,
                  onClick: _isSubmitting ? () {} : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required AppLanguage language,
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellow.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? BrandConfig.textPrimaryBlack : BrandConfig.textSecondary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BrandConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
