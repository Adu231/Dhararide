import 'dart:async';
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
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class SearchingDriverScreen extends ConsumerStatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  ConsumerState<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends ConsumerState<SearchingDriverScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _mockAcceptTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // In demo mode, automatically accept ride after 3.5 seconds
    _mockAcceptTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        final rideRepo = ref.read(rideRepositoryProvider.notifier);
        final activeRide = ref.read(rideRepositoryProvider).activeRide;
        if (activeRide != null) {
          rideRepo.driverAcceptRide(activeRide.id, DemoData.demoDriver);
          context.pushReplacement('/customer/active-ride');
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _mockAcceptTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final activeRide = ref.watch(rideRepositoryProvider).activeRide;

    return ResponsiveContainer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Radar Rings
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Container(
                          width: 220 * _animController.value,
                          height: 220 * _animController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity((1.0 - _animController.value) * 0.4),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: AutoRickshawIcon(size: 60),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                strings.searchingNearby,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                strings.connectingDriver,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              SecondaryButton(
                text: strings.cancelRequest,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).cancelActiveRide('User cancelled');
                  context.go('/customer/home');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
