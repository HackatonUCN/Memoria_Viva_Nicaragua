import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../../domain/entities/saber_popular.dart';
import '../../../domain/factories/usecases.dart';

/// Provider para manejar la pantalla de Saberes
/// - Estado: lista de saberes, filtros, búsqueda
class SaberesProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve().saberes;

  // Estado de carga
  bool loading = false;
  String? error;

  // Listas de saberes
  List<SaberPopular> saberes = [];
  List<SaberPopular> saberesDestacados = [];

  // Filtros y búsqueda
  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  String _selectedFilter = 'reciente'; // reciente, populares, me_gusta, mis_saberes
  String get selectedFilter => _selectedFilter;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  // Debounce para búsqueda
  Timer? _searchDebounce;

  // Cache para optimización
  final Map<String, List<SaberPopular>> _cacheByFilter = {};

  Future<void> init() async {
    await Future.wait([
      _loadSaberes(),
      _loadSaberesDestacados(),
    ]);
  }

  Future<void> refresh() async {
    _cacheByFilter.clear();
    await init();
  }

  // Cargar saberes principales
  Future<void> _loadSaberes({bool forceRemote = false}) async {
    final String cacheKey = '$_selectedFilter-$_selectedCategoryId-$_searchQuery';
    
    if (!forceRemote && _cacheByFilter.containsKey(cacheKey)) {
      final cached = _cacheByFilter[cacheKey]!;
      if (!listEquals(cached, saberes)) {
        saberes = List<SaberPopular>.from(cached);
        notifyListeners();
      }
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      // TODO: Implementar llamada real al usecase
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data por ahora
      saberes = _generateMockSaberes();
      _cacheByFilter[cacheKey] = List<SaberPopular>.from(saberes);
      
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  // Cargar saberes destacados para el carrusel
  Future<void> _loadSaberesDestacados() async {
    try {
      // TODO: Implementar llamada real al usecase
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mock data por ahora
      saberesDestacados = _generateMockSaberesDestacados();
      notifyListeners();
    } catch (e) {
      // Error silencioso para destacados
      debugPrint('Error loading saberes destacados: $e');
    }
  }

  // Cambiar filtro
  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _loadSaberes();
  }

  // Cambiar categoría
  void setCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _loadSaberes();
  }

  // Búsqueda con debounce
  void setSearchQuery(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadSaberes();
    });
  }

  // Generar mock data
  List<SaberPopular> _generateMockSaberes() {
    return [
      SaberPopular(
        id: '1',
        titulo: 'Receta tradicional de Gallo Pinto',
        contenido: 'El gallo pinto es el plato más tradicional de Nicaragua. Se prepara con arroz, frijoles rojos, cebolla, chile dulce y especias que le dan su sabor característico...',
        categoriaId: 'saber_recetas',
        categoriaNombre: 'Recetas',
        autorId: 'user1',
        autorNombre: 'María González',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 2)),
        etiquetas: ['cocina', 'tradicional', 'desayuno'],
        multimedia: [], // Sin multimedia por ahora
        likes: 24,
        compartidos: 8,
      ),
      SaberPopular(
        id: '2',
        titulo: 'Artesanía en barro: técnicas ancestrales',
        contenido: 'Las técnicas de alfarería han pasado de generación en generación. Aquí te enseñamos cómo preparar el barro, dar forma a las piezas y aplicar los acabados tradicionales...',
        categoriaId: 'saber_artesanias',
        categoriaNombre: 'Artesanías',
        autorId: 'user2',
        autorNombre: 'Carlos Mendoza',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 5)),
        etiquetas: ['artesanía', 'barro', 'ancestral'],
        multimedia: [], // Sin multimedia por ahora
        likes: 18,
        compartidos: 5,
      ),
      SaberPopular(
        id: '3',
        titulo: 'Remedios caseros con plantas medicinales',
        contenido: 'Nuestros abuelos conocían el poder curativo de las plantas. La manzanilla para el estómago, el eucalipto para la gripe, la sábila para la piel...',
        categoriaId: 'saber_medicina_tradicional',
        categoriaNombre: 'Medicina Tradicional',
        autorId: 'user3',
        autorNombre: 'Doña Carmen',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 1)),
        etiquetas: ['medicina', 'plantas', 'remedios'],
        multimedia: [], // Sin multimedia por ahora
        likes: 32,
        compartidos: 12,
      ),
      SaberPopular(
        id: '4',
        titulo: 'Dichos y refranes nicaragüenses',
        contenido: '"Al que madruga, Dios le ayuda", "Más vale pájaro en mano que cien volando". Los refranes nos enseñan sabiduría popular acumulada por generaciones...',
        categoriaId: 'saber_dichos_refranes',
        categoriaNombre: 'Dichos y Refranes',
        autorId: 'user4',
        autorNombre: 'Don Pedro',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 3)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 3)),
        etiquetas: ['refranes', 'sabiduría', 'cultura'],
        multimedia: [], // Sin multimedia por ahora
        likes: 15,
        compartidos: 6,
      ),
    ];
  }

  List<SaberPopular> _generateMockSaberesDestacados() {
    return [
      SaberPopular(
        id: 'dest1',
        titulo: 'Nacatamal: el rey de la cocina nica',
        contenido: 'Aprende a preparar el auténtico nacatamal nicaragüense con todos sus secretos...',
        categoriaId: 'saber_recetas',
        categoriaNombre: 'Recetas',
        autorId: 'chef1',
        autorNombre: 'Chef Alejandra',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 1)),
        multimedia: [], // Sin multimedia por ahora
        likes: 89,
        compartidos: 34,
      ),
      SaberPopular(
        id: 'dest2',
        titulo: 'Bailes folklóricos de Nicaragua',
        contenido: 'Descubre los pasos tradicionales del Palo de Mayo, la Danza de las Inditas...',
        categoriaId: 'saber_musica_danza',
        categoriaNombre: 'Música y Danza',
        autorId: 'dancer1',
        autorNombre: 'María del Socorro',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 4)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 4)),
        multimedia: [], // Sin multimedia por ahora
        likes: 67,
        compartidos: 23,
      ),
      SaberPopular(
        id: 'dest3',
        titulo: 'Hamacas tejidas a mano',
        contenido: 'El arte del tejido de hamacas es una tradición que se mantiene viva...',
        categoriaId: 'saber_artesanias',
        categoriaNombre: 'Artesanías',
        autorId: 'artisan1',
        autorNombre: 'Doña Rosa',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 6)),
        fechaActualizacion: DateTime.now().subtract(const Duration(days: 6)),
        multimedia: [], // Sin multimedia por ahora
        likes: 45,
        compartidos: 18,
      ),
    ];
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
