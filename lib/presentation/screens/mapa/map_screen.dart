import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
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
  String? _hoverRelatoId;
  bool _didProviderInit = false;
  final Set<String> _longPressedMarkers = {}; // Guardar IDs de marcadores presionados

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el foco solicitado desde fuera, pedirlo al provider
    if (widget.focusRelatoId != null && widget.focusRelatoId != oldWidget.focusRelatoId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final p = context.read<MapProvider>();
          p.focusRelatoByIdOrFetch(widget.focusRelatoId!);
        } catch (_) {}
      });
    }
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
      print('DEBUG: Actualizando bounds del mapa: S=${bounds.south}, W=${bounds.west}, N=${bounds.north}, E=${bounds.east}');
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
            print('DEBUG: Error al acceder al provider en _updateBounds: $e');
          }
        });
      }
    } catch (e) {
      print('DEBUG: Error al actualizar bounds: $e');
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
            print('DEBUG: Inicializando MapScreen');
            print('DEBUG: Relatos actuales en provider: ${provider.relatos.length}');
            provider.initialFetchIfNeeded();
            _syncCameraFromProvider(provider);
            final navFocus = context.read<NavigationProvider>().takeMapFocusRelatoId();
            final toFocus = widget.focusRelatoId ?? navFocus;
            if (toFocus != null) {
              print('DEBUG: Solicitando foco en relato ID: $toFocus');
              // Si el relato todavía no está cargado, forzamos fetch puntual
              provider.focusRelatoByIdOrFetch(toFocus);
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
        
        // Debug: Mostrar información del estado del mapa (solo en debug)
        if (kDebugMode) {
          // ignore: avoid_print
          print('DEBUG: Estado del mapa - Relatos: ${provider.relatos.length}, Loading: ${provider.loading}, Error: ${provider.error}');
        }
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
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                      } catch (e) {
                        print('DEBUG: Error al actualizar vista del mapa: $e');
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
                         print('DEBUG: Error al acceder al provider en onMapEvent: $e');
                       }
                     });
                  },
                  onTap: (tapPos, point) {
                    setState(() => _hoverRelatoId = null);
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
                      zoomToBoundsOnClick: true,
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
                    final bool isSmallScreen = constraints.maxWidth < 600;
                    
                    return Stack(
                      children: [
                        // Botones de zoom y navegación (derecha)
                        Positioned(
                          right: 12,
                          top: 120, // Posición fija debajo de los chips en todas las pantallas
                          child: Column(
                            children: [
                              _roundIconButton(
                                icon: Icons.add,
                                tooltip: 'Acercar',
                                onTap: () {
                                  final c = _mapController.camera.center;
                                  final z = (_mapController.camera.zoom + 1).clamp(3.0, 19.0) as double;
                                  _mapController.move(c, z);
                                },
                              ),
                              const SizedBox(height: 8),
                              _roundIconButton(
                                icon: Icons.remove,
                                tooltip: 'Alejar',
                                onTap: () {
                                  final c = _mapController.camera.center;
                                  final z = (_mapController.camera.zoom - 1).clamp(3.0, 19.0) as double;
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
                             print('DEBUG: Error al actualizar vista del mapa en mi ubicación: $e');
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
                          right: 70, // Dejar espacio a la derecha para los botones
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
                                  }).toList(),
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

  // Optimizado para mejor rendimiento
  Marker _buildMarker(BuildContext context, Relato r) {
    final color = _colorForCategoria(r.categoriaNombre);
    // Obtener el MapProvider para verificar si el relato está seleccionado o cerca
    final provider = Provider.of<MapProvider>(context, listen: false);
    final bool isSelected = r.id == provider.focusRelatoId;
    final bool isNearby = _isRelatoNearby(r, provider);
    
    // Estado local para mantener presionado
    final String markerKey = "marker_${r.id}";
    final bool isLongPressed = _longPressedMarkers.contains(markerKey);
    
    // Aumentar tamaño base del marcador para mejor visibilidad y tap
    final size = _markerSize(_mapController.camera.zoom) * 1.2;
    
    return Marker(
      point: latlng.LatLng(r.ubicacion!.latitud, r.ubicacion!.longitud),
      width: size * 2.5, // Área más grande para facilitar el tap
      height: size * 2.5,
      child: Stack(
        children: [
          // Marcador principal con tap y longPress
          Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                print('DEBUG: Tap en marcador detectado para relato ${r.id}');
                RelatoDetailOverlay.open(context, r);
              },
              onLongPressStart: (_) {
                setState(() {
                  _longPressedMarkers.add(markerKey);
                });
              },
              onLongPressEnd: (_) {
                setState(() {
                  _longPressedMarkers.remove(markerKey);
                });
              },
              onLongPressCancel: () {
                setState(() {
                  _longPressedMarkers.remove(markerKey);
                });
              },
              child: Container(
                alignment: Alignment.center,
                child: _buildMarkerContent(color, size, isSelected, r),
              ),
            ),
          ),
          
          // Tooltip condicional (mostrar si está seleccionado, cercano, o mantenido presionado)
          if (isSelected || isNearby || isLongPressed)
            _buildTooltipLabel(r.titulo ?? 'Sin título', isSelected)
        ],
      ),
    );
  }
  
   // Método separado para reducir reconstrucciones innecesarias
   Widget _buildMarkerContent(Color color, double size, bool isSelected, Relato r) {
     return _pinIcon(color, size, isSelected);
   }
   
  // Widget para mostrar el título sobre el marcador sin interferir con el tap
  Widget _buildTooltipLabel(String title, bool isSelected) {
    return Positioned(
      // Posicionamiento mejorado para evitar recortes
      bottom: 40,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                CustomPaint(
                  size: const Size(14, 7),
                  painter: _TrianglePainter(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimización: Simplificar icono de pin para mejor rendimiento
  Widget _pinIcon(Color color, double size, bool isSelected) {
    // En dispositivos móviles o con zoom bajo, usar un icono más simple
    final bool useSimpleIcon = !kIsWeb || _mapController.camera.zoom < 10;
    
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

  // Tooltip optimizado para mejor rendimiento
  Widget _hoverTooltip(Relato r) {
    return Positioned(
      left: 24,
      bottom: 24,
      child: Material(
        color: AppColors.surface,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optimizado: solo mostrar imagen si está en zoom alto para mejor rendimiento
                if (_mapController.camera.zoom > 12)
                  if (r.multimedia.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: r.multimedia.first.url,
                        width: 40, // Reducido para mejor rendimiento
                        height: 40,
                        fit: BoxFit.cover,
                        // Optimizaciones para imágenes
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        fadeInDuration: const Duration(milliseconds: 100),
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceVariant,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 40, // Reducido para mejor rendimiento
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.image_outlined, size: 18),
                    ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    r.titulo,
                    maxLines: 1, // Reducido para mejor rendimiento
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForCategoria(String nombre) {
    final key = nombre.toLowerCase();
    if (key.contains('gastr') || key.contains('comida')) return AppColors.tierra;
    if (key.contains('artes')) return AppColors.ceramica;
    if (key.contains('música') || key.contains('musica')) return AppColors.musicaColor;
    if (key.contains('trad')) return AppColors.jade;
    if (key.contains('hist')) return AppColors.cacao;
    return AppColors.primary;
  }
  
  // Verificar si un relato está cerca del usuario
  bool _isRelatoNearby(Relato relato, MapProvider mapProvider) {
    // Si no hay ubicación del usuario o el relato no tiene ubicación, no es cercano
    if (mapProvider.userLocation == null || 
        relato.ubicacion == null || 
        relato.ubicacion?.latitud == null || 
        relato.ubicacion?.longitud == null) {
      return false;
    }
    
    // Calcular distancia aproximada usando la fórmula del haversine
    final double lat1 = mapProvider.userLocation!.latitude;
    final double lon1 = mapProvider.userLocation!.longitude;
    final double lat2 = relato.ubicacion!.latitud!;
    final double lon2 = relato.ubicacion!.longitud!;
    
    const int radioTierra = 6371; // Radio de la Tierra en km
    final double latDistance = _toRadians(lat2 - lat1);
    final double lonDistance = _toRadians(lon2 - lon1);
    
    final double a = sin(latDistance / 2) * sin(latDistance / 2) +
               cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
               sin(lonDistance / 2) * sin(lonDistance / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distancia = radioTierra * c;
    
    // Mostrar tooltip si está a menos de 1km
    return distancia < 1.0;
  }
  
  double _toRadians(double grados) {
    return grados * pi / 180;
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


