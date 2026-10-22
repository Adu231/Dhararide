import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../brand/brand_config.dart';
import '../map/map_config.dart';
import '../theme/app_colors.dart';
import '../../data/models/driver_model.dart';

/// Interactive OpenStreetMap widget tailored for DharRide auto-rickshaw bookings.
///
/// Supports embedded card mode or full-bleed backdrop mode with live user GPS indicator,
/// pickup/destination pins, route polylines, and nearby auto-rickshaws.
class DharashivMapWidget extends StatefulWidget {
  final LatLng pickup;
  final LatLng? destination;
  final LatLng? userLocation;
  final String? pickupLabel;
  final String? destinationLabel;
  final List<DriverModel> nearbyDrivers;
  final List<LatLng>? routePolyline;
  final double? height;
  final bool isFullScreen;
  final bool showControls;
  final BorderRadius? borderRadius;
  final Function(DriverModel)? onDriverSelected;
  final MapController? externalController;
  final double attributionBottomOffset;
  final VoidCallback? onRecenterPressed;

  const DharashivMapWidget({
    super.key,
    required this.pickup,
    this.destination,
    this.userLocation,
    this.pickupLabel,
    this.destinationLabel,
    this.nearbyDrivers = const [],
    this.routePolyline,
    this.height = 240,
    this.isFullScreen = false,
    this.showControls = true,
    this.borderRadius,
    this.onDriverSelected,
    this.externalController,
    this.attributionBottomOffset = 6,
    this.onRecenterPressed,
  });

  @override
  State<DharashivMapWidget> createState() => _DharashivMapWidgetState();
}

class _DharashivMapWidgetState extends State<DharashivMapWidget> {
  late final MapController _internalMapController;

  MapController get _controller => widget.externalController ?? _internalMapController;

  @override
  void initState() {
    super.initState();
    _internalMapController = MapController();
  }

  void _zoomIn() {
    final zoom = _controller.camera.zoom + 1;
    if (zoom <= MapConfig.maxZoom) {
      _controller.move(_controller.camera.center, zoom);
    }
  }

  void _zoomOut() {
    final zoom = _controller.camera.zoom - 1;
    if (zoom >= MapConfig.minZoom) {
      _controller.move(_controller.camera.center, zoom);
    }
  }

  void _recenter() {
    if (widget.onRecenterPressed != null) {
      widget.onRecenterPressed!();
    } else {
      final target = widget.userLocation ?? widget.pickup;
      _controller.move(target, MapConfig.defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // 1. Current User Location Marker (Pulse GPS indicator)
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          point: widget.userLocation!,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.22),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade700,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Pickup Marker (Green)
    markers.add(
      Marker(
        point: widget.pickup,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    );

    // 3. Destination Marker (Red)
    if (widget.destination != null) {
      markers.add(
        Marker(
          point: widget.destination!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 22),
          ),
        ),
      );
    }

    // 4. Nearby Auto-Rickshaw Markers (Yellow brand styling)
    for (final driver in widget.nearbyDrivers) {
      if (driver.currentLatitude != null && driver.currentLongitude != null) {
        markers.add(
          Marker(
            point: LatLng(driver.currentLatitude!, driver.currentLongitude!),
            width: 36,
            height: 36,
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
                  border: Border.all(color: BrandConfig.textPrimaryBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.electric_rickshaw, color: BrandConfig.textPrimaryBlack, size: 18),
              ),
            ),
          ),
        );
      }
    }

    final effectiveRadius = widget.borderRadius ??
        (widget.isFullScreen ? BorderRadius.zero : BorderRadius.circular(16));

    final mapWidget = Stack(
      children: [
        FlutterMap(
          mapController: _controller,
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
                    strokeWidth: 4.5,
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
            right: 14,
            top: widget.isFullScreen ? 90 : 12,
            child: Column(
              children: [
                _buildMapButton(Icons.add, _zoomIn, tooltip: 'Zoom In'),
                const SizedBox(height: 8),
                _buildMapButton(Icons.remove, _zoomOut, tooltip: 'Zoom Out'),
                const SizedBox(height: 8),
                _buildMapButton(Icons.my_location, _recenter, tooltip: 'Recenter'),
              ],
            ),
          ),

        // Mandatory OpenStreetMap Attribution
        Positioned(
          left: 10,
          bottom: widget.attributionBottomOffset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: const Text(
              MapConfig.attribution,
              style: TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );

    if (widget.isFullScreen) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: mapWidget,
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: effectiveRadius,
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
      child: mapWidget,
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onPressed, {required String tooltip}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: BrandConfig.textPrimaryBlack),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}

