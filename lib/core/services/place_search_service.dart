import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/demo/demo_data.dart';
import '../../data/models/location_model.dart';

/// Represents a validated place or destination search result with genuine coordinates.
class SearchPlaceResult {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final bool isPredefinedLandmark;

  const SearchPlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.isPredefinedLandmark = false,
  });

  String getName([bool isMr = false]) => name;

  String get displayAddress => address;

  PopularPlaceModel toPopularPlaceModel() {
    return PopularPlaceModel(
      id: id,
      nameEn: name,
      nameMr: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: category,
    );
  }

  LocationPointModel toLocationPoint() {
    return LocationPointModel(
      placeName: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// Abstract provider interface for place searching and geocoding.
/// Allows swapping between Photon, Nominatim, or self-hosted Pelias in production.
abstract class PlaceSearchProvider {
  Future<List<SearchPlaceResult>> searchPlaces(String query);
}

/// Hybrid place search service combining:
/// 1. Instant local landmark recommendations for Dharashiv.
/// 2. Live OpenStreetMap geocoding via Photon/Nominatim for any real-world address/place.
/// 3. In-memory caching and rate-limit preservation.
class PlaceSearchService implements PlaceSearchProvider {
  final http.Client _httpClient;

  /// Cache mapping normalized queries to search results to prevent duplicate HTTP calls.
  final Map<String, List<SearchPlaceResult>> _cache = {};

  PlaceSearchService({http.Client? httpClient, http.Client? client})
      : _httpClient = client ?? httpClient ?? http.Client();

  /// Searches for places matching [query] across predefined Dharashiv landmarks and online geocoding.
  @override
  Future<List<SearchPlaceResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _getPredefinedSuggestions();
    }

    // 1. Check in-memory cache
    if (_cache.containsKey(cleanQuery)) {
      return _cache[cleanQuery]!;
    }

    final results = <SearchPlaceResult>[];

    // 2. Search local predefined landmarks (instant match)
    final matchedLandmarks = DemoData.popularPlaces.where((p) {
      final nameEn = p.nameEn.toLowerCase();
      final nameMr = p.nameMr.toLowerCase();
      final addr = p.address.toLowerCase();
      final cat = p.category.toLowerCase();
      return nameEn.contains(cleanQuery) ||
          nameMr.contains(cleanQuery) ||
          addr.contains(cleanQuery) ||
          cat.contains(cleanQuery);
    }).map((p) => SearchPlaceResult(
          id: p.id,
          name: p.nameEn,
          address: p.address,
          latitude: p.latitude,
          longitude: p.longitude,
          category: p.category,
          isPredefinedLandmark: true,
        ));

    results.addAll(matchedLandmarks);

    // 3. Query OpenStreetMap geocoder biased toward Dharashiv, Maharashtra coordinates (lat: 18.1861, lon: 76.0419)
    try {
      final onlineResults = await _queryOsmGeocoding(cleanQuery);
      for (final onlineResult in onlineResults) {
        // Prevent duplicate results if coordinates are virtually identical (< 100 meters)
        final isDuplicate = results.any((r) =>
            (r.latitude - onlineResult.latitude).abs() < 0.001 &&
            (r.longitude - onlineResult.longitude).abs() < 0.001);

        if (!isDuplicate) {
          results.add(onlineResult);
        }
      }
    } catch (_) {
      // If network is offline, the user still receives matched predefined landmarks
    }

    _cache[cleanQuery] = results;
    return results;
  }

  /// Queries the Photon OpenStreetMap geocoding endpoint biased by Dharashiv coordinates.
  Future<List<SearchPlaceResult>> _queryOsmGeocoding(String query) async {
    if (query.trim().length < 2) {
      return const [];
    }
    final encodedQuery = Uri.encodeComponent(query);
    // Photon by Komoot: Free OSM search with coordinate biasing toward Dharashiv
    final url = Uri.parse(
      'https://photon.komoot.io/api/?q=$encodedQuery&lat=18.1861&lon=76.0419&limit=8',
    );

    final response = await _httpClient.get(
      url,
      headers: {
        'User-Agent': 'DharRide-Flutter-App/1.0 (contact: support@dharride.demo)',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      // Fallback to Nominatim if Photon fails
      return _queryNominatim(query);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      return _queryNominatim(query);
    }

    final searchResults = <SearchPlaceResult>[];
    for (int i = 0; i < features.length; i++) {
      final feat = features[i] as Map<String, dynamic>;
      final geom = feat['geometry'] as Map<String, dynamic>?;
      final props = feat['properties'] as Map<String, dynamic>?;

      if (geom != null && props != null && geom['coordinates'] is List) {
        final coords = geom['coordinates'] as List;
        if (coords.length >= 2) {
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          final name = props['name'] as String? ??
              props['street'] as String? ??
              props['city'] as String? ??
              query;

          final addressParts = <String>[];
          if (props['street'] != null && props['street'] != name) addressParts.add(props['street']);
          if (props['district'] != null) addressParts.add(props['district']);
          if (props['city'] != null && props['city'] != name) addressParts.add(props['city']);
          if (props['state'] != null) addressParts.add(props['state']);

          final address = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Dharashiv, Maharashtra';

          final category = props['osm_value'] as String? ?? 'Place';

          searchResults.add(
            SearchPlaceResult(
              id: 'osm_${props['osm_id'] ?? i}_$lon',
              name: name,
              address: address,
              latitude: lat,
              longitude: lon,
              category: _mapOsmCategory(category),
              isPredefinedLandmark: false,
            ),
          );
        }
      }
    }

    return searchResults;
  }

  /// Secondary fallback query to OpenStreetMap Nominatim.
  Future<List<SearchPlaceResult>> _queryNominatim(String query) async {
    final encodedQuery = Uri.encodeComponent('$query, Dharashiv');
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&countrycodes=in&limit=6',
    );

    final response = await _httpClient.get(
      url,
      headers: {
        'User-Agent': 'DharRide-Flutter-App/1.0 (contact: support@dharride.demo)',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List<dynamic>;
    final results = <SearchPlaceResult>[];

    for (int i = 0; i < list.length; i++) {
      final item = list[i] as Map<String, dynamic>;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      final displayName = item['display_name'] as String? ?? query;

      if (lat != null && lon != null) {
        final parts = displayName.split(',');
        final name = parts.isNotEmpty ? parts[0].trim() : query;
        final address = parts.length > 1 ? parts.sublist(1).take(2).join(', ').trim() : 'Dharashiv';

        results.add(
          SearchPlaceResult(
            id: 'nom_${item['place_id'] ?? i}',
            name: name,
            address: address,
            latitude: lat,
            longitude: lon,
            category: _mapOsmCategory(item['type']?.toString() ?? 'Place'),
            isPredefinedLandmark: false,
          ),
        );
      }
    }

    return results;
  }

  String _mapOsmCategory(String osmType) {
    switch (osmType.toLowerCase()) {
      case 'hospital':
      case 'clinic':
      case 'doctors':
        return 'Hospital';
      case 'bus_station':
      case 'bus_stop':
        return 'Bus Stand';
      case 'station':
      case 'railway':
        return 'Railway Station';
      case 'marketplace':
      case 'shop':
      case 'supermarket':
        return 'Market';
      case 'school':
      case 'college':
      case 'university':
        return 'College';
      case 'place_of_worship':
      case 'temple':
        return 'Temple';
      default:
        return 'Place';
    }
  }

  List<SearchPlaceResult> _getPredefinedSuggestions() {
    return DemoData.popularPlaces
        .map((p) => SearchPlaceResult(
              id: p.id,
              name: p.nameEn,
              address: p.address,
              latitude: p.latitude,
              longitude: p.longitude,
              category: p.category,
              isPredefinedLandmark: true,
            ))
        .toList();
  }
}

final placeSearchServiceProvider = Provider<PlaceSearchService>((ref) {
  return PlaceSearchService();
});
