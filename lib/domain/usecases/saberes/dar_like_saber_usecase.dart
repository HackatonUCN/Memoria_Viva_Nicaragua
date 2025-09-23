import '../../repositories/saber_popular_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

class DarLikeSaberUseCase {
  final ISaberPopularRepository _repo;
  DarLikeSaberUseCase(this._repo);

  UseCaseResult<void> execute({required String saberId}) async {
    try {
      await _repo.darLike(saberId);
      return Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}

