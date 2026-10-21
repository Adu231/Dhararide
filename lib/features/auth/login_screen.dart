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
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '9822012345');
  final _passwordController = TextEditingController(text: 'password123');
  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;

  void _handleLogin() {
    final userRepo = ref.read(userRepositoryProvider.notifier);
    final user = userRepo.login(_phoneController.text.trim(), _selectedRole);

    if (user != null) {
      ref.read(currentUserProvider.notifier).login(user);
      if (user.role == UserRole.driver) {
        final drivers = ref.read(driverRepositoryProvider);
        final driver = drivers.firstWhere(
          (d) => d.userId == user.id || d.phone == user.phone,
          orElse: () => DemoData.demoDriver,
        );
        ref.read(currentDriverProvider.notifier).setDriver(driver);
        context.go('/driver/home');
      } else if (user.role == UserRole.admin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/customer/home');
      }
    }
  }

  void _demoQuickLogin(UserRole role) {
    setState(() => _selectedRole = role);
    switch (role) {
      case UserRole.customer:
        _phoneController.text = DemoData.demoCustomer.phone;
        break;
      case UserRole.driver:
        _phoneController.text = DemoData.demoDriverUser.phone;
        break;
      case UserRole.admin:
        _phoneController.text = DemoData.demoAdmin.phone;
        break;
    }
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return ResponsiveContainer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    const AutoRickshawIcon(size: 64),
                    const SizedBox(height: 12),
                    Text(
                      BrandConfig.appName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.appTagline,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Role Selector Tabs
              Text(
                strings.selectRole,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildRolePill('Customer', UserRole.customer),
                    _buildRolePill('Driver', UserRole.driver),
                    _buildRolePill('Admin', UserRole.admin),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Phone Field
              Text(strings.mobileNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android, size: 20),
                  hintText: 'Enter 10-digit mobile number',
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Text(strings.password, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  hintText: 'Enter password',
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: strings.login,
                onClick: _handleLogin,
              ),
              const SizedBox(height: 16),

              // Register Link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    "Don't have an account? ${strings.register}",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Demo Switcher Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 18, color: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          strings.loginDemoHint,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _demoQuickLogin(UserRole.customer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(strings.demoCustomerBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _demoQuickLogin(UserRole.driver),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(strings.demoDriverBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _demoQuickLogin(UserRole.admin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(strings.demoAdminBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolePill(String title, UserRole role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
