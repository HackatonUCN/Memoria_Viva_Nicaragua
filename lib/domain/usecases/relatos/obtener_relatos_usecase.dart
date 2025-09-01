import '../../entities/relato.dart';
import '../../repositories/relato_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener relatos con diferentes filtros
class ObtenerRelatosUseCase {
  final IRelatoRepository _relatoRepository;

  ObtenerRelatosUseCase(this._relatoRepository);

  /// Obtiene todos los relatos activos
  UseCaseResult<List<Relato>> execute() async {
    try {
      final data = await _relatoRepository.obtenerRelatos();
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene relatos por categoría
  UseCaseResult<List<Relato>> porCategoria(String categoriaId) async {
    try {
      final data = await _relatoRepository.obtenerRelatosPorCategoria(categoriaId);
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene relatos por autor
  UseCaseResult<List<Relato>> porAutor(String autorId) async {
    try {
      final data = await _relatoRepository.obtenerRelatosPorAutor(autorId);
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene relatos por ubicación
  UseCaseResult<List<Relato>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      final data = await _relatoRepository.obtenerRelatosPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene relatos cercanos a una ubicación
  UseCaseResult<List<Relato>> cercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    try {
      final data = await _relatoRepository.obtenerRelatosCercanos(
        latitud: latitud,
        longitud: longitud,
        radioKm: radioKm,
      );
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Busca relatos por texto
  UseCaseResult<List<Relato>> buscar(String texto) async {
    try {
      final data = await _relatoRepository.buscarRelatos(texto);
      return Success<List<Relato>, Failure>(data);
    } catch (e) {
      return FailureResult<List<Relato>, Failure>(mapExceptionToFailure(e));
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
