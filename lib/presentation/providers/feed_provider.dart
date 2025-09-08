import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/factories/usecases.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_connectivity_service.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_geolocation_service.dart';

enum FeedFilter { recientes, populares, mis }

class FeedProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve();
  final GetIt _getIt = GetIt.I;

  // Historias (eventos cercanos)
  bool storiesLoading = false;
  String? storiesError;
  List<EventoCultural> historias = [];

  // Feed de relatos
  bool feedLoading = false;
  String? feedError;
  List<Relato> relatos = [];
  // Fuente completa desde el stream
  List<Relato> _allRelatos = [];

  // Filtro actual
  FeedFilter filtro = FeedFilter.recientes;

  // Paginación (simple): tamaño de página
  int _pageSize = 20;

  // Estado de conectividad
  bool offline = false;
  StreamSubscription? _connectivitySub;
  StreamSubscription<List<Relato>>? _relatosSub;
  StreamSubscription? _authSub;

  String? _currentUserId;
  bool get isLoggedIn => _currentUserId != null;
  String? get currentUserId => _currentUserId;

  Future<void> init() async {
    _listenConnectivity();
    await _loadCurrentUser();
    _authSub?.cancel();
    _authSub = _useCases.auth.getCurrentUser.observe().listen((user) {
      _currentUserId = user?.id;
      relatos = _applyFilterAndSort(_allRelatos);
      notifyListeners();
    });
    await Future.wait([
      loadStories(),
      _observeFeed(),
    ]);
  }

  void _listenConnectivity() {
    if (_getIt.isRegistered<IConnectivityService>()) {
      final conn = _getIt<IConnectivityService>();
      offline = !conn.current.online;
      _connectivitySub?.cancel();
      _connectivitySub = conn.changes.listen((state) {
        offline = !state.online;
        notifyListeners();
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final result = await _useCases.auth.getCurrentUser.execute();
    _currentUserId = result.valueOrNull?.id;
  }

  Future<void> loadStories() async {
    storiesLoading = true;
    storiesError = null;
    notifyListeners();

    try {
      // Intentar por geolocalización
      if (_getIt.isRegistered<IGeolocationService>()) {
        final geo = _getIt<IGeolocationService>();
        try {
          final loc = await geo.obtenerUbicacionActual();
          final res = await _useCases.eventos.obtener.cercanos(
            latitud: loc.latitud,
            longitud: loc.longitud,
            radioKm: 50,
          );
          final data = res.valueOrNull;
          if (data != null && data.isNotEmpty) {
            historias = data;
          } else {
            final destacados = await _useCases.eventos.obtener.execute();
            historias = destacados.valueOrNull ?? [];
          }
        } catch (_) {
          final destacados = await _useCases.eventos.obtener.execute();
          historias = destacados.valueOrNull ?? [];
        }
      } else {
        final destacados = await _useCases.eventos.obtener.execute();
        historias = destacados.valueOrNull ?? [];
      }
    } catch (e) {
      storiesError = e.toString();
    }

    storiesLoading = false;
    notifyListeners();
  }

  Future<void> _observeFeed() async {
    feedLoading = true;
    feedError = null;
    notifyListeners();

    _relatosSub?.cancel();
    _relatosSub = _useCases.relatos.obtener.observe().listen((data) {
      _allRelatos = data;
      relatos = _applyFilterAndSort(_allRelatos);
      feedLoading = false;
      notifyListeners();
    }, onError: (err) {
      feedError = err.toString();
      feedLoading = false;
      notifyListeners();
    });
  }

  List<Relato> _applyFilterAndSort(List<Relato> input) {
    List<Relato> out = List.of(input);
    switch (filtro) {
      case FeedFilter.recientes:
        out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        break;
      case FeedFilter.populares:
        out.sort((a, b) => (b.likes + b.compartidos).compareTo(a.likes + a.compartidos));
        break;
      case FeedFilter.mis:
        if (_currentUserId != null) {
          out = out.where((r) => r.autorId == _currentUserId).toList();
          out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        } else {
          out = [];
        }
        break;
    }

    // Paginación simple por tamaño
    if (out.length > _pageSize) {
      out = out.sublist(0, _pageSize);
    }
    return out;
  }

  void changeFilter(FeedFilter value) {
    filtro = value;
    relatos = _applyFilterAndSort(_allRelatos);
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadStories(),
      _observeFeed(),
    ]);
  }

  Future<void> loadMore() async {
    // Aumentar ventana de página y re-aplicar
    _pageSize += 20;
    relatos = _applyFilterAndSort(_allRelatos);
    notifyListeners();
  }

  Future<void> reportRelato({required String relatoId, required String razon}) async {
    if (_currentUserId == null) {
      feedError = 'Debes iniciar sesión para reportar';
      notifyListeners();
      return;
    }
    final res = await _useCases.relatos.reportar.execute(
      usuarioId: _currentUserId!,
      relatoId: relatoId,
      razon: razon,
    );
    if (res.isFailure) {
      feedError = res.errorOrNull?.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _relatosSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}


