/// Excepción base para errores relacionados con usuarios
class UserException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  UserException(this.message, {this.code, this.data});

  @override
  String toString() => 'UserException: $message${code != null ? ' (Code: $code)' : ''}';

  /// Usuario no encontrado
  factory UserException.noEncontrado({String? userId, String? email}) {
    final id = userId != null ? 'ID: $userId' : '';
    final mail = email != null ? 'Email: $email' : '';
    final detail = [id, mail].where((s) => s.isNotEmpty).join(', ');
    
    return UserException(
      'Usuario no encontrado${detail.isNotEmpty ? ' ($detail)' : ''}',
      code: 'user-not-found',
      data: {'userId': userId, 'email': email},
    );
  }

  /// Permisos insuficientes
  factory UserException.sinPermisos({required String accion, String? rolRequerido}) {
    return UserException(
      'No tienes permisos suficientes para $accion${rolRequerido != null ? ' (Requiere: $rolRequerido)' : ''}',
      code: 'insufficient-permissions',
      data: {'accion': accion, 'rolRequerido': rolRequerido},
    );
  }

  /// Usuario ya existe
  factory UserException.yaExiste({required String email}) {
    return UserException(
      'Ya existe un usuario con el email: $email',
      code: 'user-already-exists',
      data: {'email': email},
    );
  }

  /// Usuario inactivo
  factory UserException.inactivo({required String userId}) {
    return UserException(
      'La cuenta de usuario está inactiva (ID: $userId)',
      code: 'user-inactive',
      data: {'userId': userId},
    );
  }

  /// Error al actualizar usuario
  factory UserException.errorActualizacion({required String userId, required String detalle}) {
    return UserException(
      'Error al actualizar usuario: $detalle',
      code: 'update-failed',
      data: {'userId': userId, 'detalle': detalle},
    );
  }
}
