import '../../entities/saber_popular.dart';
import '../../repositories/saber_popular_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener saberes populares con diferentes filtros
class ObtenerSaberesUseCase {
  final ISaberPopularRepository _saberRepository;

  ObtenerSaberesUseCase(this._saberRepository);

  /// Obtiene todos los saberes activos
  UseCaseResult<List<SaberPopular>> execute() async {
    try {
      final data = await _saberRepository.obtenerSaberes();
      return Success<List<SaberPopular>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SaberPopular>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene saberes por categoría
  UseCaseResult<List<SaberPopular>> porCategoria(String categoriaId) async {
    try {
      final data = await _saberRepository.obtenerSaberesPorCategoria(categoriaId);
      return Success<List<SaberPopular>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SaberPopular>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene saberes por autor
  UseCaseResult<List<SaberPopular>> porAutor(String autorId) async {
    try {
      final data = await _saberRepository.obtenerSaberesPorAutor(autorId);
      return Success<List<SaberPopular>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SaberPopular>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene saberes por ubicación
  UseCaseResult<List<SaberPopular>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      final data = await _saberRepository.obtenerSaberesPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
      return Success<List<SaberPopular>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SaberPopular>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Busca saberes por texto
  UseCaseResult<List<SaberPopular>> buscar(String texto) async {
    try {
      final data = await _saberRepository.buscarSaberes(texto);
      return Success<List<SaberPopular>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SaberPopular>, Failure>(mapExceptionToFailure(e));
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