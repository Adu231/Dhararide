import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../brand/brand_config.dart';

/// Itemized breakdown of the calculated auto-rickshaw fare.
class FareBreakdown {
  /// The road-route distance in kilometers used for calculation.
  final double distanceKm;

  /// Base fare covering up to [baseDistanceKm] (default: ₹20.0).
  final double baseFare;

  /// Distance threshold covered by the base fare in kilometers (default: 1.5 km).
  final double baseDistanceKm;

  /// Additional distance beyond the base distance subject to [ratePerKm].
  final double billableDistanceKm;

  /// Fare charged for the additional distance.
  final double distanceFare;

  /// Rate per kilometer applied after [baseDistanceKm] (default: ₹12.0/km).
  final double ratePerKm;

  /// Platform commission fee (always ₹0.0 in DharRide - 0% commission).
  final double platformFee;

  /// Unrounded exact calculated fare.
  final double rawTotalFare;

  /// Final total fare rounded for customer convenience (rounded to nearest ₹1).
  final double totalFare;

  /// Cash-friendly rounded fare (rounded to nearest ₹5).
  final double cashRoundedFare;

  /// Flag indicating whether the fare is an estimate or final confirmed.
  final bool isEstimated;

  const FareBreakdown({
    required this.distanceKm,
    required this.baseFare,
    required this.baseDistanceKm,
    required this.billableDistanceKm,
    required this.distanceFare,
    required this.ratePerKm,
    required this.platformFee,
    required this.rawTotalFare,
    required this.totalFare,
    required this.cashRoundedFare,
    this.isEstimated = true,
  });

  @override
  String toString() {
    return 'FareBreakdown(dist: ${distanceKm}km, base: ₹$baseFare, extraDist: ${billableDistanceKm}km @ ₹$ratePerKm/km = ₹$distanceFare, total: ₹$totalFare)';
  }
}

/// Centralized, configurable service for calculating DharRide auto-rickshaw fares.
///
/// Business Rules:
/// - Base fare: ₹20.0 covering the first 1.5 km.
/// - Distance beyond 1.5 km: ₹12.0 per km (development configurable placeholder).
/// - Platform commission: 0.0% (Platform fee = ₹0).
/// - Rounding: Round to nearest ₹5 for local auto cash convenience, or ₹1 for UPI.
class FareCalculationService {
  /// Base fare in Indian Rupees (₹).
  final double baseFare;

  /// Distance in kilometers covered by the base fare.
  final double baseDistanceKm;

  /// Rate in Indian Rupees per kilometer beyond [baseDistanceKm].
  final double ratePerKm;

  /// Platform commission percentage (0% for DharRide).
  final double commissionPercentage;

  const FareCalculationService({
    this.baseFare = 20.0,
    this.baseDistanceKm = 1.5,
    this.ratePerKm = BrandConfig.baseFarePerKm, // ₹12.0/km
    this.commissionPercentage = BrandConfig.commissionPercentage, // 0.0%
  });

  /// Calculates a complete transparent [FareBreakdown] from a road-route distance.
  ///
  /// Formula:
  /// - If distanceKm <= baseDistanceKm: fare = baseFare
  /// - If distanceKm > baseDistanceKm: fare = baseFare + (distanceKm - baseDistanceKm) * ratePerKm
  FareBreakdown calculateFare({
    required double distanceKm,
    bool isEstimated = true,
    bool roundToNearestFive = true,
  }) {
    // Guard against negative or invalid distances
    final safeDistance = distanceKm < 0.0 ? 0.0 : distanceKm;

    final billableKm = (safeDistance > baseDistanceKm)
        ? (safeDistance - baseDistanceKm)
        : 0.0;

    final distanceFare = billableKm * ratePerKm;
    final rawTotal = baseFare + distanceFare;

    // Nearest ₹1 integer rounding
    final totalToRupee = rawTotal.roundToDouble();

    // Nearest ₹5 rounding (e.g. ₹22 -> ₹20, ₹23 -> ₹25)
    final totalToFive = (rawTotal / 5.0).round() * 5.0;

    final finalTotal = roundToNearestFive ? totalToFive : totalToRupee;

    return FareBreakdown(
      distanceKm: safeDistance,
      baseFare: baseFare,
      baseDistanceKm: baseDistanceKm,
      billableDistanceKm: double.parse(billableKm.toStringAsFixed(2)),
      distanceFare: double.parse(distanceFare.toStringAsFixed(2)),
      ratePerKm: ratePerKm,
      platformFee: 0.0,
      rawTotalFare: rawTotal,
      totalFare: finalTotal,
      cashRoundedFare: totalToFive,
      isEstimated: isEstimated,
    );
  }
}

final fareCalculationServiceProvider = Provider<FareCalculationService>((ref) {
  return const FareCalculationService();
});
