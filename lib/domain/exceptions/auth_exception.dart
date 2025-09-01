/// Excepción base para errores de autenticación
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  AuthException(this.message, {this.code, this.value});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Email/contraseña inválidos
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException([String message = 'Credenciales inválidas'])
      : super(message, code: 'INVALID_CREDENTIALS');
}

/// Email ya existe
class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException([String message = 'El email ya está registrado'])
      : super(message, code: 'EMAIL_ALREADY_IN_USE');
}

/// Email no verificado
class EmailNotVerifiedException extends AuthException {
  EmailNotVerifiedException([String message = 'Email no verificado'])
      : super(message, code: 'EMAIL_NOT_VERIFIED');
}

/// Usuario no encontrado
class UserNotFoundException extends AuthException {
  UserNotFoundException([String message = 'Usuario no encontrado'])
      : super(message, code: 'USER_NOT_FOUND');
      
  factory UserNotFoundException.withId(String userId) {
    return UserNotFoundException('Usuario con ID $userId no encontrado');
  }
  
  factory UserNotFoundException.withEmail(String email) {
    return UserNotFoundException('Usuario con email $email no encontrado');
  }
}

/// Contraseña débil
class WeakPasswordException extends AuthException {
  WeakPasswordException([String message = 'La contraseña es muy débil'])
      : super(message, code: 'WEAK_PASSWORD');
      
  factory WeakPasswordException.withReason(String reason) {
    return WeakPasswordException(
      'Contraseña débil: $reason',

    );
  }
}

/// Error de red
class NetworkException extends AuthException {
  NetworkException([String message = 'Error de conexión'])
      : super(message, code: 'NETWORK_ERROR');
}

/// Sesión expirada
class SessionExpiredException extends AuthException {
  SessionExpiredException([String message = 'La sesión ha expirado'])
      : super(message, code: 'SESSION_EXPIRED');
}

/// Error de permisos
class InsufficientPermissionsException extends AuthException {
  InsufficientPermissionsException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'INSUFFICIENT_PERMISSIONS', value: value);
      
  factory InsufficientPermissionsException.requiredRole(String requiredRole) {
    return InsufficientPermissionsException(
      'Se requiere el rol $requiredRole para esta acción',
      code: 'ROLE_REQUIRED',
      value: {'requiredRole': requiredRole}
    );
  }
}

/// Cuenta desactivada
class AccountDisabledException extends AuthException {
  AccountDisabledException([String message = 'La cuenta ha sido desactivada'])
      : super(message, code: 'ACCOUNT_DISABLED');
}

/// Error de autenticación con Google
class GoogleAuthException extends AuthException {
  GoogleAuthException([String message = 'Error en la autenticación con Google'])
      : super(message, code: 'GOOGLE_AUTH_ERROR');
}