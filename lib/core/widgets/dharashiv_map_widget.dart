import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../brand/brand_config.dart';
import '../map/map_config.dart';
import '../theme/app_colors.dart';
import '../../data/models/driver_model.dart';

/// Interactive OpenStreetMap widget tailored for DharRide auto-rickshaw bookings.
class DharashivMapWidget extends StatefulWidget {
  final LatLng pickup;
  final LatLng? destination;
  final String? pickupLabel;
  final String? destinationLabel;
  final List<DriverModel> nearbyDrivers;
  final List<LatLng>? routePolyline;
  final double height;
  final bool showControls;
  final Function(DriverModel)? onDriverSelected;

  const DharashivMapWidget({
    super.key,
    required this.pickup,
    this.destination,
    this.pickupLabel,
    this.destinationLabel,
    this.nearbyDrivers = const [],
    this.routePolyline,
    this.height = 240,
    this.showControls = true,
    this.onDriverSelected,
  });

  @override
  State<DharashivMapWidget> createState() => _DharashivMapWidgetState();
}

class _DharashivMapWidgetState extends State<DharashivMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    if (zoom <= MapConfig.maxZoom) {
      _mapController.move(_mapController.camera.center, zoom);
    }
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1;
    if (zoom >= MapConfig.minZoom) {
      _mapController.move(_mapController.camera.center, zoom);
    }
  }

  void _recenter() {
    _mapController.move(widget.pickup, MapConfig.defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // 1. Pickup Marker (Green)
    markers.add(
      Marker(
        point: widget.pickup,
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 18),
        ),
      ),
    );

    // 2. Destination Marker (Red)
    if (widget.destination != null) {
      markers.add(
        Marker(
          point: widget.destination!,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // 3. Nearby Auto-Rickshaw Markers (Yellow brand styling)
    for (final driver in widget.nearbyDrivers) {
      if (driver.currentLatitude != null && driver.currentLongitude != null) {
        markers.add(
          Marker(
            point: LatLng(driver.currentLatitude!, driver.currentLongitude!),
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () {
                if (widget.onDriverSelected != null) {
                  widget.onDriverSelected!(driver);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: BrandConfig.accentYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandConfig.textPrimaryBlack, width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.electric_rickshaw, color: BrandConfig.textPrimaryBlack, size: 16),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.pickup,
              initialZoom: MapConfig.defaultZoom,
              minZoom: MapConfig.minZoom,
              maxZoom: MapConfig.maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap Tile Layer with required User-Agent
              TileLayer(
                urlTemplate: MapConfig.tileUrlTemplate,
                userAgentPackageName: MapConfig.userAgentPackageName,
                tileBuilder: (context, tileWidget, tile) {
                  return tileWidget;
                },
                errorTileCallback: (tile, error, stackTrace) {
                  // Network tile loading failure handled gracefully
                },
              ),

              // Route Polyline Layer
              if (widget.routePolyline != null && widget.routePolyline!.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePolyline!,
                      strokeWidth: 4.0,
                      color: BrandConfig.textPrimaryBlack,
                      borderColor: BrandConfig.accentYellow,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Marker Layer
              MarkerLayer(markers: markers),
            ],
          ),

          // Zoom & Recenter Controls
          if (widget.showControls)
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _buildMapButton(Icons.add, _zoomIn, tooltip: 'Zoom In'),
                  const SizedBox(height: 6),
                  _buildMapButton(Icons.remove, _zoomOut, tooltip: 'Zoom Out'),
                  const SizedBox(height: 6),
                  _buildMapButton(Icons.my_location, _recenter, tooltip: 'Recenter'),
                ],
              ),
            ),

          // Mandatory OpenStreetMap Attribution
          Positioned(
            left: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                MapConfig.attribution,
                style: TextStyle(fontSize: 9, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onPressed, {required String tooltip}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: BrandConfig.textPrimaryBlack),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}
