import '../../entities/relato.dart';
import '../../exceptions/relato_exception.dart';
import '../../repositories/relato_repository.dart';

/// Caso de uso para obtener relatos con diferentes filtros
class ObtenerRelatosUseCase {
  final IRelatoRepository _relatoRepository;

  ObtenerRelatosUseCase(this._relatoRepository);

  /// Obtiene todos los relatos activos
  Future<List<Relato>> execute() async {
    try {
      return await _relatoRepository.obtenerRelatos();
    } catch (e) {
      throw RelatoException('Error al obtener relatos: $e');
    }
  }

  /// Obtiene relatos por categoría
  Future<List<Relato>> porCategoria(String categoriaId) async {
    try {
      return await _relatoRepository.obtenerRelatosPorCategoria(categoriaId);
    } catch (e) {
      throw RelatoException('Error al obtener relatos por categoría: $e');
    }
  }

  /// Obtiene relatos por autor
  Future<List<Relato>> porAutor(String autorId) async {
    try {
      return await _relatoRepository.obtenerRelatosPorAutor(autorId);
    } catch (e) {
      throw RelatoException('Error al obtener relatos por autor: $e');
    }
  }

  /// Obtiene relatos por ubicación
  Future<List<Relato>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      return await _relatoRepository.obtenerRelatosPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
    } catch (e) {
      throw RelatoException('Error al obtener relatos por ubicación: $e');
    }
  }

  /// Obtiene relatos cercanos a una ubicación
  Future<List<Relato>> cercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    try {
      return await _relatoRepository.obtenerRelatosCercanos(
        latitud: latitud,
        longitud: longitud,
        radioKm: radioKm,
      );
    } catch (e) {
      throw RelatoException('Error al obtener relatos cercanos: $e');
    }
  }

  /// Busca relatos por texto
  Future<List<Relato>> buscar(String texto) async {
    try {
      return await _relatoRepository.buscarRelatos(texto);
    } catch (e) {
      throw RelatoException('Error al buscar relatos: $e');
    }
  }

  /// Stream para observar cambios en los relatos
  Stream<List<Relato>> observe() {
    return _relatoRepository.observarRelatos();
  }

  /// Stream para observar relatos por categoría
  Stream<List<Relato>> observePorCategoria(String categoriaId) {
    return _relatoRepository.observarRelatosPorCategoria(categoriaId);
  }
}
