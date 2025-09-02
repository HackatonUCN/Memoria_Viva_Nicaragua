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
  InvalidCredentialsException([super.message = 'Credenciales inválidas'])
      : super(code: 'INVALID_CREDENTIALS');
}

/// Email ya existe
class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException([super.message = 'El email ya está registrado'])
      : super(code: 'EMAIL_ALREADY_IN_USE');
}

/// Email no verificado
class EmailNotVerifiedException extends AuthException {
  EmailNotVerifiedException([super.message = 'Email no verificado'])
      : super(code: 'EMAIL_NOT_VERIFIED');
}

/// Usuario no encontrado
class UserNotFoundException extends AuthException {
  UserNotFoundException([super.message = 'Usuario no encontrado'])
      : super(code: 'USER_NOT_FOUND');
      
  factory UserNotFoundException.withId(String userId) {
    return UserNotFoundException('Usuario con ID $userId no encontrado');
  }
  
  factory UserNotFoundException.withEmail(String email) {
    return UserNotFoundException('Usuario con email $email no encontrado');
  }
}

/// Contraseña débil
class WeakPasswordException extends AuthException {
  WeakPasswordException([super.message = 'La contraseña es muy débil'])
      : super(code: 'WEAK_PASSWORD');
      
  factory WeakPasswordException.withReason(String reason) {
    return WeakPasswordException(
      'Contraseña débil: $reason',

    );
  }
}

/// Error de red
class NetworkException extends AuthException {
  NetworkException([super.message = 'Error de conexión'])
      : super(code: 'NETWORK_ERROR');
}

/// Sesión expirada
class SessionExpiredException extends AuthException {
  SessionExpiredException([super.message = 'La sesión ha expirado'])
      : super(code: 'SESSION_EXPIRED');
}

/// Error de permisos
class InsufficientPermissionsException extends AuthException {
  InsufficientPermissionsException(super.message, {String? code, super.value})
      : super(code: code ?? 'INSUFFICIENT_PERMISSIONS');
      
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
  AccountDisabledException([super.message = 'La cuenta ha sido desactivada'])
      : super(code: 'ACCOUNT_DISABLED');
}

/// Error de autenticación con Google
class GoogleAuthException extends AuthException {
  GoogleAuthException([super.message = 'Error en la autenticación con Google'])
      : super(code: 'GOOGLE_AUTH_ERROR');
}