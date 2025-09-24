import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../domain/entities/evento_cultural.dart';
import '../../domain/factories/usecases.dart';

/// Provider: gestiona el carrusel superior de eventos
/// - Estado: categoría seleccionada y lista de eventos para el carrusel
class EventCarouselProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve().eventos;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  bool loading = false;
  String? error;
  List<EventoCultural> eventsForCarousel = const [];

  // Debounce y coalescing
  Timer? _debounce;
  String? _lastOpId;
  final Map<String, List<EventoCultural>> _cacheByCategory = <String, List<EventoCultural>>{};

  Future<void> init() async {
    await _load();
  }

  Future<void> refresh() async => _load(forceRemote: true);

  void setSelectedCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _load());
  }

  Future<void> _load({bool forceRemote = false}) async {
    final String key = _selectedCategoryId ?? 'all';

    if (!forceRemote && _cacheByCategory.containsKey(key)) {
      final cached = _cacheByCategory[key]!;
      if (!listEquals(cached, eventsForCarousel)) {
        eventsForCarousel = List<EventoCultural>.from(cached);
        notifyListeners();
      }
      unawaited(_fetchRemote(key));
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    await _fetchRemote(key);
    loading = false;
    notifyListeners();
  }

  Future<void> _fetchRemote(String key) async {
    try {
      final String opId = 'op_${DateTime.now().microsecondsSinceEpoch}';
      _lastOpId = opId;
      final res = await _useCases.carruselPorCategoria.execute(
        categoriaId: _selectedCategoryId,
      );
      if (_lastOpId != opId) return;
      res.when(
        success: (data) {
          _cacheByCategory[key] = List<EventoCultural>.from(data);
          if (!listEquals(eventsForCarousel, data)) {
            eventsForCarousel = data;
          }
          debugPrint('[EVENT_CAROUSEL] Cargados ${data.length} eventos');
          notifyListeners();
        },
        failure: (f) {
          error = f.message;
          debugPrint('[EVENT_CAROUSEL] Error: ${f.message}');
          notifyListeners();
        },
      );
    } catch (e) {
      error = 'Error de conexión: $e';
      debugPrint('[EVENT_CAROUSEL] Error de timeout/conexión: $e');
      notifyListeners();
    }
  }

  /// Elimina un evento por ID del carrusel actual sin refrescar desde backend
  void removeEventById(String id) {
    if (eventsForCarousel.isEmpty) return;
    final List<EventoCultural> updated = List<EventoCultural>.from(eventsForCarousel);
    final int before = updated.length;
    updated.removeWhere((e) => e.id == id);
    if (updated.length != before) {
      eventsForCarousel = updated;
      // También actualizar cache
      final String key = _selectedCategoryId ?? 'all';
      _cacheByCategory[key] = updated;
      notifyListeners();
    }
  }

  /// Inserta o reemplaza un evento en el carrusel actual sin refrescar desde backend
  void upsertEvent(EventoCultural event) {
    final int index = eventsForCarousel.indexWhere((e) => e.id == event.id);
    final List<EventoCultural> updated = List<EventoCultural>.from(eventsForCarousel);
    if (index >= 0) {
      updated[index] = event;
    } else {
      // Insertar al inicio para dar feedback inmediato
      updated.insert(0, event);
    }
    eventsForCarousel = updated;
    // También actualizar cache
    final String key = _selectedCategoryId ?? 'all';
    _cacheByCategory[key] = updated;
    notifyListeners();
  }
}


