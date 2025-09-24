import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/entities/evento_cultural.dart';
import '../../domain/factories/usecases.dart';

/// Provider: gestiona la lista inferior de eventos
/// - Filtros: texto de búsqueda y rango de fechas visibles
class EventListProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve().eventos;

  String _searchText = '';
  String get searchText => _searchText;

  DateTimeRange? _visibleRange;
  DateTimeRange? get visibleRange => _visibleRange;

  bool loading = false;
  String? error;
  List<EventoCultural> eventsForList = const [];

  // Debounce y coalescing
  Timer? _debounce;
  String? _lastOpId;

  // Cache en memoria por bucket+query
  final Map<String, List<EventoCultural>> _cacheByKey = <String, List<EventoCultural>>{};

  // Bucket helpers - cache diferente para día específico vs rangos amplios vs búsqueda global
  String _bucketKey(DateTimeRange r, String q) {
    final DateTime s = r.start;
    final DateTime e = r.end;
    final String query = q.trim().toLowerCase();
    
    // Si hay búsqueda de texto, usar cache global
    if (query.isNotEmpty) {
      return 'search:global|q:$query';
    }
    
    // Si es un día específico (diferencia de 1 día), usar cache por día
    final bool isDaySpecific = e.difference(s).inDays == 1;
    if (isDaySpecific) {
      final String dayKey = '${s.year}${s.month.toString().padLeft(2, '0')}${s.day.toString().padLeft(2, '0')}';
      return 'day:$dayKey|q:$query';
    }
    
    // Para rangos amplios sin búsqueda, usar cache por semana
    final int week = int.parse('${s.year}${(s.month).toString().padLeft(2, '0')}${(s.day ~/ 7).toString()}');
    return 'wk:$week|q:$query';
  }

  // Helper para obtener clave de semana desde un día específico
  String _getWeekKey(DateTime day, String q) {
    final String query = q.trim().toLowerCase();
    final int week = int.parse('${day.year}${(day.month).toString().padLeft(2, '0')}${(day.day ~/ 7).toString()}');
    return 'wk:$week|q:$query';
  }

  // Helper para búsqueda global - rango amplio de 1 año
  DateTimeRange _getGlobalSearchRange() {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year - 1, now.month, now.day); // 1 año atrás
    final DateTime end = DateTime(now.year + 1, now.month, now.day);   // 1 año adelante
    return DateTimeRange(start: start, end: end);
  }

  Future<void> init({DateTimeRange? initialRange}) async {
    _visibleRange = initialRange;
    await _load(immediate: true);
  }

  Future<void> refresh() async => _load(forceRemote: true);

  void setSearchText(String text) {
    if (_searchText == text) return;
    _searchText = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _load());
  }

  void setVisibleRange(DateTimeRange range) {
    final same = _visibleRange != null && _visibleRange!.start == range.start && _visibleRange!.end == range.end;
    if (same) return;
    _visibleRange = range;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => _load());
  }

  Future<void> _load({bool immediate = false, bool forceRemote = false}) async {
    if (_visibleRange == null) return;
    
    // Para búsqueda global: usar rango amplio (1 año) cuando hay texto de búsqueda
    final bool hasSearchText = _searchText.trim().isNotEmpty;
    final DateTimeRange range = hasSearchText 
        ? _getGlobalSearchRange() 
        : _visibleRange!;
    
    final String key = _bucketKey(range, _searchText);

    // SWR: servir cache inmediato si existe
    if (!forceRemote && _cacheByKey.containsKey(key)) {
      final cached = _cacheByKey[key]!;
      if (!listEquals(cached, eventsForList)) {
        eventsForList = List<EventoCultural>.from(cached);
        notifyListeners();
      }
      // refrescar en background
      unawaited(_fetchRemote(range, key));
      return;
    }

    // Solo optimizar cache para días específicos cuando NO hay búsqueda
    if (!hasSearchText) {
      final bool isDaySpecific = range.end.difference(range.start).inDays == 1;
      if (isDaySpecific && !forceRemote) {
        final String weekKey = _getWeekKey(range.start, _searchText);
        if (_cacheByKey.containsKey(weekKey)) {
          final weekEvents = _cacheByKey[weekKey]!;
          final dayEvents = weekEvents.where((e) {
            final eventDate = DateTime(e.fechaInicio.year, e.fechaInicio.month, e.fechaInicio.day);
            final selectedDate = DateTime(range.start.year, range.start.month, range.start.day);
            return eventDate == selectedDate || 
                   (e.fechaInicio.isBefore(range.end) && e.fechaFin.isAfter(range.start));
          }).toList();
          
          _cacheByKey[key] = dayEvents;
          if (!listEquals(eventsForList, dayEvents)) {
            eventsForList = dayEvents;
            notifyListeners();
          }
          // refrescar en background para ese día específico
          unawaited(_fetchRemote(range, key));
          return;
        }
      }
    }

    // Si immediate, no muestres loading si hay cache vacío pero haz fetch
    loading = true;
    error = null;
    notifyListeners();
    await _fetchRemote(range, key);
    loading = false;
    notifyListeners();
  }

  Future<void> _fetchRemote(DateTimeRange range, String key) async {
    final String opId = 'op_${DateTime.now().microsecondsSinceEpoch}';
    _lastOpId = opId;
    final res = await _useCases.porRangoYBusqueda.execute(
      inicio: range.start,
      fin: range.end,
      texto: _searchText,
    );
    if (_lastOpId != opId) return; // cancelar resultados tardíos
    res.when(
      success: (data) {
        _cacheByKey[key] = List<EventoCultural>.from(data);
        if (!listEquals(eventsForList, data)) {
          eventsForList = data;
          error = null;
        }
        notifyListeners();
      },
      failure: (f) {
        error = f.message;
        notifyListeners();
      },
    );
  }

  /// Elimina un evento por ID de la lista actual sin refrescar desde backend
  void removeEventById(String id) {
    if (eventsForList.isEmpty) return;
    final List<EventoCultural> updated = List<EventoCultural>.from(eventsForList);
    final int before = updated.length;
    updated.removeWhere((e) => e.id == id);
    if (updated.length != before) {
      eventsForList = updated;
      notifyListeners();
    }
  }

  /// Inserta o reemplaza un evento en la lista actual sin refrescar desde backend
  void upsertEvent(EventoCultural event) {
    final int index = eventsForList.indexWhere((e) => e.id == event.id);
    final List<EventoCultural> updated = List<EventoCultural>.from(eventsForList);
    if (index >= 0) {
      updated[index] = event;
    } else {
      // Insertar al inicio para dar feedback inmediato
      updated.insert(0, event);
    }
    eventsForList = updated;
    notifyListeners();
  }
}


