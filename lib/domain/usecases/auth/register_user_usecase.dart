import '../../entities/user.dart';
import '../../exceptions/auth_exception.dart';
import '../../repositories/user_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para registrar un nuevo usuario
class RegisterUserUseCase {
  final IUserRepository _userRepository;

  RegisterUserUseCase(this._userRepository);

  /// Registra un nuevo usuario con email y contraseña
  /// 
  /// Throws:
  /// - [EmailAlreadyInUseException] si el email ya está registrado
  /// - [WeakPasswordException] si la contraseña es débil
  /// - [NetworkException] si hay problemas de conexión
  UseCaseResult<User> execute({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      // Verificar si el email ya existe
      final emailExiste = await _userRepository.verificarEmailExiste(email);
      if (emailExiste) {
        throw EmailAlreadyInUseException();
      }

      // Registrar usuario
      final user = await _userRepository.registrarEmail(
        email: email,
        password: password,
        nombre: nombre,
      );

      // Enviar email de verificación
      await _userRepository.enviarEmailVerificacion();

      return Success<User, Failure>(user);
    } catch (e) {
      if (e is EmailAlreadyInUseException) {
        return FailureResult<User, Failure>(mapExceptionToFailure(e));
      }
      if (e.toString().contains('weak-password')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(WeakPasswordException()));
      }
      if (e.toString().contains('network-error')) {
        return FailureResult<User, Failure>(mapExceptionToFailure(NetworkException()));
      }
      return FailureResult<User, Failure>(mapExceptionToFailure(AuthException('Error al registrar usuario: $e')));
    }
  }
}
