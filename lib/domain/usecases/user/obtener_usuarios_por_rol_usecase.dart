import '../../entities/user.dart';
import '../../enums/roles_usuario.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para obtener usuarios filtrados por rol
class ObtenerUsuariosPorRolUseCase {
  final IUserRepository _userRepository;

  ObtenerUsuariosPorRolUseCase(this._userRepository);

  /// Obtiene usuarios por rol
  /// 
  /// [adminId] - ID del administrador que solicita la información
  /// [rol] - Rol a filtrar
  /// 
  /// Throws:
  /// - [AuthException] si el que ejecuta no es admin o hay otro error
  Future<List<User>> execute({
    required String adminId,
    required UserRole rol,
  }) async {
    try {
      // Verificar que quien ejecuta es admin
      final admin = await _userRepository.obtenerUsuarioPorId(adminId);
      if (admin?.rol != UserRole.admin) {
        throw AuthException('Solo los administradores pueden listar usuarios por rol');
      }

      return await _userRepository.obtenerUsuariosPorRol(rol);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Error al obtener usuarios por rol: $e');
    }
  }
}
