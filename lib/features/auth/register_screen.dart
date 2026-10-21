import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _autoNumberController = TextEditingController(text: 'MH-25-');
  final _upiIdController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  void _handleRegister() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and phone number')),
      );
      return;
    }

    final user = ref.read(userRepositoryProvider.notifier).register(
      name: name,
      phone: phone,
      email: email,
      role: _selectedRole,
    );
    ref.read(currentUserProvider.notifier).login(user);

    if (_selectedRole == UserRole.driver) {
      final driver = ref.read(driverRepositoryProvider.notifier).registerDriver(
        userId: user.id,
        name: user.name,
        phone: user.phone,
        autoNumber: _autoNumberController.text.trim(),
        upiId: _upiIdController.text.trim(),
      );
      ref.read(currentDriverProvider.notifier).setDriver(driver);
      context.go('/driver/home');
    } else {
      context.go('/customer/home');
    }
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
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.register,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role Selector
              Text(strings.selectRole, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(strings.roleCustomer),
                      selected: _selectedRole == UserRole.customer,
                      selectedColor: AppColors.primary,
                      onSelected: (val) => setState(() => _selectedRole = UserRole.customer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(strings.roleDriver),
                      selected: _selectedRole == UserRole.driver,
                      selectedColor: AppColors.primary,
                      onSelected: (val) => setState(() => _selectedRole = UserRole.driver),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(strings.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter full name'),
              ),
              const SizedBox(height: 16),

              Text(strings.mobileNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '10-digit mobile number'),
              ),
              const SizedBox(height: 16),

              Text(strings.emailOptional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'user@example.com'),
              ),
              const SizedBox(height: 16),

              // Driver specific fields
              if (_selectedRole == UserRole.driver) ...[
                Text(strings.autoNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _autoNumberController,
                  decoration: const InputDecoration(hintText: 'MH-25-AB-1234'),
                ),
                const SizedBox(height: 16),
                Text(strings.upiId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _upiIdController,
                  decoration: const InputDecoration(hintText: 'driver@upi'),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
              PrimaryButton(
                text: strings.register,
                onClick: _handleRegister,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    "Already have an account? ${strings.login}",
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
