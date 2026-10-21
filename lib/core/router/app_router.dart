import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../data/models/location_model.dart';
import '../../data/models/ride_model.dart';
import '../../data/session/session_manager.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';

import '../../features/customer/customer_shell.dart';
import '../../features/customer/customer_home_screen.dart';
import '../../features/customer/fare_preview_screen.dart';
import '../../features/customer/searching_driver_screen.dart';
import '../../features/customer/active_ride_customer_screen.dart';
import '../../features/customer/payment_screen.dart';
import '../../features/customer/rating_screen.dart';
import '../../features/customer/customer_rides_screen.dart';
import '../../features/customer/customer_notifications_screen.dart';
import '../../features/customer/customer_profile_screen.dart';

import '../../features/driver/driver_shell.dart';
import '../../features/driver/driver_home_screen.dart';
import '../../features/driver/active_ride_driver_screen.dart';
import '../../features/driver/pending_approval_screen.dart';

import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/admin/admin_drivers_screen.dart';
import '../../features/admin/admin_rides_screen.dart';
import '../../features/admin/admin_complaints_screen.dart';
import '../../features/admin/admin_announcements_screen.dart';

import '../../features/common/ride_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Shell
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/customer/home',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/customer/rides',
            builder: (context, state) => const CustomerRidesScreen(),
          ),
          GoRoute(
            path: '/customer/notifications',
            builder: (context, state) => const CustomerNotificationsScreen(),
          ),
          GoRoute(
            path: '/customer/profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
        ],
      ),

      // Customer Flow Screens
      GoRoute(
        path: '/customer/fare-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final pickup = extra?['pickup'] as LocationPointModel? ??
              const LocationPointModel(address: 'Dharashiv Central Bus Stand', placeName: 'Central Bus Stand');
          final destination = extra?['destination'] as LocationPointModel? ??
              const LocationPointModel(address: 'Civil Hospital', placeName: 'Civil Hospital');
          return FarePreviewScreen(pickup: pickup, destination: destination);
        },
      ),
      GoRoute(
        path: '/customer/searching',
        builder: (context, state) => const SearchingDriverScreen(),
      ),
      GoRoute(
        path: '/customer/active-ride',
        builder: (context, state) => const ActiveRideCustomerScreen(),
      ),
      GoRoute(
        path: '/customer/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/customer/rating',
        builder: (context, state) => const RatingScreen(),
      ),

      // Driver Shell
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver/home',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/driver/rides',
            builder: (context, state) => const CustomerRidesScreen(),
          ),
          GoRoute(
            path: '/driver/notifications',
            builder: (context, state) => const CustomerNotificationsScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
        ],
      ),

      // Driver Flow Screens
      GoRoute(
        path: '/driver/active-ride',
        builder: (context, state) => const ActiveRideDriverScreen(),
      ),
      GoRoute(
        path: '/driver/pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // Admin Flow Screens
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/drivers',
        builder: (context, state) => const AdminDriversScreen(),
      ),
      GoRoute(
        path: '/admin/rides',
        builder: (context, state) => const AdminRidesScreen(),
      ),
      GoRoute(
        path: '/admin/complaints',
        builder: (context, state) => const AdminComplaintsScreen(),
      ),
      GoRoute(
        path: '/admin/announcements',
        builder: (context, state) => const AdminAnnouncementsScreen(),
      ),

      // Common Receipt
      GoRoute(
        path: '/ride-detail',
        builder: (context, state) {
          final ride = state.extra as RideModel;
          return RideDetailScreen(ride: ride);
        },
      ),
    ],
  );
});
