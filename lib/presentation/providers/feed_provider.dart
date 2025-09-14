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
import 'package:memoria_viva_nicaragua/presentation/providers/relatos/relato_form_provider.dart';

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
  final Map<String, int> _idToIndex = <String, int>{};

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
  bool filterSwitching = false;

  // Paginación (simple): tamaño de página (ajustado por plataforma)
  int _pageSize = kIsWeb ? 16 : 20;

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
  bool _awaitingFeedForLiked = false;

  Future<void> init() async {
    _listenConnectivity();
    await _loadCurrentUser();
    // Precargar likes del usuario para que íconos y filtro "Me gusta" funcionen desde el inicio
    if (_currentUserId != null) {
      await _loadAllLikedIds();
    }
    _authSub?.cancel();
    _authSub = _useCases.auth.getCurrentUser.observe().listen((user) async {
      _currentUserId = user?.id;
      // Al cambiar de usuario, refrescar likes propios visibles
      _likedByMe.clear();
      if (_currentUserId != null) {
        // Cargar set global de liked para consistencia inmediata
        await _loadAllLikedIds();
        if (_allRelatos.isNotEmpty && filtro != FeedFilter.liked) {
          _refreshLikedByMe(visibles: _applyFilterAndSort(_activeSource()));
        }
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
    _relatosSub = _useCases.relatos.obtener.observe().listen((data) async {
      // Deduplicar emisiones: si conjunto de IDs no cambió, evitar coste
      final String prevKey = _allRelatos.isEmpty ? '' : _allRelatos.first.id;
      final bool sameLength = data.length == _allRelatos.length;
      bool sameIds = false;
      if (sameLength) {
        sameIds = true;
        for (int i = 0; i < data.length; i++) {
          if (data[i].id != _allRelatos[i].id) { sameIds = false; break; }
        }
      }
      _allRelatos = data;
      _rebuildIndex();
      // Calcular visibles con la fuente actual (búsqueda o feed completo)
      if (filtro == FeedFilter.liked) {
        if (_currentUserId != null && _likedByMe.isEmpty) {
          await _loadAllLikedIds();
        }
        relatos = _applyFilterAndSort(_activeSource());
      } else {
        final visibles = _applyFilterAndSort(_activeSource());
        if (_currentUserId != null) {
          await _refreshLikedByMe(visibles: visibles);
        }
        relatos = visibles;
      }
      feedLoading = false;
      _awaitingFeedForLiked = false;
      if (!(sameLength && sameIds)) {
        notifyListeners();
      }
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
    // Mantener compatibilidad; preferir setFiltro
    // ignore: discarded_futures
    setFiltro(value);
  }

  Future<void> setFiltro(FeedFilter value) async {
    // Reset de estado y paginación
    _debounce?.cancel();
    searchQuery = '';
    searchError = null;
    searching = false;
    _searchResults = [];
    feedError = null;
    _pageSize = 20;

    filtro = value;
    filterSwitching = true;
    notifyListeners();

    // Si es filtro de "Me gusta", cargar IDs liked globalmente
    if (filtro == FeedFilter.liked) {
      if (_currentUserId == null) {
        relatos = [];
        notifyListeners();
        return;
      }
      feedLoading = true;
      notifyListeners();
      await _loadAllLikedIds();
      _awaitingFeedForLiked = _allRelatos.isEmpty;
      if (!_awaitingFeedForLiked) {
        relatos = _applyFilterAndSort(_activeSource());
        feedLoading = false;
      }
    } else if (_currentUserId != null) {
      // Para otros filtros, refrescar likes de visibles para iconos
      // Importante: refrescar por el conjunto completo para evitar misses al paginar
      await _refreshLikedByMe(visibles: _allRelatos);
    }

    if (filtro != FeedFilter.liked || !_awaitingFeedForLiked) {
      relatos = _applyFilterAndSort(_activeSource());
    }
    // Dar un pequeño margen para que la UI muestre skeletons y evitar jank de cambio abrupto
    Future.microtask(() {
      filterSwitching = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    await Future.wait([
      loadStories(),
      _observeFeed(),
    ]);
  }

  Future<void> loadMore() async {
    // Aumentar ventana de página y re-aplicar (incremento menor en Web por peso de DOM/canvas)
    _pageSize += (kIsWeb ? 12 : 20);
    relatos = _applyFilterAndSort(_allRelatos);
    notifyListeners();
  }

  Future<void> toggleLike(String relatoId) async {
    if (_currentUserId == null) {
      feedError = 'Debes iniciar sesión para dar like';
      notifyListeners();
      return;
    }
    final int idx = _idToIndex[relatoId] ?? _allRelatos.indexWhere((r) => r.id == relatoId);
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
      _idToIndex[relatoId] = idx;
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
      // Si ya tenemos el set global, podemos opcionalmente intersectar con visibles para acelerar
      if (_likedByMe.isNotEmpty && visibles != null) {
        final Set<String> visiblesIds = visibles.map((e) => e.id).toSet();
        final Set<String> intersect = _likedByMe.intersection(visiblesIds);
        _likedByMe
          ..clear()
          ..addAll(intersect);
        notifyListeners();
        return;
      }

      // Fallback: consultar por visibles
      final List<Relato> visiblesList = visibles ?? _applyFilterAndSort(_activeSource());
      if (visiblesList.isEmpty) return;
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

  Future<void> _loadAllLikedIds() async {
    try {
      final String? uid = _currentUserId;
      if (uid == null) return;
      final query = await FirebaseFirestore.instance
          .collectionGroup('likes')
          .where(FieldPath.documentId, isEqualTo: uid)
          .get();
      final Set<String> likedIds = <String>{};
      for (final doc in query.docs) {
        final parentRelato = doc.reference.parent.parent;
        if (parentRelato != null) {
          likedIds.add(parentRelato.id);
        }
      }
      _likedByMe
        ..clear()
        ..addAll(likedIds);
    } catch (_) {
      // Silencio; un fallo aquí no debe bloquear el feed
    }
  }

  Future<void> compartir(String relatoId) async {
    final int idx = _idToIndex[relatoId] ?? _allRelatos.indexWhere((r) => r.id == relatoId);
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

  // ========= CRUD Optimista: eliminar =========
  Future<bool> eliminarOptimista({required String relatoId, required String usuarioId}) async {
    // Ocultar de la UI inmediatamente
    final int idx = _idToIndex[relatoId] ?? _allRelatos.indexWhere((r) => r.id == relatoId);
    if (idx == -1) return false;
    final Relato backup = _allRelatos[idx];
    _allRelatos.removeAt(idx);
    _idToIndex.remove(relatoId);
    _rebuildIndex(startFrom: idx);
    relatos = _applyFilterAndSort(_allRelatos);
    notifyListeners();

    final res = await _useCases.relatos.eliminar.execute(usuarioId: usuarioId, relatoId: relatoId);
    if (res.isFailure) {
      // rollback
      _allRelatos.insert(idx.clamp(0, _allRelatos.length), backup);
      _rebuildIndex(startFrom: idx);
      relatos = _applyFilterAndSort(_allRelatos);
      notifyListeners();
      feedError = res.errorOrNull?.message;
      return false;
    }
    return true;
  }

  // ========= CRUD Optimista: insertar =========
  void insertarOptimista(Relato nuevo) {
    // Insertar al principio de la fuente completa
    _allRelatos.insert(0, nuevo);
    _rebuildIndex(startFrom: 0);
    relatos = _applyFilterAndSort(_activeSource());
    notifyListeners();
  }

  // ========= CRUD Optimista: actualizar =========
  void actualizarOptimista(Relato actualizado) {
    final int idx = _idToIndex[actualizado.id] ?? _allRelatos.indexWhere((r) => r.id == actualizado.id);
    if (idx == -1) return;
    _allRelatos[idx] = actualizado;
    _idToIndex[actualizado.id] = idx;
    relatos = _applyFilterAndSort(_activeSource());
    notifyListeners();
  }

  void _rebuildIndex({int startFrom = 0}) {
    if (startFrom <= 0) {
      _idToIndex
        ..clear()
        ..addEntries(Iterable.generate(_allRelatos.length, (i) => MapEntry(_allRelatos[i].id, i)));
      return;
    }
    for (int i = startFrom; i < _allRelatos.length; i++) {
      _idToIndex[_allRelatos[i].id] = i;
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
    final String opId = DateTime.now().microsecondsSinceEpoch.toString();
    final localOp = opId;
    _lastSearchOpId = opId;
    final res = await _useCases.relatos.obtener.buscar(q);
    res.when(
      success: (data) {
        // Descartar resultados obsoletos
        if (_lastSearchOpId != localOp) return;
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
        if (_lastSearchOpId != localOp) return;
        searching = false;
        searchError = f.message;
        notifyListeners();
      },
    );
  }

  List<Relato> _activeSource() => (searchQuery.trim().isNotEmpty) ? _searchResults : _allRelatos;

  String? _lastSearchOpId;

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

    // Sembrar cache para el sheet de publicación/edición
    try {
      RelatoFormProvider.seedCategoriasCache(categorias);
    } catch (_) {}
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


