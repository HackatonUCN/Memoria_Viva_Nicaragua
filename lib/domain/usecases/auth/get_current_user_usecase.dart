import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para obtener el usuario actual
class GetCurrentUserUseCase {
  final IUserRepository _userRepository;

  GetCurrentUserUseCase(this._userRepository);

  /// Obtiene el usuario actualmente autenticado
  /// 
  /// Returns null si no hay usuario autenticado
  /// 
  /// Throws:
  /// - [AuthException] si hay algún error durante el proceso
  Future<User?> execute() async {
    try {
      return await _userRepository.obtenerUsuarioActual();
    } catch (e) {
      throw AuthException('Error al obtener usuario actual: $e');
    }
  }

  /// Stream que emite cambios en el usuario actual
  Stream<User?> observe() {
    return _userRepository.observarUsuarioActual();
  }
}
