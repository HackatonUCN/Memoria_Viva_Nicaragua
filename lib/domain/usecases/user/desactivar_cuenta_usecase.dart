import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para desactivar una cuenta de usuario
class DesactivarCuentaUseCase {
  final IUserRepository _userRepository;

  DesactivarCuentaUseCase(this._userRepository);

  /// Desactiva la cuenta de un usuario
  /// 
  /// [adminId] - ID del admin si es una acción administrativa (opcional)
  /// [userId] - ID del usuario a desactivar
  /// 
  /// Throws:
  /// - [UserNotFoundException] si el usuario no existe
  /// - [AuthException] si hay algún error durante el proceso
  Future<void> execute({
    String? adminId,
    required String userId,
  }) async {
    try {
      // Si es acción administrativa, verificar que sea admin
      if (adminId != null) {
        final admin = await _userRepository.obtenerUsuarioPorId(adminId);
        if (admin?.rol != UserRole.admin) {
          throw AuthException('Solo los administradores pueden desactivar cuentas de otros usuarios');
        }
      }

      // Verificar que el usuario existe
      final usuario = await _userRepository.obtenerUsuarioPorId(userId);
      if (usuario == null) {
        throw UserNotFoundException();
      }

      // No permitir desactivar el último admin
      if (usuario.rol == UserRole.admin) {
        final admins = await _userRepository.obtenerUsuariosPorRol(UserRole.admin);
        if (admins.length <= 1) {
          throw AuthException('No se puede desactivar el último administrador');
        }
      }

      await _userRepository.desactivarCuenta(userId);
    } catch (e) {
      if (e is UserNotFoundException || e is AuthException) {
        rethrow;
      }
      throw AuthException('Error al desactivar cuenta: $e');
    }
  }
}
