import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../exceptions/relato_exception.dart';
import '../../repositories/relato_repository.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para eliminar un relato (soft delete)
class EliminarRelatoUseCase {
  final IRelatoRepository _relatoRepository;
  final IUserRepository _userRepository;

  EliminarRelatoUseCase(
    this._relatoRepository,
    this._userRepository,
  );

  /// Elimina un relato (soft delete)
  /// 
  /// [usuarioId] - ID del usuario que intenta eliminar
  /// [relatoId] - ID del relato a eliminar
  /// 
  /// Throws:
  /// - [RelatoNotFoundException] si el relato no existe
  /// - [RelatoPermissionException] si no tiene permisos
  /// - [RelatoAlreadyDeletedException] si ya está eliminado
  /// - [RelatoException] para otros errores
  UseCaseResult<void> execute({
    required String usuarioId,
    required String relatoId,
  }) async {
    try {
      // Verificar que el relato existe
      final relato = await _relatoRepository.obtenerRelatoPorId(relatoId);
      if (relato == null) {
        throw RelatoNotFoundException();
      }

      // Verificar que no esté ya eliminado
      if (relato.eliminado) {
        throw RelatoAlreadyDeletedException();
      }

      // Verificar permisos
      final usuario = await _userRepository.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // Solo el autor o un admin pueden eliminar
      if (relato.autorId != usuarioId && usuario.rol != UserRole.admin) {
        throw RelatoPermissionException(
          'Solo el autor o un administrador pueden eliminar este relato'
        );
      }

      // Eliminar el relato (soft delete)
      await _relatoRepository.eliminarRelato(relatoId);

      // Actualizar estadísticas del autor
      final autor = await _userRepository.obtenerUsuarioPorId(relato.autorId);
      if (autor != null) {
        await _userRepository.actualizarEstadisticas(
          userId: relato.autorId,
          relatosPublicados: autor.relatosPublicados - 1,
        );
      }
      return Success<void, Failure>(null);
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      return FailureResult<void, Failure>(failure);
    }
  }
}
