import '../../failures/exception_mapper.dart';
import '../../failures/failures.dart';
import '../../failures/result.dart';
import '../../repositories/relato_repository.dart';

/// Caso de uso para dar like a un relato
class DarLikeRelatoUseCase {
  final IRelatoRepository _relatoRepository;

  DarLikeRelatoUseCase(this._relatoRepository);

  /// Incrementa el contador de likes del relato
  UseCaseResult<void> execute({required String relatoId}) async {
    try {
      await _relatoRepository.darLike(relatoId);
      return const Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}


