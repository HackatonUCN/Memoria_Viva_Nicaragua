/// Clase base para excepciones de aplicación
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => code != null 
      ? 'AppException[$code]: $message' 
      : 'AppException: $message';
}

/// Excepción para errores de base de datos
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
  });

  @override
  String toString() => code != null 
      ? 'DatabaseException[$code]: $message' 
      : 'DatabaseException: $message';
}

/// Excepción para errores de red
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
  });

  @override
  String toString() => code != null 
      ? 'NetworkException[$code]: $message' 
      : 'NetworkException: $message';
}

/// Excepción para errores de almacenamiento
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
  });

  @override
  String toString() => code != null 
      ? 'StorageException[$code]: $message' 
      : 'StorageException: $message';
}

/// Excepción para errores de validación
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
  });

  @override
  String toString() => code != null 
      ? 'ValidationException[$code]: $message' 
      : 'ValidationException: $message';
}
