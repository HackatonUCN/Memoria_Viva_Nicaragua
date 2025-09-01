import '../../entities/saber_popular.dart';
import '../../exceptions/saber_exception.dart';
import '../../repositories/saber_popular_repository.dart';

/// Caso de uso para obtener saberes populares con diferentes filtros
class ObtenerSaberesUseCase {
  final ISaberPopularRepository _saberRepository;

  ObtenerSaberesUseCase(this._saberRepository);

  /// Obtiene todos los saberes activos
  Future<List<SaberPopular>> execute() async {
    try {
      return await _saberRepository.obtenerSaberes();
    } catch (e) {
      throw SaberException('Error al obtener saberes: $e');
    }
  }

  /// Obtiene saberes por categoría
  Future<List<SaberPopular>> porCategoria(String categoriaId) async {
    try {
      return await _saberRepository.obtenerSaberesPorCategoria(categoriaId);
    } catch (e) {
      throw SaberException('Error al obtener saberes por categoría: $e');
    }
  }

  /// Obtiene saberes por autor
  Future<List<SaberPopular>> porAutor(String autorId) async {
    try {
      return await _saberRepository.obtenerSaberesPorAutor(autorId);
    } catch (e) {
      throw SaberException('Error al obtener saberes por autor: $e');
    }
  }

  /// Obtiene saberes por ubicación
  Future<List<SaberPopular>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      return await _saberRepository.obtenerSaberesPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
    } catch (e) {
      throw SaberException('Error al obtener saberes por ubicación: $e');
    }
  }

  /// Busca saberes por texto
  Future<List<SaberPopular>> buscar(String texto) async {
    try {
      return await _saberRepository.buscarSaberes(texto);
    } catch (e) {
      throw SaberException('Error al buscar saberes: $e');
    }
  }

  /// Stream para observar cambios en los saberes
  Stream<List<SaberPopular>> observe() {
    return _saberRepository.observarSaberes();
  }

  /// Stream para observar saberes por categoría
  Stream<List<SaberPopular>> observePorCategoria(String categoriaId) {
    return _saberRepository.observarSaberesPorCategoria(categoriaId);
  }
}