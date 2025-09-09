import '../../failures/exception_mapper.dart';
import '../../failures/failures.dart';
import '../../failures/result.dart';
import '../../repositories/relato_repository.dart';

/// Caso de uso para alternar (toggle) el like de un relato de forma idempotente
class ToggleLikeRelatoUseCase {
  final IRelatoRepository _relatoRepository;

  ToggleLikeRelatoUseCase(this._relatoRepository);

  /// Alterna el like para [userId] en el relato [relatoId].
  /// Retorna true si termina con like activo; false si queda sin like.
  UseCaseResult<bool> execute({required String relatoId, required String userId}) async {
    try {
      final isLiked = await _relatoRepository.toggleLike(id: relatoId, userId: userId);
      return Success<bool, Failure>(isLiked);
    } catch (e) {
      return FailureResult<bool, Failure>(mapExceptionToFailure(e));
    }
  }
}


