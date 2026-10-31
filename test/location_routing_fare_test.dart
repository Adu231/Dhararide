import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:dharride/core/services/fare_calculation_service.dart';
import 'package:dharride/core/services/place_search_service.dart';
import 'package:dharride/core/services/routing_service.dart';

/// Mock HTTP client for deterministic routing and geocoding test assertions.
class _MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;

  _MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('FareCalculationService Tests (Dynamic Road-Distance Fare)', () {
    const fareService = FareCalculationService(
      baseFare: 20.0,
      baseDistanceKm: 1.5,
      ratePerKm: 12.0,
      commissionPercentage: 0.0,
    );

    test('Short ride under 1.5 km charges exact base fare of ₹20', () {
      final breakdown = fareService.calculateFare(distanceKm: 1.2);

      expect(breakdown.distanceKm, equals(1.2));
      expect(breakdown.baseFare, equals(20.0));
      expect(breakdown.billableDistanceKm, equals(0.0));
      expect(breakdown.distanceFare, equals(0.0));
      expect(breakdown.platformFee, equals(0.0));
      expect(breakdown.rawTotalFare, equals(20.0));
      expect(breakdown.cashRoundedFare, equals(20.0));
    });

    test('Ride at exactly 1.5 km threshold charges exact base fare of ₹20', () {
      final breakdown = fareService.calculateFare(distanceKm: 1.5);

      expect(breakdown.billableDistanceKm, equals(0.0));
      expect(breakdown.distanceFare, equals(0.0));
      expect(breakdown.cashRoundedFare, equals(20.0));
    });

    test('Ride over 1.5 km charges base fare plus ₹12 per billable km with 0% platform fee', () {
      // 3.5 km total -> 1.5 km base (₹20) + 2.0 extra km @ ₹12 = ₹24 -> raw ₹44 -> rounded to ₹45
      final breakdown = fareService.calculateFare(distanceKm: 3.5);

      expect(breakdown.distanceKm, equals(3.5));
      expect(breakdown.baseFare, equals(20.0));
      expect(breakdown.billableDistanceKm, equals(2.0));
      expect(breakdown.distanceFare, equals(24.0));
      expect(breakdown.platformFee, equals(0.0));
      expect(breakdown.rawTotalFare, equals(44.0));
      expect(breakdown.cashRoundedFare, equals(45.0)); // Rounded to nearest ₹5 for auto cash

      // When unrounded to 5 (e.g. for exact UPI payment)
      final exactBreakdown = fareService.calculateFare(distanceKm: 3.5, roundToNearestFive: false);
      expect(exactBreakdown.totalFare, equals(44.0));
    });

    test('Longer distance in Dharashiv (6.5 km) calculates transparently', () {
      // 6.5 km total -> 1.5 km base (₹20) + 5.0 extra km @ ₹12 = ₹60 -> total ₹80
      final breakdown = fareService.calculateFare(distanceKm: 6.5);

      expect(breakdown.billableDistanceKm, equals(5.0));
      expect(breakdown.distanceFare, equals(60.0));
      expect(breakdown.rawTotalFare, equals(80.0));
      expect(breakdown.cashRoundedFare, equals(80.0));
    });

    test('Zero and negative distance safety guards', () {
      final zeroBreakdown = fareService.calculateFare(distanceKm: 0.0);
      expect(zeroBreakdown.baseFare, equals(20.0));
      expect(zeroBreakdown.cashRoundedFare, equals(20.0));

      final negativeBreakdown = fareService.calculateFare(distanceKm: -5.0);
      expect(negativeBreakdown.distanceKm, equals(0.0));
      expect(negativeBreakdown.cashRoundedFare, equals(20.0));
    });
  });

  group('RoutingService Tests (Real Road Distance & OSRM Engine)', () {
    final pickup = const LatLng(18.1865, 76.0402);
    final destination = const LatLng(18.2045, 76.0355);

    test('Identical pickup and destination returns 0 km without HTTP call', () async {
      const service = RoutingService();
      final result = await service.calculateRoadRoute(pickup, pickup);

      expect(result.distanceKm, equals(0.0));
      expect(result.polylinePoints.length, equals(1));
      expect(result.isRealRoadRoute, isTrue);
      expect(result.status, equals(RoutingStatus.success));
    });

    test('Parses genuine OSRM GeoJSON road response with meters-to-km and polyline', () async {
      final mockClient = _MockHttpClient((request) async {
        expect(request.url.path.contains('/route/v1/driving'), isTrue);

        // Simulated OSRM response for Dharashiv road route: 2450 meters (2.45 km), 420 seconds (7 min)
        final osrmJson = {
          'code': 'Ok',
          'routes': [
            {
              'distance': 2450.0,
              'duration': 420.0,
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [76.0402, 18.1865],
                  [76.0410, 18.1900],
                  [76.0380, 18.1980],
                  [76.0355, 18.2045],
                ],
              },
            }
          ],
        };

        return http.Response(
          jsonEncode(osrmJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RoutingService(client: mockClient);
      final result = await service.calculateRoadRoute(pickup, destination);

      expect(result.distanceKm, closeTo(2.45, 0.01)); // Genuine road distance in kilometers
      expect(result.estimatedDurationMinutes, equals(7)); // 420s / 60
      expect(result.polylinePoints.length, equals(4));
      expect(result.polylinePoints.first.latitude, equals(18.1865));
      expect(result.polylinePoints.last.latitude, equals(18.2045));
      expect(result.isRealRoadRoute, isTrue);
      expect(result.status, equals(RoutingStatus.success));
    });

    test('Network error gracefully falls back to geodesic distance estimate without crashing', () async {
      final mockClient = _MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = RoutingService(client: mockClient);
      final result = await service.calculateRoadRoute(pickup, destination);

      expect(result.isRealRoadRoute, isFalse);
      expect(result.isGeodesicEstimate, isTrue);
      expect(result.distanceKm, greaterThan(0.0));
      expect(result.polylinePoints.length, equals(2));
      expect(result.status, equals(RoutingStatus.networkError));
    });
  });

  group('PlaceSearchService Tests (Real OSM Geocoding & Local Landmarks)', () {
    test('Matches Dharashiv local curated landmarks instantly', () async {
      final service = PlaceSearchService();
      final results = await service.searchPlaces('bus stand');

      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.name.toLowerCase().contains('bus stand')), isTrue);
      expect(results.first.latitude, greaterThan(18.0));
      expect(results.first.longitude, greaterThan(76.0));
    });

    test('Parses remote Photon OpenStreetMap geocoding response into SearchPlaceResult', () async {
      final mockClient = _MockHttpClient((request) async {
        final photonJson = {
          'features': [
            {
              'geometry': {
                'coordinates': [76.0450, 18.1920],
              },
              'properties': {
                'osm_id': 123456,
                'name': 'Dharashiv District Court',
                'street': 'Court Road',
                'city': 'Dharashiv',
                'state': 'Maharashtra',
                'type': 'amenity',
              },
            }
          ],
        };

        return http.Response(
          jsonEncode(photonJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PlaceSearchService(client: mockClient);
      final results = await service.searchPlaces('district court');

      expect(results.isNotEmpty, isTrue);
      final first = results.first;
      expect(first.name, equals('Dharashiv District Court'));
      expect(first.latitude, equals(18.1920));
      expect(first.longitude, equals(76.0450));
      expect(first.displayAddress.contains('Court Road'), isTrue);

      // Verify toPopularPlaceModel conversion retains coordinates
      final popularModel = first.toPopularPlaceModel();
      expect(popularModel.latitude, equals(18.1920));
      expect(popularModel.longitude, equals(76.0450));
    });

    test('Empty query returns default Dharashiv suggestions without making HTTP call', () async {
      var httpCalled = false;
      final mockClient = _MockHttpClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      final service = PlaceSearchService(client: mockClient);
      final emptyResults = await service.searchPlaces('');

      // Returns curated Dharashiv landmarks as convenient suggestions
      expect(emptyResults.isNotEmpty, isTrue);
      expect(httpCalled, isFalse);
    });

    test('Single-character query does not send request to remote geocoder', () async {
      var httpCalled = false;
      final mockClient = _MockHttpClient((request) async {
        httpCalled = true;
        return http.Response('{}', 200);
      });

      final service = PlaceSearchService(client: mockClient);
      await service.searchPlaces('z');

      expect(httpCalled, isFalse);
    });
  });
}
