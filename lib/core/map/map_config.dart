import 'package:latlong2/latlong.dart';

/// Configuration and policies for OpenStreetMap and map rendering in DharRide.
///
/// NOTE on OpenStreetMap Tile Usage Policy:
/// OpenStreetMap is a collaborative, volunteer-supported mapping project.
/// Their public tile servers (tile.openstreetmap.org) are provided for low-volume
/// demonstration and personal use.
/// - The policy strictly mandates identifying the application via a descriptive User-Agent
///   (configured here as [userAgentPackageName]).
/// - Heavy scraping, bulk caching, or high-volume commercial production use without permission
///   is prohibited.
/// - For production scaling, consider a dedicated tile hosting provider (such as MapTiler,
///   Stadia Maps, Thunderforest) or self-hosting an OSM tile server using Docker/renderd.
class MapConfig {
  /// OpenStreetMap standard tile server URL template.
  static const String tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Package/Application identifier sent in HTTP headers per OSM Tile Usage Policy.
  static const String userAgentPackageName = 'com.example.dharride.dharride';

  /// Mandatory OpenStreetMap copyright attribution string.
  static const String attribution = '© OpenStreetMap contributors';

  /// Default geographical center of Dharashiv (Osmanabad), Maharashtra.
  static const LatLng dharashivCenter = LatLng(18.1865, 76.0410);

  /// Default interactive zoom level for city-scale navigation.
  static const double defaultZoom = 14.5;

  /// Minimum zoom level (shows broader Marathwada region).
  static const double minZoom = 10.0;

  /// Maximum zoom level (street and landmark detail).
  static const double maxZoom = 19.0;
}
