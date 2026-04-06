import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

class _RealInteractiveMapState extends State<RealInteractiveMap> with TickerProviderStateMixin {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(RealInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetLat != widget.targetLat || oldWidget.targetLng != widget.targetLng) {
      _animatedMapMove(LatLng(widget.targetLat, widget.targetLng), 4.0);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
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
              // Using Google Maps Satellite Hybrid with Arabic labels
              urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.azizacademy.app',
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
