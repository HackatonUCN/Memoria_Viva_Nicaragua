import 'package:flutter/foundation.dart';

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

  Future<void> init() async {
    await _load();
  }

  Future<void> refresh() async => _load();

  void setSelectedCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _load();
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    notifyListeners();
    final res = await _useCases.carruselPorCategoria.execute(
      categoriaId: _selectedCategoryId,
    );
    res.when(
      success: (data) => eventsForCarousel = data,
      failure: (f) => error = f.message,
    );
    loading = false;
    notifyListeners();
  }
}


