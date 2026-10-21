import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/session/session_manager.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _finishOnboarding() {
    ref.read(onboardingCompletedProvider.notifier).complete();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    final slides = [
      {
        'title': strings.onboardingTitle1,
        'desc': strings.onboardingDesc1,
        'icon': Icons.location_on_outlined,
      },
      {
        'title': strings.onboardingTitle2,
        'desc': strings.onboardingDesc2,
        'icon': Icons.phone_in_talk_outlined,
      },
      {
        'title': strings.onboardingTitle3,
        'desc': strings.onboardingDesc3,
        'icon': Icons.handshake_outlined,
      },
    ];

    return ResponsiveContainer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header with skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AutoRickshawIcon(size: 38),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      strings.skip,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Page view for slides
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, idx) {
                    final item = slides[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 54,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Action buttons
              PrimaryButton(
                text: _currentPage == slides.length - 1 ? strings.getStarted : strings.next,
                onClick: () {
                  if (_currentPage < slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _finishOnboarding();
                  }
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
