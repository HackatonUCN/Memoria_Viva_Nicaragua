import '../../failures/exception_mapper.dart';
import '../../failures/failures.dart';
import '../../failures/result.dart';
import '../../repositories/relato_repository.dart';

/// Caso de uso para dar like a un relato (obsoleto). Usar ToggleLikeRelatoUseCase.
class DarLikeRelatoUseCase {
  final IRelatoRepository _relatoRepository;

  DarLikeRelatoUseCase(this._relatoRepository);

  /// Incrementa el contador de likes del relato
  UseCaseResult<void> execute({required String relatoId}) async {
    try {
      // Mantener compatibilidad si es usado en algún lugar (incremento simple)
      await _relatoRepository.toggleLike(id: relatoId, userId: '');
      return const Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}


