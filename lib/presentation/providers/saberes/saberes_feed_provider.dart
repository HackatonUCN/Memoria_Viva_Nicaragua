import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/saber_popular.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/factories/usecases.dart';
import '../../../domain/services/i_connectivity_service.dart';
import '../../../domain/services/i_analytics_service.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../../domain/enums/tipos_contenido.dart';
import 'saber_form_provider.dart';

enum FeedFilter { recientes, populares, mis, liked }

class SaberesFeedProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve();
  final GetIt _getIt = GetIt.I;

  bool feedLoading = false;
  String? feedError;
  List<SaberPopular> saberes = [];
  List<SaberPopular> _allSaberes = [];
  final Map<String, int> _idToIndex = <String, int>{};

  // Búsqueda
  String searchQuery = '';
  bool searching = false;
  String? searchError;
  List<SaberPopular> _searchResults = [];
  Timer? _debounce;

  // Filtro actual
  FeedFilter filtro = FeedFilter.recientes;
  bool filterSwitching = false;

  int _pageSize = kIsWeb ? 16 : 20;

  bool offline = false;
  StreamSubscription? _connectivitySub;
  StreamSubscription<List<SaberPopular>>? _saberesSub;
  StreamSubscription? _authSub;

  String? _currentUserId;
  bool get isLoggedIn => _currentUserId != null;
  String? get currentUserId => _currentUserId;
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  final Set<String> _likedByMe = <String>{};
  bool isLiked(String saberId) => _likedByMe.contains(saberId);
  bool _awaitingFeedForLiked = false;

  // Destacados (tipo "libro"): afectados solo por la búsqueda, no por otros filtros
  List<SaberPopular> get destacadosLibres {
    final List<SaberPopular> source = _activeSource();
    final List<SaberPopular> libros = source
        .where((s) => (
          s.categoriaId == 'saber_libros' ||
          s.categoriaNombre.toLowerCase() == 'libro' ||
          s.categoriaNombre.toLowerCase() == 'libros'
        ))
        .toList();
    libros.sort((a, b) {
      final int ia = a.likes + a.compartidos;
      final int ib = b.likes + b.compartidos;
      final int cmp = ib.compareTo(ia);
      return cmp != 0 ? cmp : b.fechaCreacion.compareTo(a.fechaCreacion);
    });
    return libros.length > 10 ? libros.sublist(0, 10) : libros;
  }

  bool _esLibro(SaberPopular s) {
    final String nombre = s.categoriaNombre.toLowerCase();
    return s.categoriaId == 'saber_libros' || nombre == 'libro' || nombre == 'libros';
  }

  Future<void> init() async {
    _listenConnectivity();
    await _loadCurrentUser();
    if (_currentUserId != null) {
      await _loadAllLikedIds();
    }
    // Prefetch categorías para el sheet de publicación/edición (seed cache)
    unawaited(_loadCategorias());
    _authSub?.cancel();
    _authSub = _useCases.auth.getCurrentUser.observe().listen((user) async {
      _currentUserId = user?.id;
      _likedByMe.clear();
      if (_currentUserId != null) {
        // resolver admin de forma ligera leyendo user actual si está registrado en UseCases
        try {
          final u = await _useCases.auth.getCurrentUser.execute();
          _isAdmin = (u.valueOrNull?.rol.value == 'admin');
        } catch (_) {}
        await _loadAllLikedIds();
        if (_allSaberes.isNotEmpty && filtro != FeedFilter.liked) {
          _refreshLikedByMe(visibles: _applyFilterAndSort(_activeSource()));
        }
      }
      saberes = _applyFilterAndSort(_activeSource());
      notifyListeners();
    });
    await _observeFeed();
  }

  void _listenConnectivity() {
    if (_getIt.isRegistered<IConnectivityService>()) {
      _connectivitySub?.cancel();
      _connectivitySub = _getIt<IConnectivityService>().changes.listen((state) {
        offline = !state.online || state.type == ConnectivityType.none;
        notifyListeners();
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final current = await _useCases.auth.getCurrentUser.execute();
    _currentUserId = current.valueOrNull?.id;
    _isAdmin = (current.valueOrNull?.rol.value == 'admin');
  }

  Future<void> _observeFeed() async {
    debugPrint('[SABER_FEED][OBSERVE_START]');
    feedLoading = true;
    feedError = null;
    notifyListeners();

    _saberesSub?.cancel();
    _saberesSub = _useCases.saberes.obtener.observe().listen((data) async {
      debugPrint('[SABER_FEED][OBSERVE_DATA] count=' + data.length.toString());
      final bool sameLength = data.length == _allSaberes.length;
      bool sameIds = false;
      if (sameLength) {
        sameIds = true;
        for (int i = 0; i < data.length; i++) {
          if (data[i].id != _allSaberes[i].id) { sameIds = false; break; }
        }
      }
      _allSaberes = data;
      _rebuildIndex();
      if (filtro == FeedFilter.liked) {
        if (_currentUserId != null && _likedByMe.isEmpty) {
          await _loadAllLikedIds();
        }
        saberes = _applyFilterAndSort(_activeSource());
      } else {
        final visibles = _applyFilterAndSort(_activeSource());
        if (_currentUserId != null) {
          await _refreshLikedByMe(visibles: visibles);
        }
        saberes = visibles;
      }
      feedLoading = false;
      _awaitingFeedForLiked = false;
      if (!(sameLength && sameIds)) {
        notifyListeners();
      }
    }, onError: (err) {
      debugPrint('[SABER_FEED][OBSERVE_ERROR] ' + err.toString());
      feedError = err.toString();
      feedLoading = false;
      notifyListeners();
    });
  }

  List<SaberPopular> _applyFilterAndSort(List<SaberPopular> input) {
    List<SaberPopular> out = List.of(input);
    // Omitir libros del feed principal (siempre fuera de la lista)
    out = out.where((r) => !_esLibro(r)).toList();
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
    if (out.length > _pageSize) {
      out = out.sublist(0, _pageSize);
    }
    return out;
  }

  Future<void> setFiltro(FeedFilter value) async {
    _debounce?.cancel();
    feedError = null;
    _pageSize = 20;

    filtro = value;
    filterSwitching = true;
    notifyListeners();

    if (value == FeedFilter.liked) {
      feedLoading = true;
      notifyListeners();
      await _loadAllLikedIds();
      _awaitingFeedForLiked = _allSaberes.isEmpty;
      if (!_awaitingFeedForLiked) {
        saberes = _applyFilterAndSort(_allSaberes);
        notifyListeners();
      }
    } else {
      await _refreshLikedByMe(visibles: _allSaberes);
      saberes = _applyFilterAndSort(_allSaberes);
      notifyListeners();
    }
    filterSwitching = false;
  }

  Future<void> loadMore() async {
    _pageSize += kIsWeb ? 16 : 20;
    saberes = _applyFilterAndSort(_activeSource());
    notifyListeners();
  }

  Future<void> refresh() async {
    await _observeFeed();
  }

  // Likes optimistas + subcolección
  Future<void> toggleLike(String saberId) async {
    if (_currentUserId == null) {
      feedError = 'Debes iniciar sesión para dar like';
      notifyListeners();
      return;
    }
    // No permitir like al propio saber
    final int idxSelf = _idToIndex[saberId] ?? _allSaberes.indexWhere((r) => r.id == saberId);
    if (idxSelf != -1 && _allSaberes[idxSelf].autorId == _currentUserId) {
      return;
    }
    final int idx = _idToIndex[saberId] ?? _allSaberes.indexWhere((r) => r.id == saberId);
    if (idx == -1) return;
    final SaberPopular r = _allSaberes[idx];

    final likeDoc = FirebaseFirestore.instance
        .collection('saberes_populares')
        .doc(saberId)
        .collection('likes')
        .doc(_currentUserId);

    final snap = await likeDoc.get();
    if (!snap.exists) {
      // like
      await likeDoc.set({'uid': _currentUserId, 'at': FieldValue.serverTimestamp()}).catchError((e) {
        debugPrint('[SABER_FEED][LIKE_SUBCOLL_ERROR] ' + e.toString());
      });
      _allSaberes[idx] = r.copyWith(likes: r.likes + 1);
      _likedByMe.add(saberId);
      saberes = _applyFilterAndSort(_activeSource());
      notifyListeners();
      final likeRes = await _useCases.saberes.like.execute(saberId: saberId);
      if (likeRes.isFailure) {
        debugPrint('[SABER_FEED][LIKE_USECASE_ERROR] ' + (likeRes.errorOrNull?.toString() ?? ''));
      }
      if (_getIt.isRegistered<IAnalyticsService>()) {
        await _getIt<IAnalyticsService>().registrarInteraccion(
          contenidoId: saberId,
          tipoContenido: 'saber',
          tipoInteraccion: 'like_toggle',
          propiedades: {'result': 'liked'},
        );
      }
    } else {
      // unlike (solo UI y subcolección; el server no decrementa en repo)
      await likeDoc.delete().catchError((e) {
        debugPrint('[SABER_FEED][UNLIKE_SUBCOLL_ERROR] ' + e.toString());
      });
      _allSaberes[idx] = r.copyWith(likes: (r.likes - 1).clamp(0, 1 << 31));
      _likedByMe.remove(saberId);
      saberes = _applyFilterAndSort(_activeSource());
      notifyListeners();
      if (_getIt.isRegistered<IAnalyticsService>()) {
        await _getIt<IAnalyticsService>().registrarInteraccion(
          contenidoId: saberId,
          tipoContenido: 'saber',
          tipoInteraccion: 'like_toggle',
          propiedades: {'result': 'unliked'},
        );
      }
    }
  }

  // ========= CRUD Optimista: insertar =========
  void insertarOptimista(SaberPopular nuevo) {
    if (_idToIndex.containsKey(nuevo.id) || _allSaberes.any((r) => r.id == nuevo.id)) {
      final int idx = _idToIndex[nuevo.id] ?? _allSaberes.indexWhere((r) => r.id == nuevo.id);
      if (idx >= 0) {
        _allSaberes[idx] = nuevo;
      }
    } else {
      _allSaberes.insert(0, nuevo);
    }
    _rebuildIndex(startFrom: 0);
    saberes = _applyFilterAndSort(_activeSource());
    notifyListeners();
  }

  // ========= CRUD Optimista: actualizar =========
  bool actualizarOptimista(SaberPopular edited) {
    final int idx = _idToIndex[edited.id] ?? _allSaberes.indexWhere((r) => r.id == edited.id);
    if (idx == -1) return false;
    _allSaberes[idx] = edited;
    _rebuildIndex(startFrom: idx);
    saberes = _applyFilterAndSort(_activeSource());
    notifyListeners();
    return true;
  }

  // ========= CRUD Optimista: eliminar =========
  Future<bool> eliminarOptimista({required String saberId, required String usuarioId}) async {
    final int idx = _idToIndex[saberId] ?? _allSaberes.indexWhere((r) => r.id == saberId);
    if (idx == -1) return false;
    final SaberPopular backup = _allSaberes[idx];
    _allSaberes.removeAt(idx);
    _idToIndex.remove(saberId);
    _rebuildIndex(startFrom: idx);
    saberes = _applyFilterAndSort(_allSaberes);
    notifyListeners();

    final res = await _useCases.saberes.eliminar.execute(usuarioId: usuarioId, saberId: saberId);
    if (res.isFailure) {
      // rollback
      _allSaberes.insert(idx.clamp(0, _allSaberes.length), backup);
      _rebuildIndex(startFrom: idx);
      saberes = _applyFilterAndSort(_allSaberes);
      notifyListeners();
      feedError = res.errorOrNull?.message;
      return false;
    }
    return true;
  }

  Future<void> compartir(String saberId) async {
    final int idx = _idToIndex[saberId] ?? _allSaberes.indexWhere((r) => r.id == saberId);
    if (idx != -1) {
      _allSaberes[idx] = _allSaberes[idx].copyWith(compartidos: _allSaberes[idx].compartidos + 1);
      saberes = _applyFilterAndSort(_allSaberes);
      notifyListeners();
    }
    final res = await _useCases.saberes.compartir.execute(saberId: saberId);
    if (_getIt.isRegistered<IAnalyticsService>()) {
      await _getIt<IAnalyticsService>().registrarInteraccion(
        contenidoId: saberId,
        tipoContenido: 'saber',
        tipoInteraccion: 'share',
      );
    }
    if (res.isFailure && idx != -1) {
      debugPrint('[SABER_FEED][SHARE_USECASE_ERROR] ' + (res.errorOrNull?.toString() ?? ''));
      final r = _allSaberes[idx];
      _allSaberes[idx] = r.copyWith(compartidos: (r.compartidos - 1).clamp(0, 1 << 31));
      saberes = _applyFilterAndSort(_allSaberes);
      notifyListeners();
      feedError = res.errorOrNull?.message;
    }
  }

  Future<void> reportar(String saberId, String razon) async {
    if (_currentUserId == null) {
      feedError = 'Debes iniciar sesión para reportar';
      notifyListeners();
      return;
    }
    final res = await _useCases.saberes.reportar.execute(
      usuarioId: _currentUserId!,
      saberId: saberId,
      razon: razon,
    );
    if (_getIt.isRegistered<IAnalyticsService>()) {
      await _getIt<IAnalyticsService>().registrarInteraccion(
        contenidoId: saberId,
        tipoContenido: 'saber',
        tipoInteraccion: 'report',
      );
    }
    if (res.isFailure) {
      debugPrint('[SABER_FEED][REPORT_USECASE_ERROR] ' + (res.errorOrNull?.toString() ?? ''));
      feedError = res.errorOrNull?.message;
      notifyListeners();
    }
  }

  Future<void> _refreshLikedByMe({List<SaberPopular>? visibles}) async {
    try {
      final String? uid = _currentUserId;
      if (uid == null) return;
      if (_likedByMe.isNotEmpty && visibles != null) {
        final Set<String> visiblesIds = visibles.map((e) => e.id).toSet();
        final Set<String> intersect = _likedByMe.intersection(visiblesIds);
        _likedByMe
          ..clear()
          ..addAll(intersect);
        notifyListeners();
        return;
      }
      final List<SaberPopular> visiblesList = visibles ?? _applyFilterAndSort(_activeSource());
      if (visiblesList.isEmpty) return;
      final List<Future<void>> tasks = [];
      final Set<String> newSet = <String>{};
      for (final r in visiblesList) {
        tasks.add(FirebaseFirestore.instance
            .collection('saberes_populares')
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
    } catch (_) {}
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
        // Solo likes bajo saberes_populares
        final parent = doc.reference.parent.parent;
        if (parent != null && parent.path.startsWith('saberes_populares/')) {
          likedIds.add(parent.id);
        }
      }
      _likedByMe
        ..clear()
        ..addAll(likedIds);
    } catch (_) {}
  }

  void setSearchQuery(String value) {
    final String q = value.trimLeft();
    searchQuery = q;
    searchError = null;
    _debounce?.cancel();
    if (q.isEmpty) {
      _searchResults = [];
      searching = false;
      saberes = _applyFilterAndSort(_allSaberes);
      if (_currentUserId != null) {
        _refreshLikedByMe(visibles: saberes);
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
    debugPrint('[SABER_FEED][SEARCH_START] q=' + q);
    final String opId = DateTime.now().microsecondsSinceEpoch.toString();
    final localOp = opId;
    _lastSearchOpId = opId;
    final res = await _useCases.saberes.obtener.buscar(q);
    res.when(
      success: (data) {
        debugPrint('[SABER_FEED][SEARCH_OK] count=' + data.length.toString());
        if (_lastSearchOpId != localOp) return;
        _searchResults = data;
        saberes = _applyFilterAndSort(_searchResults);
        searching = false;
        searchError = null;
        if (_currentUserId != null) {
          _refreshLikedByMe(visibles: saberes);
        }
        notifyListeners();
      },
      failure: (f) {
        debugPrint('[SABER_FEED][SEARCH_ERROR] code=' + (f.code ?? '') + ' msg=' + f.message);
        if (_lastSearchOpId != localOp) return;
        searching = false;
        searchError = f.message;
        notifyListeners();
      },
    );
  }

  List<SaberPopular> _activeSource() => (searchQuery.trim().isNotEmpty) ? _searchResults : _allSaberes;

  String? _lastSearchOpId;

  void _rebuildIndex({int startFrom = 0}) {
    if (startFrom <= 0) {
      _idToIndex
        ..clear()
        ..addEntries(Iterable.generate(_allSaberes.length, (i) => MapEntry(_allSaberes[i].id, i)));
      return;
    }
    for (int i = startFrom; i < _allSaberes.length; i++) {
      _idToIndex[_allSaberes[i].id] = i;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _saberesSub?.cancel();
    _authSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

// ======== Helpers privados adicionales ========
extension _CategoriasSeed on SaberesFeedProvider {
  Future<void> _loadCategorias() async {
    try {
      final usecase = _getIt<ObtenerCategoriasPorTipoUseCase>();
      final res = await usecase.execute(TipoContenido.saber);
      final List<Categoria> cats = res.valueOrNull ?? const [];
      cats.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      try { SaberFormProvider.seedCategoriasCache(cats); } catch (_) {}
    } catch (_) {}
  }
}

