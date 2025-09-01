import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para actualizar el rol de un usuario (solo admin)
class ActualizarRolUseCase {
  final IUserRepository _userRepository;

  ActualizarRolUseCase(this._userRepository);

  /// Actualiza el rol de un usuario
  /// 
  /// [adminId] - ID del administrador que realiza el cambio
  /// [userId] - ID del usuario a modificar
  /// [nuevoRol] - Nuevo rol a asignar
  /// 
  /// Throws:
  /// - [UserNotFoundException] si el usuario no existe
  /// - [AuthException] si el que ejecuta no es admin o hay otro error
  Future<void> execute({
    required String adminId,
    required String userId,
    required UserRole nuevoRol,
  }) async {
    try {
      // Verificar que quien ejecuta es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw AuthException('Solo los administradores pueden cambiar roles');
      }

      // Verificar que el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(userId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      await _userRepository.actualizarRol(
        userId: userId,
        nuevoRol: nuevoRol,
      );
    } catch (e) {
      if (e is UserNotFoundException || e is AuthException) {
        rethrow;
      }
      throw AuthException('Error al actualizar rol: $e');
    }
  }
}
