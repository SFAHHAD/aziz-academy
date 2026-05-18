import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:latlong2/latlong.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

class RealInteractiveMap extends StatefulWidget {
  const RealInteractiveMap({
    super.key,
    required this.targetLat,
    required this.targetLng,
  });

  final double targetLat;
  final double targetLng;

  @override
  State<RealInteractiveMap> createState() => _RealInteractiveMapState();
}

class _RealInteractiveMapState extends State<RealInteractiveMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  final _tileStore = MemCacheStore();

  // Single controller created once and reused for every map pan/zoom.
  // Tweens are mutable and updated in-place, so no new controller is ever
  // allocated mid-flight — this eliminates the AnimationController leak.
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;
  final _latTween  = Tween<double>(begin: 0, end: 0);
  final _lngTween  = Tween<double>(begin: 0, end: 0);
  final _zoomTween = Tween<double>(begin: 4, end: 4);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    _moveController.addListener(() {
      _mapController.move(
        LatLng(
          _latTween.evaluate(_moveAnimation),
          _lngTween.evaluate(_moveAnimation),
        ),
        _zoomTween.evaluate(_moveAnimation),
      );
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RealInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetLat != widget.targetLat ||
        oldWidget.targetLng != widget.targetLng) {
      _animatedMapMove(LatLng(widget.targetLat, widget.targetLng), 4.0);
    }
  }

  void _animatedMapMove(LatLng dest, double destZoom) {
    // Update tween endpoints from the map's current camera position.
    _latTween
      ..begin = _mapController.camera.center.latitude
      ..end   = dest.latitude;
    _lngTween
      ..begin = _mapController.camera.center.longitude
      ..end   = dest.longitude;
    _zoomTween
      ..begin = _mapController.camera.zoom
      ..end   = destZoom;

    // Interrupt any in-progress animation and start from the updated values.
    _moveController
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Matches Navy dark water
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
             initialCenter: LatLng(widget.targetLat, widget.targetLng),
             initialZoom: 4.0,
             interactionOptions: const InteractionOptions(
               flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
             ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.azizacademy.app',
              tileProvider: CachedTileProvider(
                store: _tileStore,
                maxStale: const Duration(days: 30),
              ),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.targetLat, widget.targetLng),
                  width: 80,
                  height: 80,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
                        child: child,
                      );
                    },
                    child: PinWidget(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PinWidget extends StatelessWidget {
  const PinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha:0.6),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
