import '../../repositories/saber_popular_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

class RegistrarCompartidoSaberUseCase {
  final ISaberPopularRepository _repo;
  RegistrarCompartidoSaberUseCase(this._repo);

  UseCaseResult<void> execute({required String saberId}) async {
    try {
      await _repo.registrarCompartido(saberId);
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}

