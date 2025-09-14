import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/infrastructure/services/nominatim_geocoding_service.dart';

class MapPickerResult {
  final double latitud;
  final double longitud;
  final String? departamento;
  final String? municipio;

  const MapPickerResult({
    required this.latitud,
    required this.longitud,
    this.departamento,
    this.municipio,
  });
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final latlng.LatLng _initial = const latlng.LatLng(12.114993, -86.236174);
  double _zoom = 6.5;
  latlng.LatLng? _selected;
  bool _resolving = false;
  final NominatimGeocodingService _geocoder = NominatimGeocodingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elegir ubicación', style: AppTypography.textTheme.titleLarge),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initial,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                // Habilita gestos: arrastrar, pinchar, doble toque, rueda del ratón, etc.
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                setState(() => _selected = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memoriaviva.app',
                tileProvider: CancellableNetworkTileProvider(),
                tileDisplay: TileDisplay.fadeIn(duration: const Duration(milliseconds: 100)),
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, color: AppColors.primaryDark),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: _selected == null
                  ? null
                  : () async {
                      final lat = _selected!.latitude;
                      final lng = _selected!.longitude;
                      setState(() => _resolving = true);
                      String? dep;
                      String? mun;
                      try {
                        final result = await _geocoder.reverseGeocode(latitude: lat, longitude: lng);
                        dep = result?.departamento;
                        mun = result?.municipio;
                      } catch (_) {}
                      if (!mounted) return;
                      setState(() => _resolving = false);
                      Navigator.of(context).pop(MapPickerResult(
                        latitud: lat,
                        longitud: lng,
                        departamento: dep,
                        municipio: mun,
                      ));
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: _resolving ? const Text('Obteniendo dirección...') : const Text('Usar esta ubicación'),
            ),
          )
          ,
          // Controles de zoom (opcional)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      try {
                        final center = _mapController.camera.center;
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(center, (currentZoom + 1).clamp(3, 19));
                      } catch (_) {
                        _zoom = (_zoom + 1).clamp(3, 19);
                        _mapController.move(_initial, _zoom);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.add, size: 22, color: AppColors.primaryDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      try {
                        final center = _mapController.camera.center;
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(center, (currentZoom - 1).clamp(3, 19));
                      } catch (_) {
                        _zoom = (_zoom - 1).clamp(3, 19);
                        _mapController.move(_initial, _zoom);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.remove, size: 22, color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


