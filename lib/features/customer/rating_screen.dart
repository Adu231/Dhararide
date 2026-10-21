import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  final List<String> _feedbackTags = [
    'Polite Driver',
    'Safe Driving',
    'Clean Rickshaw',
    'Fair Price',
    'Quick Pickup',
  ];
  final Set<String> _selectedTags = {'Polite Driver', 'Safe Driving'};

  void _submitRating() {
    final activeRide = ref.read(rideRepositoryProvider).activeRide;
    if (activeRide != null) {
      ref.read(rideRepositoryProvider.notifier).submitRating(
        activeRide.id,
        _selectedRating,
        _commentController.text.trim(),
      );
    }
    context.go('/customer/home');
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.rateDriver)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const AutoRickshawIcon(size: 64),
            const SizedBox(height: 16),
            Text(
              strings.rateYourExperience,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _selectedRating ? Icons.star : Icons.star_border,
                    size: 38,
                    color: AppColors.primaryDark,
                  ),
                  onPressed: () => setState(() => _selectedRating = starValue),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _feedbackTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: strings.writeFeedback,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: strings.submit,
              onClick: _submitRating,
            ),
          ],
        ),
      ),
    );
  }
}
