import 'package:flutter/foundation.dart';
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

  Future<void> init({DateTimeRange? initialRange}) async {
    _visibleRange = initialRange;
    await _load();
  }

  Future<void> refresh() async => _load();

  void setSearchText(String text) {
    if (_searchText == text) return;
    _searchText = text;
    _load();
  }

  void setVisibleRange(DateTimeRange range) {
    final same = _visibleRange != null && _visibleRange!.start == range.start && _visibleRange!.end == range.end;
    if (same) return;
    _visibleRange = range;
    _load();
  }

  Future<void> _load() async {
    if (_visibleRange == null) return;
    loading = true;
    error = null;
    notifyListeners();
    final res = await _useCases.porRangoYBusqueda.execute(
      inicio: _visibleRange!.start,
      fin: _visibleRange!.end,
      texto: _searchText,
    );
    res.when(
      success: (data) => eventsForList = data,
      failure: (f) => error = f.message,
    );
    loading = false;
    notifyListeners();
  }
}


