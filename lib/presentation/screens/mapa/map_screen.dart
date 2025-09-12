import 'dart:math';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' as latlng;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;

import '../../../core/theme/app_colors.dart';
import '../../providers/map_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/relatos/relato_detail_overlay.dart';
import '../../../domain/entities/relato.dart';

class MapScreen extends StatefulWidget {
  final String? focusRelatoId;
  const MapScreen({super.key, this.focusRelatoId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// Implementación simple de TickerProvider para animaciones
class _TickerProviderImpl extends TickerProvider {
  const _TickerProviderImpl();
  
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick, debugLabel: 'MapAnimationTicker');
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  latlng.LatLng _center = const latlng.LatLng(12.114993, -86.236174);
  double _zoom = 6.5;
  bool _didProviderInit = false;
  bool _showRelatosList = false; // Controla la visibilidad de la lista lateral
  // Eliminando state para simplificar
  // final Set<String> _pressedMarkers = {}; // IDs de marcadores mientras están presionados (tooltip)
  // final Map<String, Timer> _pressTimers = {}; // Temporizadores por marcador para long press (tooltip)
  // final Set<String> _longPressFired = {}; // Marcadores cuyo long-press (1.5s) ya se disparó (tooltip)

  @override
  void initState() {
    super.initState();
    // En la próxima frame, ajustar visibilidad de lista según tamaño de pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        if (mounted) {
          setState(() {
            _showRelatosList = size.width >= 900; // Mostrar lista solo en pantallas grandes
          });
        }
      }
    });
  }

  // Eliminado método dispose

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el foco solicitado desde fuera, pedirlo al provider
    if (widget.focusRelatoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final p = context.read<MapProvider>();
          p.focusRelatoByIdOrFetch(widget.focusRelatoId!);
        } catch (_) {}
      });
    }

    // Consumir foco por ubicación si llega mientras el widget ya está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final nav = context.read<NavigationProvider>();
        final loc = nav.takeMapFocusLocation();
        if (loc != null) {
          final vp = MediaQuery.of(context).size;
          final destZoom = _zoomForRadiusKm(latitude: loc.lat, radiusKm: loc.radiusKm, viewportSize: vp);
          _animatedMapMove(latlng.LatLng(loc.lat, loc.lng), destZoom);
          final p = context.read<MapProvider>();
          p.setMapView(lat: loc.lat, lng: loc.lng, newZoom: destZoom);
          Future.delayed(const Duration(milliseconds: 550), () { _updateBounds(p); });
          
          // Si hay navegación desde feed, mostrar lista lateral
          if (widget.focusRelatoId != null && mounted) {
            setState(() {
              _showRelatosList = true;
            });
          }
        }
      } catch (_) {}
    });
  }

  Widget _roundIconButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Tooltip(message: tooltip, child: Icon(icon, size: 22, color: AppColors.primaryDark)),
        ),
      ),
    );
  }

  // Método para verificar si un relato está en los límites visibles del mapa
  bool _isRelatoInBounds(Relato relato, latlng.LatLngBounds bounds) {
    if (relato.ubicacion?.latitud == null || relato.ubicacion?.longitud == null) {
      return false;
    }
    
    final lat = relato.ubicacion!.latitud;
    final lng = relato.ubicacion!.longitud;
    
    return lat >= bounds.south && 
           lat <= bounds.north && 
           lng >= bounds.west && 
           lng <= bounds.east;
  }

  // Widget para la lista lateral de relatos
  Widget _buildRelatosList(MapProvider provider, BoxConstraints constraints) {
    final bool isSmallScreen = constraints.maxWidth < 900;
    final double listWidth = isSmallScreen ? constraints.maxWidth * 0.85 : 320;
    
    // Filtrar relatos visibles en el mapa actual
    List<Relato> visibleRelatos = [];
    try {
      // Verificar que el controlador esté montado antes de acceder a la cámara
      if (_mapController.camera != null) {
        final bounds = _mapController.camera.visibleBounds;
        visibleRelatos = provider.relatos.where((r) => 
          r.ubicacion != null && _isRelatoInBounds(r, bounds)
        ).toList();
      } else {
        // Si el mapa no está listo, mostrar todos los relatos con ubicación
        visibleRelatos = provider.relatos.where((r) => r.ubicacion != null).toList();
      }
    } catch (e) {
      // Si hay error obteniendo bounds, mostrar todos los relatos
      visibleRelatos = provider.relatos.where((r) => r.ubicacion != null).toList();
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: (_showRelatosList == true) ? 12 : -listWidth - 12,
      top: 120,
      bottom: 12,
      width: listWidth,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Column(
          children: [
            // Header de la lista
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Relatos (${visibleRelatos.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _showRelatosList = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Lista de relatos
            Expanded(
              child: visibleRelatos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text(
                            'No hay relatos en esta área',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mueve el mapa para explorar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: visibleRelatos.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final relato = visibleRelatos[index];
                      final isSelected = relato.id == provider.focusRelatoId;
                      final categoryColor = AppColors.categoryColor(categoryId: relato.categoriaId);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            relato.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (relato.ubicacion != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: categoryColor),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          relato.ubicacion!.obtenerDireccionFormateada(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        relato.autorNombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          value: relato.id,
                          groupValue: provider.focusRelatoId,
                          activeColor: AppColors.primary,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          onChanged: (value) {
                            if (value != null) {
                              // Focalizar en el provider
                              provider.requestFocusOnRelato(value);
                              
                              // Centrar mapa en el relato
                              final lat = relato.ubicacion!.latitud;
                              final lng = relato.ubicacion!.longitud;
                              _animatedMapMove(latlng.LatLng(lat, lng), 15.0);
                              
                              // Abrir overlay con el relato
                              Future.delayed(const Duration(milliseconds: 400), () {
                                if (mounted) {
                                  _openRelatoOverlay(context, relato);
                                }
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón flotante para mostrar/ocultar la lista en pantallas pequeñas
  Widget _buildToggleListButton(bool isSmallScreen) {
    if (!isSmallScreen) return const SizedBox.shrink();
    
    return Positioned(
      right: 12,
      top: 60,
      child: _roundIconButton(
        icon: (_showRelatosList == true) ? Icons.list_alt : Icons.list_alt_outlined,
        tooltip: (_showRelatosList == true) ? 'Ocultar lista' : 'Mostrar lista de relatos',
        onTap: () => setState(() => _showRelatosList = !(_showRelatosList == true)),
      ),
    );
  }

  void _syncCameraFromProvider(MapProvider p) {
    _center = latlng.LatLng(p.centerLat, p.centerLng);
    _zoom = p.zoom;
    // Mover la cámara solo cuando el mapa esté montado (post-frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(_center, _zoom);
      } catch (_) {}
    });
  }

  double _zoomForRadiusKm({required double latitude, required double radiusKm, required Size viewportSize}) {
    // Queremos que el diámetro (2 * radio) ocupe ~60% del menor lado de la vista
    final double targetPixels = (viewportSize.shortestSide * 0.60).clamp(200.0, 1400.0);
    final double diameterMeters = radiusKm * 2 * 1000.0;
    final double metersPerPixelWanted = diameterMeters / targetPixels;
    final double latRad = latitude * pi / 180.0;
    final double metersPerPixelAtZoom0 = 156543.03392 * cos(latRad);
    double z = log(metersPerPixelAtZoom0 / metersPerPixelWanted) / log(2);
    // Limitar a los rangos del mapa
    z = z.clamp(3.0, 19.0);
    return z;
  }

  void _moveCameraToFocusIfRequested(MapProvider p) {
    if (!p.cameraMoveRequested) return;
    p.cameraMoveRequested = false; // consumir solicitud
    final Size vp = MediaQuery.of(context).size;
    final lat = p.centerLat;
    final lng = p.centerLng;
    // Calcular zoom para ~5 km de radio
    final destZoom = _zoomForRadiusKm(latitude: lat, radiusKm: 5, viewportSize: vp);
    // Moviendo cámara por foco
    // Actualizar estado local y provider para mantener consistencia
    _animatedMapMove(latlng.LatLng(lat, lng), destZoom);
    try {
      p.setMapView(lat: lat, lng: lng, newZoom: destZoom);
    } catch (_) {}
    // Actualizar bounds luego de la animación
    Future.delayed(const Duration(milliseconds: 550), () {
      _updateBounds(p);
    });
  }
  
  void _updateBounds([MapProvider? provider]) {
    try {
      final bounds = _mapController.camera.visibleBounds;
      // Actualizar bounds del mapa
      // Aplicamos un ligero padding a los límites para asegurar que vemos suficientes relatos
      final padding = 0.05;
      
      if (provider != null) {
        provider.setBounds(
          s: bounds.south - padding, 
          w: bounds.west - padding, 
          n: bounds.north + padding, 
          e: bounds.east + padding,
        );
      } else {
        // Usar un callback para asegurar que el provider esté disponible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final p = context.read<MapProvider>();
            p.setBounds(
              s: bounds.south - padding, 
              w: bounds.west - padding, 
              n: bounds.north + padding, 
              e: bounds.east + padding,
            );
          } catch (e) {
            // Error al acceder al provider en _updateBounds
          }
        });
      }
    } catch (e) {
      // Error al actualizar bounds
    }
  }

  double _markerSize(double zoom) {
    final z = zoom.clamp(3.0, 19.0);
    final size = 28 + (z - 6.5) * 2.2; // base 28, crece con el zoom
    return size.clamp(24, 56);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MapProvider>(
      create: (_) => MapProvider(),
      builder: (context, _) {
        final provider = context.watch<MapProvider>();
            if (!_didProviderInit) {
          _didProviderInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.initialFetchIfNeeded();
            _syncCameraFromProvider(provider);
            final nav = context.read<NavigationProvider>();
            final navFocus = nav.takeMapFocusRelatoId();
            final toFocus = widget.focusRelatoId ?? navFocus;
            if (toFocus != null) {
              provider.focusRelatoByIdOrFetch(toFocus);
            }
            // Consumir foco por ubicación si viene definido (prioriza centrado inmediato por lat/lng)
            final loc = nav.takeMapFocusLocation();
            if (loc != null) {
              final vp = MediaQuery.of(context).size;
              final destZoom = _zoomForRadiusKm(latitude: loc.lat, radiusKm: loc.radiusKm, viewportSize: vp);
              _animatedMapMove(latlng.LatLng(loc.lat, loc.lng), destZoom);
              try {
                provider.setMapView(lat: loc.lat, lng: loc.lng, newZoom: destZoom);
              } catch (_) {}
              Future.delayed(const Duration(milliseconds: 550), () {
                _updateBounds(provider);
              });
              
              // Si viene navegación desde feed, mostrar lista lateral automáticamente
              if (toFocus != null && mounted) {
                setState(() {
                  _showRelatosList = true; // Mostrar lista para ver el relato seleccionado
                });
              }
            }
            // Post-frame para acceder a camera de forma segura
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Actualizar bounds de forma segura
              _updateBounds(provider);
              // Si hay solicitud de mover cámara por foco, hacerlo ya
              try {
                if (provider.cameraMoveRequested) {
                  _moveCameraToFocusIfRequested(provider);
                }
              } catch (_) {}
            });
          });
        }

        // En cada build, si hay una solicitud pendiente de mover cámara por foco, ejecutarla
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _moveCameraToFocusIfRequested(provider);
          } catch (_) {}
        });
        
        // Información del estado del mapa omitida en producción
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _zoom,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate & ~InteractiveFlag.doubleTapZoom,
                  ),
                  onMapEvent: (e) {
                    if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd || e is MapEventRotateEnd || e is MapEventDoubleTapZoomEnd) {
                      try {
                        final p = context.read<MapProvider>();
                        _updateBounds(p); // Pasar el provider directamente
                        p.setMapView(
                              lat: _mapController.camera.center.latitude,
                              lng: _mapController.camera.center.longitude,
                              newZoom: _mapController.camera.zoom,
                            );
                        // Si el usuario movió manualmente el mapa, despejar foco para evitar re-centrado continuo
                        p.clearFocus();
                      } catch (e) {
                        // Error al actualizar vista del mapa
                      }
                      // Actualizar zoom local de forma segura
                      final newZoom = _mapController.camera.zoom;
                      if (newZoom != _zoom) {
                        setState(() => _zoom = newZoom);
                      }
                    }
                        // Si el provider solicitó mover cámara por foco, ejecutar
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       try {
                         final p = context.read<MapProvider>();
                         _moveCameraToFocusIfRequested(p);
                       } catch (e) {
                         // Error al acceder al provider en onMapEvent
                       }
                     });
                  },
                  onTap: (tapPos, point) {
                    // Limpiar selección si se toca el mapa
                    final provider = context.read<MapProvider>();
                    provider.clearFocus();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.memoriaviva.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  // Optimización: Limitar número de marcadores renderizados simultáneamente
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 70,
                      size: const Size(36, 36),
                      // Limitar marcadores renderizados según zoom SIN acceder al controller durante build
                      markers: () {
                        final rels = provider.relatos.where((r) => r.ubicacion != null);
                        final z = _zoom;
                        final cap = z < 8 ? 80 : (z < 12 ? 140 : 240);
                        return rels.take(cap).map((r) => _buildMarker(context, r)).toList();
                      }(),
                      disableClusteringAtZoom: 15,
                      zoomToBoundsOnClick: false,
                      builder: (context, markers) {
                        final count = markers.length;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                      computeSize: (markers) => const Size(36, 36),
                    ),
                  ),
                ],
              ),

              // Contenedor para controles responsive
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isSmallScreen = constraints.maxWidth < 900;
                    
                    return Stack(
                      children: [
                        // Lista lateral de relatos
                        _buildRelatosList(provider, constraints),
                        
                        // Botón para mostrar/ocultar lista en pantallas pequeñas
                        _buildToggleListButton(isSmallScreen),
                        
                        // Botones de zoom y navegación (derecha)
                        Positioned(
                          right: (_showRelatosList == true && !isSmallScreen) ? 344 : 12, // Ajustar posición según lista
                          top: 120, // Posición fija debajo de los chips en todas las pantallas
                          child: Column(
                            children: [
                              _roundIconButton(
                                icon: Icons.add,
                                tooltip: 'Acercar',
                                onTap: () {
                                  final c = _mapController.camera.center;
                                  final z = (_mapController.camera.zoom + 1).clamp(3.0, 19.0);
                                  _mapController.move(c, z);
                                },
                              ),
                              const SizedBox(height: 8),
                              _roundIconButton(
                                icon: Icons.remove,
                                tooltip: 'Alejar',
                                onTap: () {
                                  final c = _mapController.camera.center;
                                  final z = (_mapController.camera.zoom - 1).clamp(3.0, 19.0);
                                  _mapController.move(c, z);
                                },
                              ),
                              const SizedBox(height: 8),
                               _roundIconButton(
                                 icon: Icons.my_location,
                                 tooltip: 'Mi ubicación',
                                 onTap: () async {
                         try {
                           // Mostrar indicador de carga
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Obteniendo tu ubicación...'), duration: Duration(seconds: 2))
                           );
                           
                           // Asegurar permisos
                           final hasPermission = await _ensureLocationPermission(context);
                           if (!hasPermission) return;
                           
                           // Estrategia de ubicación mejorada
                           Position pos;
                           
                           // 1. Intentar con alta precisión primero
                           try {
                             pos = await Geolocator.getCurrentPosition(
                               desiredAccuracy: LocationAccuracy.best,
                               timeLimit: const Duration(seconds: 8),
                             );
                           } catch (e1) {
                             // 2. Si falla, intentar con precisión media
                             try {
                               pos = await Geolocator.getCurrentPosition(
                                 desiredAccuracy: LocationAccuracy.medium,
                                 timeLimit: const Duration(seconds: 5),
                               );
                             } catch (e2) {
                               // 3. Último recurso: obtener la última posición conocida
                               try {
                                 final lastPos = await Geolocator.getLastKnownPosition();
                                 if (lastPos != null) {
                                   pos = lastPos;
                                   if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Usando última ubicación conocida'))
                                     );
                                   }
                                 } else {
                                   throw Exception('No se pudo obtener la ubicación');
                                 }
                               } catch (e3) {
                                 throw Exception('No se pudo obtener la ubicación');
                               }
                             }
                           }
                           
                           // Verificar si la ubicación es válida
                           if (pos.latitude == 0 && pos.longitude == 0) {
                             throw Exception('Ubicación no válida');
                           }
                           
                           // Centrar mapa en la ubicación
                           final here = latlng.LatLng(pos.latitude, pos.longitude);
                           _mapController.move(here, 15);
                           
                           // Actualizar provider
                           try {
                             final p = context.read<MapProvider>();
                             // Guardar la ubicación del usuario en el provider
                             p.userLocation = pos;
                             p.setMapView(
                                   lat: here.latitude,
                                   lng: here.longitude,
                                   newZoom: 15,
                                 );
                             _updateBounds(p);
                             
                             // Mostrar confirmación
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Ubicación obtenida correctamente'))
                               );
                             }
                           } catch (e) {
                             // Error al actualizar vista del mapa en mi ubicación
                           }
                         } catch (e) {
                           if (!mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo obtener ubicación: $e')));
                         }
                                },
                              ),
                              const SizedBox(height: 8),
                              _roundIconButton(
                                icon: Icons.public,
                                tooltip: 'Recentrar Nicaragua',
                                onTap: () {
                                  final nicaragua = const latlng.LatLng(12.114993, -86.236174);
                                  _mapController.move(nicaragua, 6.5);
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Toggle cercanos (izquierda arriba)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_outlined, size: 18, color: AppColors.primaryDark),
                                const SizedBox(width: 6),
                                const Text('Solo cercanos'),
                                const SizedBox(width: 6),
                                Switch(
                                  value: provider.nearbyOnly,
                                  onChanged: (v) => provider.toggleNearbyOnly(v),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Filtros por categoría (barra superior)
                        Positioned(
                          left: 12,
                          right: (_showRelatosList == true && !isSmallScreen) ? 376 : 70, // Ajustar según lista lateral
                          top: 64,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: const Text('Todos'),
                                      selected: provider.selectedCategoriaIds.isEmpty,
                                      onSelected: (_) {
                                        if (provider.selectedCategoriaIds.isNotEmpty) {
                                          provider.selectedCategoriaIds.clear();
                                          provider.toggleNearbyOnly(provider.nearbyOnly); // retrigger fetch
                                        }
                                      },
                                    ),
                                  ),
                                  ...provider.categorias.map((c) {
                                    final selected = provider.selectedCategoriaIds.contains(c.id);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        label: Text(c.nombre),
                                        selected: selected,
                                        selectedColor: AppColors.accent,
                                        onSelected: (_) => provider.toggleCategoria(c.id),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Estado offline
              if (provider.offline)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0,2))],
                    ),
                    child: const Text('Offline (vista en caché)'),
                  ),
                ),

              // Loading
              if (provider.loading)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Marcador simplificado ya que la interacción principal es via lista lateral
  Marker _buildMarker(BuildContext context, Relato r) {
    final color = AppColors.categoryColor(categoryId: r.categoriaId);
    // Obtener el MapProvider para verificar si el relato está seleccionado
    final provider = Provider.of<MapProvider>(context, listen: false);
    final bool isSelected = r.id == provider.focusRelatoId;
    
    // Tamaño base del marcador sin amplificación excesiva
    final size = _markerSize(_zoom);
    
    return Marker(
      point: latlng.LatLng(r.ubicacion!.latitud, r.ubicacion!.longitud),
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Focalizar en el provider y abrir overlay
          provider.requestFocusOnRelato(r.id);
          _openRelatoOverlay(context, r);
        },
        child: _buildMarkerContent(color, size, isSelected, r),
      ),
    );
  }
  
  // Eliminado método duplicado
  
  // Método para abrir el overlay de forma confiable
  void _openRelatoOverlay(BuildContext context, Relato r) {
    // Usar el método original pero con try-catch para evitar errores
    try {
      RelatoDetailOverlay.open(context, r);
    } catch (e) {
      print('ERROR al abrir overlay: $e');
      
      // Intento alternativo directo
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        
        try {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            enableDrag: true,
            isDismissible: true,
            barrierColor: Colors.black54,
            backgroundColor: Colors.transparent,
            builder: (ctx) {
              return Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(r.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const Divider(),
                      Expanded(child: SingleChildScrollView(child: Text(r.contenido))),
                    ],
                  ),
                ),
              );
            },
          );
        } catch (e2) {
          print('ERROR en intento alternativo: $e2');
        }
      });
    }
  }

  // Eliminado método _openOverlayOnce
  
   // Método separado para reducir reconstrucciones innecesarias
   Widget _buildMarkerContent(Color color, double size, bool isSelected, Relato r) {
     return _pinIcon(color, size, isSelected);
   }
   

  // Optimización: Simplificar icono de pin para mejor rendimiento
  Widget _pinIcon(Color color, double size, bool isSelected) {
    // En dispositivos móviles o con zoom bajo, usar un icono más simple
    final bool useSimpleIcon = !kIsWeb || _zoom < 10;
    
    if (useSimpleIcon) {
      return Container(
        width: size * 0.8,
        height: size * 0.8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ] : [],
        ),
      );
    }
    
    // Versión completa para web o zoom alto
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.location_on, size: size + 6, color: Colors.white),
        Icon(Icons.location_on, size: size, color: color),
        if (isSelected)
          Icon(Icons.location_on, size: size + 10, color: Colors.white.withOpacity(0.3)),
      ],
    );
  }


  

   // Implementación personalizada de animación de movimiento del mapa
   void _animatedMapMove(latlng.LatLng destLocation, double destZoom) {
     // Obtener posición y zoom actuales
     final latTween = Tween<double>(
       begin: _mapController.camera.center.latitude,
       end: destLocation.latitude,
     );
     final lngTween = Tween<double>(
       begin: _mapController.camera.center.longitude,
       end: destLocation.longitude,
     );
     final zoomTween = Tween<double>(
       begin: _mapController.camera.zoom,
       end: destZoom,
     );

     // Crear un controlador de animación
     final controller = AnimationController(
       duration: const Duration(milliseconds: 500),
       vsync: const _TickerProviderImpl(),
     );

     // Añadir listener para actualizar el mapa en cada frame
     controller.addListener(() {
       final lat = latTween.evaluate(controller);
       final lng = lngTween.evaluate(controller);
       final zoom = zoomTween.evaluate(controller);
       
       _mapController.move(latlng.LatLng(lat, lng), zoom);
     });

     // Iniciar la animación
     controller.forward().then((value) => controller.dispose());
   }
   
   Future<bool> _ensureLocationPermission(BuildContext context) async {
     // 1. Verificar si el servicio de ubicación está habilitado
     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     if (!serviceEnabled) {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('El servicio de ubicación está desactivado. Por favor, actívalo.'))
         );
       }
       
       // En web, mostrar instrucciones específicas
       if (kIsWeb && context.mounted) {
         showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text('Activar ubicación'),
             content: const Text(
               'Para usar tu ubicación en web:\n'
               '1. Asegura que tu navegador tenga permisos de ubicación\n'
               '2. Verifica que el sitio use HTTPS\n'
               '3. Permite el acceso cuando el navegador lo solicite'
             ),
             actions: [
               TextButton(
                 onPressed: () => Navigator.pop(ctx),
                 child: const Text('Entendido'),
               ),
             ],
           ),
         );
       } else {
         // En dispositivos móviles, abrir configuración
         await Geolocator.openLocationSettings();
       }
       return false;
     }
     
     // 2. Verificar permisos de ubicación
     LocationPermission permission = await Geolocator.checkPermission();
     if (permission == LocationPermission.denied) {
       // Solicitar permiso
       permission = await Geolocator.requestPermission();
       if (permission == LocationPermission.denied) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Permiso de ubicación denegado. No podemos obtener tu ubicación.'))
           );
         }
         return false;
       }
     }
     
     // 3. Manejar el caso de permiso denegado permanentemente
     if (permission == LocationPermission.deniedForever) {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Permiso de ubicación denegado permanentemente. Cambia los permisos en la configuración.'),
             duration: Duration(seconds: 5),
           )
         );
       }
       return false;
     }
     
     return true;
   }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 2, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


