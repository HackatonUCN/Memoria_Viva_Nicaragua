import '../../entities/evento_cultural.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener sugerencias de eventos pendientes (solo lectura)
class ObtenerSugerenciasPendientesUseCase {
  final IEventoCulturalRepository _eventoRepository;

  ObtenerSugerenciasPendientesUseCase(this._eventoRepository);

  /// Obtiene todas las sugerencias en estado pendiente
  UseCaseResult<List<SugerenciaEvento>> execute() async {
    try {
      final data = await _eventoRepository.obtenerSugerenciasPendientes();
      return Success<List<SugerenciaEvento>, Failure>(data);
    } catch (e) {
      return FailureResult<List<SugerenciaEvento>, Failure>(mapExceptionToFailure(e));
    }
  }
}


