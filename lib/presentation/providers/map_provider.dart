import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/relato.dart';
import '../../domain/repositories/relato_repository.dart';
import '../../domain/factories/usecases.dart';
import '../../domain/services/i_connectivity_service.dart';
import '../../domain/services/i_cache_service.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../domain/enums/tipos_contenido.dart';

class MapProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve();
  final GetIt _getIt = GetIt.I;

  // Estado del mapa
  double centerLat = 12.114993; // Managua por defecto
  double centerLng = -86.236174;
  double zoom = 6.5;
  
  // Ubicación del usuario (para mostrar relatos cercanos)
  Position? userLocation;

  // Bounds visibles (south, west, north, east)
  double? south;
  double? west;
  double? north;
  double? east;

  // Datos
  List<Relato> relatos = [];
  bool loading = false;
  String? error;

  // Estado de conectividad
  bool offline = false;
  StreamSubscription? _connSub;

  // Filtros
  bool nearbyOnly = false;
  double radioKm = 25;

  // Debounce para fetch al mover/zoom
  Timer? _debounce;

  // Foco de relato (para centrar y resaltar)
  String? focusRelatoId;
  // Variable para indicar si se solicitó mover la cámara
  bool cameraMoveRequested = false;

  // Categorías (filtros)
  List<Categoria> categorias = [];
  bool categoriasLoading = false;
  String? categoriasError;
  final Set<String> selectedCategoriaIds = {};

  MapProvider() {
    _initConnectivity();
    _loadCategorias();
  }

  void dispose() {
    _debounce?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  void _initConnectivity() {
    if (_getIt.isRegistered<IConnectivityService>()) {
      final conn = _getIt<IConnectivityService>();
      offline = !conn.current.online;
      _connSub = conn.changes.listen((state) {
        offline = !state.online;
        notifyListeners();
      });
    }
  }

  void setMapView({required double lat, required double lng, required double newZoom}) {
    // Evitar notificaciones si el cambio es mínimo para no reconstruir innecesariamente
    final bool smallLatChange = (lat - centerLat).abs() < 0.0005;
    final bool smallLngChange = (lng - centerLng).abs() < 0.0005;
    final bool smallZoomChange = (newZoom - zoom).abs() < 0.1;
    if (smallLatChange && smallLngChange && smallZoomChange) {
      return;
    }
    centerLat = lat;
    centerLng = lng;
    zoom = newZoom;
    notifyListeners();
  }

  void setBounds({required double s, required double w, required double n, required double e}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: MapProvider.setBounds - S=$s, W=$w, N=$n, E=$e');
    }
    // Umbral para evitar fetch por cambios muy pequeños
    const double epsilon = 0.025; // ~2.7km latitud
    if (south != null &&
        (s - south!).abs() < epsilon &&
        (w - west!).abs() < epsilon &&
        (n - north!).abs() < epsilon &&
        (e - east!).abs() < epsilon) {
      return;
    }
    south = s;
    west = w;
    north = n;
    east = e;
    _debouncedFetch();
  }

  void toggleNearbyOnly(bool value) {
    nearbyOnly = value;
    _debouncedFetch(force: true);
    notifyListeners();
  }

  void setRadioKm(double km) {
    radioKm = km.clamp(1, 200);
    if (nearbyOnly) _debouncedFetch(force: true);
    notifyListeners();
  }

  void requestFocusOnRelato(String relatoId) {
    print('DEBUG: MapProvider.requestFocusOnRelato: $relatoId');
    focusRelatoId = relatoId;
    // Intentaremos centrar cuando tengamos datos.
    // Si ya están cargados, centramos de inmediato.
    _centerIfPossible();
  }

  /// Fuerza centrado en un relato por ID, buscándolo si no está en memoria
  Future<void> focusRelatoByIdOrFetch(String relatoId) async {
    print('DEBUG: MapProvider.focusRelatoByIdOrFetch($relatoId)');
    focusRelatoId = relatoId;
    _centerIfPossible();
    if (cameraMoveRequested) {
      print('DEBUG: Ya se solicitó mover la cámara, no es necesario buscar el relato');
      return; // ya se centró
    }
    
    try {
      if (_getIt.isRegistered<IRelatoRepository>()) {
        final repo = _getIt<IRelatoRepository>();
        print('DEBUG: Buscando relato por ID: $relatoId');
        final r = await repo.obtenerRelatoPorId(relatoId);
        
        if (r != null) {
          print('DEBUG: Relato encontrado: ${r.titulo}');
          
          if (r.ubicacion != null) {
            print('DEBUG: Ubicación encontrada: (${r.ubicacion!.latitud}, ${r.ubicacion!.longitud})');
            centerLat = r.ubicacion!.latitud;
            centerLng = r.ubicacion!.longitud;
            zoom = 15.5; // Zoom más cercano para ver un área de ~3km
            cameraMoveRequested = true;
            notifyListeners();
          } else {
            print('DEBUG: El relato no tiene ubicación');
          }
        } else {
          print('DEBUG: No se encontró el relato con ID: $relatoId');
        }
      }
    } catch (e) {
      print('DEBUG: Error al buscar relato: $e');
    }
  }

  void _centerIfPossible() {
    if (focusRelatoId == null) return;
    print('DEBUG: Intentando centrar en relato ID: $focusRelatoId');
    print('DEBUG: Relatos cargados actualmente: ${relatos.length}');
    
    final idx = relatos.indexWhere((r) => r.id == focusRelatoId);
    print('DEBUG: Índice encontrado: $idx');
    
    if (idx >= 0) {
      final r = relatos[idx];
      if (r.ubicacion != null) {
        print('DEBUG: Centrando mapa en ubicación: (${r.ubicacion!.latitud}, ${r.ubicacion!.longitud})');
        final double targetLat = r.ubicacion!.latitud;
        final double targetLng = r.ubicacion!.longitud;
        final double targetZoom = 14; // aprox ~5-8km, el ajuste final lo hará MapScreen

        // Evitar solicitar movimiento si ya estamos prácticamente en ese punto/zoom
        final bool smallLatChange = (targetLat - centerLat).abs() < 0.0005;
        final bool smallLngChange = (targetLng - centerLng).abs() < 0.0005;
        final bool smallZoomChange = (targetZoom - zoom).abs() < 0.1;
        centerLat = targetLat;
        centerLng = targetLng;
        if (!(smallLatChange && smallLngChange && smallZoomChange)) {
          zoom = targetZoom;
          cameraMoveRequested = true;
          notifyListeners();
        } else {
          // Mantener selección pero no forzar animación redundante
          notifyListeners();
        }
      } else {
        print('DEBUG: ERROR - El relato no tiene ubicación');
      }
    } else {
      // Si no encontramos el relato, forzamos una búsqueda
      print('DEBUG: Relato no encontrado en los datos actuales, forzando búsqueda...');
      _fetch(force: true);
    }
  }

  // El método takeCameraMoveRequest ya no se usa porque ahora accedemos directamente
  // a _cameraMoveRequested desde MapScreen

  void _debouncedFetch({bool force = false}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: MapProvider._debouncedFetch - force=$force');
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 550), () {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: Ejecutando fetch después del debounce');
      }
      _fetch(force: force);
    });
  }

  Future<void> initialFetchIfNeeded() async {
    print('DEBUG: MapProvider.initialFetchIfNeeded - relatos.isEmpty=${relatos.isEmpty}');
    if (relatos.isEmpty) {
      // Usar un timer para evitar bloquear el hilo principal durante la inicialización
      Future.delayed(const Duration(milliseconds: 300), () {
        print('DEBUG: Ejecutando fetch inicial después del delay');
        _fetch(force: true);
      });
    }
  }

  String _cacheKey() {
    if (south == null || west == null || north == null || east == null) return 'map:none';
    final z = zoom.toStringAsFixed(1);
    return 'map:bounds:${south!.toStringAsFixed(3)},${west!.toStringAsFixed(3)},${north!.toStringAsFixed(3)},${east!.toStringAsFixed(3)}:z=$z:nearby=$nearbyOnly:r=$radioKm';
  }

  Future<void> _fetch({bool force = false}) async {
    if (!force && loading) return;
    if (nearbyOnly) {
      await _fetchNearby();
      return;
    }
    if (south == null || west == null || north == null || east == null) return;

    loading = true;
    error = null;
    notifyListeners();
    
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: Iniciando fetch de relatos en bounds: S=$south, W=$west, N=$north, E=$east');
    }

    // Intentar caché ligera (TTL 60s)
    try {
      if (_getIt.isRegistered<ICacheService>() && !force) {
        final cache = _getIt<ICacheService>();
        final cached = await cache.get<List<Relato>>(_cacheKey());
        if (cached != null && cached.isNotEmpty) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('DEBUG: Usando ${cached.length} relatos desde caché');
          }
          relatos = cached;
          loading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: Error al obtener de caché: $e');
      }
    }

    // Límite dinámico según el nivel de zoom para reducir carga en zoom bajo
    final double currentZoom = zoom;
    final int dynamicLimit = currentZoom < 8
        ? 120
        : (currentZoom < 12 ? 200 : 300);

    final res = await _useCases.relatos.obtener.enBounds(
      south: south!, west: west!, north: north!, east: east!, limit: dynamicLimit,
    );
    final data = res.valueOrNull;
    if (data != null) {
      print('DEBUG: Obtenidos ${data.length} relatos del repositorio');
      var list = data.where((r) => r.ubicacion != null).toList();
      print('DEBUG: ${list.length} relatos tienen ubicación válida');
      
      // Imprimir detalles de los primeros 3 relatos para depuración
      if (list.isNotEmpty) {
        print('DEBUG: Ejemplos de relatos con ubicación:');
        for (var i = 0; i < list.length && i < 3; i++) {
          final r = list[i];
          print('DEBUG: Relato ${i+1}: id=${r.id}, título=${r.titulo}, ubicación=(${r.ubicacion?.latitud}, ${r.ubicacion?.longitud})');
        }
      }
      
      // Filtro por categoría si aplica
      if (selectedCategoriaIds.isNotEmpty) {
        list = list.where((r) => selectedCategoriaIds.contains(r.categoriaId)).toList();
        print('DEBUG: ${list.length} relatos después de filtrar por categorías');
      }
      relatos = list;
      _centerIfPossible();
      try {
        if (_getIt.isRegistered<ICacheService>()) {
          final cache = _getIt<ICacheService>();
          await cache.set<List<Relato>>(_cacheKey(), relatos, ttlSeconds: 60, tag: 'map');
          print('DEBUG: Guardados ${relatos.length} relatos en caché');
        }
      } catch (e) {
        print('DEBUG: Error al guardar en caché: $e');
      }
    } else {
      error = res.errorOrNull?.message;
      print('DEBUG: Error al obtener relatos: ${error ?? "desconocido"}');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _fetchNearby() async {
    loading = true;
    error = null;
    notifyListeners();
    
    print('DEBUG: Buscando relatos cercanos en (${centerLat}, ${centerLng}) con radio ${radioKm}km');

    final res = await _useCases.relatos.obtener.cercanos(
      latitud: centerLat, longitud: centerLng, radioKm: radioKm,
    );
    final data = res.valueOrNull;
    if (data != null) {
      print('DEBUG: Obtenidos ${data.length} relatos cercanos');
      var list = data.where((r) => r.ubicacion != null).toList();
      print('DEBUG: ${list.length} relatos cercanos tienen ubicación válida');
      
      if (selectedCategoriaIds.isNotEmpty) {
        list = list.where((r) => selectedCategoriaIds.contains(r.categoriaId)).toList();
        print('DEBUG: ${list.length} relatos cercanos después de filtrar por categorías');
      }
      relatos = list;
      _centerIfPossible();
    } else {
      error = res.errorOrNull?.message;
      print('DEBUG: Error al obtener relatos cercanos: ${error ?? "desconocido"}');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _loadCategorias() async {
    try {
      categoriasLoading = true;
      categoriasError = null;
      notifyListeners();
      final uc = _getIt<ObtenerCategoriasPorTipoUseCase>();
      final res = await uc.execute(TipoContenido.relato);
      categorias = res.valueOrNull ?? [];
      categorias.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } catch (e) {
      categoriasError = e.toString();
    }
    categoriasLoading = false;
    notifyListeners();
  }

  void toggleCategoria(String categoriaId) {
    if (selectedCategoriaIds.contains(categoriaId)) {
      selectedCategoriaIds.remove(categoriaId);
    } else {
      selectedCategoriaIds.add(categoriaId);
    }
    _debouncedFetch(force: true);
    notifyListeners();
  }
}

