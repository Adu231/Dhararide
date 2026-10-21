import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../../core/localization/app_strings.dart';

// Current User Notifier
class CurrentUserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  void login(UserModel user) => state = user;
  void logout() => state = null;
  void updateLanguage(AppLanguage language) {
    if (state != null) {
      state = state!.copyWith(language: language);
    }
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel?>(CurrentUserNotifier.new);

// Current Driver Notifier
class CurrentDriverNotifier extends Notifier<DriverModel?> {
  @override
  DriverModel? build() => null;

  void setDriver(DriverModel? driver) => state = driver;

  void updateAvailability(DriverAvailability availability) {
    if (state != null) {
      state = state!.copyWith(availability: availability);
    }
  }

  void updateVerification(DriverVerificationStatus status) {
    if (state != null) {
      state = state!.copyWith(verificationStatus: status);
    }
  }
}

final currentDriverProvider = NotifierProvider<CurrentDriverNotifier, DriverModel?>(CurrentDriverNotifier.new);

// Active Language Notifier
class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.marathi : AppLanguage.english;
  }

  void setLanguage(AppLanguage lang) => state = lang;
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});

// Onboarding Notifier
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
