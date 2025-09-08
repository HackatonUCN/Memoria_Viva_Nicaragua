import '../../failures/exception_mapper.dart';
import '../../failures/failures.dart';
import '../../failures/result.dart';
import '../../repositories/relato_repository.dart';

/// Caso de uso para registrar un compartido de relato
class RegistrarCompartidoRelatoUseCase {
  final IRelatoRepository _relatoRepository;

  RegistrarCompartidoRelatoUseCase(this._relatoRepository);

  /// Incrementa el contador de compartidos del relato
  UseCaseResult<void> execute({required String relatoId}) async {
    try {
      await _relatoRepository.registrarCompartido(relatoId);
      return const Success<void, Failure>(null);
    } catch (e) {
      return FailureResult<void, Failure>(mapExceptionToFailure(e));
    }
  }
}


