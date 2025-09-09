import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/factories/usecases.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_connectivity_service.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_geolocation_service.dart';
import 'package:memoria_viva_nicaragua/domain/services/i_analytics_service.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart';
import 'package:memoria_viva_nicaragua/domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

enum FeedFilter { recientes, populares, mis, liked }

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

  // Búsqueda
  String searchQuery = '';
  bool searching = false;
  String? searchError;
  List<Relato> _searchResults = [];
  Timer? _debounce;

  // Categorías para autocompletar
  List<Categoria> categorias = [];
  bool categoriasLoading = false;
  String? categoriasError;

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

  // Estado efímero: relatos a los que el usuario actual ha dado like en esta sesión
  final Set<String> _likedByMe = <String>{};
  bool isLiked(String relatoId) => _likedByMe.contains(relatoId);

  Future<void> init() async {
    _listenConnectivity();
    await _loadCurrentUser();
    _authSub?.cancel();
    _authSub = _useCases.auth.getCurrentUser.observe().listen((user) {
      _currentUserId = user?.id;
      // Al cambiar de usuario, refrescar likes propios visibles
      _likedByMe.clear();
      if (_currentUserId != null && _allRelatos.isNotEmpty) {
        _refreshLikedByMe();
      }
      relatos = _applyFilterAndSort(_activeSource());
      notifyListeners();
    });
    await Future.wait([
      loadStories(),
      _observeFeed(),
      _loadCategorias(),
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
      // Cargar estado de likes propios para los relatos visibles
      if (_currentUserId != null) {
        _refreshLikedByMe(visibles: relatos);
      }
      relatos = _applyFilterAndSort(_activeSource());
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
        out = out
            .where((r) => (r.likes + r.compartidos) > 0)
            .toList()
          ..sort((a, b) {
            final int ia = a.likes + a.compartidos;
            final int ib = b.likes + b.compartidos;
            final int cmp = ib.compareTo(ia);
            return cmp != 0 ? cmp : b.fechaCreacion.compareTo(a.fechaCreacion);
          });
        break;
      case FeedFilter.mis:
        if (_currentUserId != null) {
          out = out.where((r) => r.autorId == _currentUserId).toList();
          out.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        } else {
          out = [];
        }
        break;
      case FeedFilter.liked:
        if (_currentUserId != null) {
          out = out.where((r) => isLiked(r.id)).toList();
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
    relatos = _applyFilterAndSort(_activeSource());
    if (_currentUserId != null) {
      _refreshLikedByMe(visibles: relatos);
    }
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

  Future<void> toggleLike(String relatoId) async {
    if (_currentUserId == null) {
      feedError = 'Debes iniciar sesión para dar like';
      notifyListeners();
      return;
    }
    final int idx = _allRelatos.indexWhere((r) => r.id == relatoId);
    final res = await _useCases.relatos.toggleLike.execute(relatoId: relatoId, userId: _currentUserId!);
    if (_getIt.isRegistered<IAnalyticsService>()) {
      await _getIt<IAnalyticsService>().registrarInteraccion(
        contenidoId: relatoId,
        tipoContenido: 'relato',
        tipoInteraccion: 'like_toggle',
        propiedades: {'result': res.valueOrNull == true ? 'liked' : 'unliked'},
      );
    }
    if (res.isFailure) {
      feedError = res.errorOrNull?.message;
      notifyListeners();
      return;
    }
    if (idx != -1) {
      final r = _allRelatos[idx];
      final bool likedNow = res.valueOrNull == true;
      final int delta = likedNow ? 1 : -1;
      final updated = r.copyWith(likes: (r.likes + delta).clamp(0, 1 << 31));
      _allRelatos[idx] = updated;
      // Mantener marca efímera para icono de UI
      if (likedNow) {
        _likedByMe.add(relatoId);
      } else {
        _likedByMe.remove(relatoId);
      }
      relatos = _applyFilterAndSort(_activeSource());
      notifyListeners();
    }
  }

  Future<void> _refreshLikedByMe({List<Relato>? visibles}) async {
    try {
      final String? uid = _currentUserId;
      if (uid == null) return;
      // Consultar likes del usuario actual sobre los relatos visibles
      final List<Relato> visiblesList = visibles ?? _applyFilterAndSort(_activeSource());
      final List<Future<void>> tasks = [];
      final Set<String> newSet = <String>{};
      for (final r in visiblesList) {
        tasks.add(FirebaseFirestore.instance
            .collection('relatos')
            .doc(r.id)
            .collection('likes')
            .doc(uid)
            .get()
            .then((snap) {
          if (snap.exists) newSet.add(r.id);
        }).catchError((_) {}));
      }
      await Future.wait(tasks);
      _likedByMe
        ..clear()
        ..addAll(newSet);
      notifyListeners();
    } catch (_) {
      // Silencio: no bloquear UI por este estado auxiliar
    }
  }

  Future<void> compartir(String relatoId) async {
    final int idx = _allRelatos.indexWhere((r) => r.id == relatoId);
    if (idx != -1) {
      _allRelatos[idx] = _allRelatos[idx].incrementarCompartidos();
      relatos = _applyFilterAndSort(_allRelatos);
      notifyListeners();
    }
    final res = await _useCases.relatos.compartir.execute(relatoId: relatoId);
    if (_getIt.isRegistered<IAnalyticsService>()) {
      await _getIt<IAnalyticsService>().registrarInteraccion(
        contenidoId: relatoId,
        tipoContenido: 'relato',
        tipoInteraccion: 'share',
      );
    }
    if (res.isFailure) {
      // rollback
      if (idx != -1) {
        final r = _allRelatos[idx];
        _allRelatos[idx] = r.copyWith(compartidos: (r.compartidos - 1).clamp(0, 1 << 31));
        relatos = _applyFilterAndSort(_allRelatos);
        notifyListeners();
      }
      feedError = res.errorOrNull?.message;
    }
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
    if (_getIt.isRegistered<IAnalyticsService>()) {
      await _getIt<IAnalyticsService>().registrarInteraccion(
        contenidoId: relatoId,
        tipoContenido: 'relato',
        tipoInteraccion: 'report',
      );
    }
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
    _debounce?.cancel();
    super.dispose();
  }

  // ========= Búsqueda =========
  void setSearchQuery(String value) {
    final String q = value.trimLeft();
    searchQuery = q;
    searchError = null;
    _debounce?.cancel();
    if (q.isEmpty) {
      // Limpiar búsqueda
      _searchResults = [];
      searching = false;
      relatos = _applyFilterAndSort(_allRelatos);
      if (_currentUserId != null) {
        _refreshLikedByMe(visibles: relatos);
      }
      notifyListeners();
      return;
    }
    searching = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _doSearch(q);
    });
  }

  Future<void> _doSearch(String q) async {
    final res = await _useCases.relatos.obtener.buscar(q);
    res.when(
      success: (data) {
        _searchResults = data;
        relatos = _applyFilterAndSort(_searchResults);
        searching = false;
        searchError = null;
        if (_currentUserId != null) {
          _refreshLikedByMe(visibles: relatos);
        }
        notifyListeners();
      },
      failure: (f) {
        searching = false;
        searchError = f.message;
        notifyListeners();
      },
    );
  }

  List<Relato> _activeSource() => (searchQuery.trim().isNotEmpty) ? _searchResults : _allRelatos;

  // ========= Categorías (autocompletado) =========
  Future<void> _loadCategorias() async {
    try {
      categoriasLoading = true;
      categoriasError = null;
      final usecase = _getIt<ObtenerCategoriasPorTipoUseCase>();
      final res = await usecase.execute(TipoContenido.relato);
      categorias = res.valueOrNull ?? [];
    } catch (e) {
      categoriasError = e.toString();
    }
    categorias.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    categoriasLoading = false;
    notifyListeners();
  }

  List<String> sugerenciasCategorias(String input) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return const [];
    if (categorias.isEmpty) return const [];
    return categorias
        .map((c) => c.nombre)
        .where((n) => n.toLowerCase().contains(q))
        .take(8)
        .toList();
  }
}


