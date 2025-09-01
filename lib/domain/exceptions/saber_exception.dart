/// Excepción base para errores relacionados con saberes populares
class SaberException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  SaberException(this.message, {this.code, this.value});

  @override
  String toString() => 'SaberException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Saber popular no encontrado
class SaberNotFoundException extends SaberException {
  SaberNotFoundException([String message = 'Saber popular no encontrado'])
      : super(message, code: 'SABER_NOT_FOUND');
}

/// Error de permisos
class SaberPermissionException extends SaberException {
  SaberPermissionException([String message = 'No tienes permisos para esta acción'])
      : super(message, code: 'SABER_PERMISSION_DENIED');
}

/// Contenido inválido
class SaberInvalidContentException extends SaberException {
  SaberInvalidContentException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'SABER_INVALID_CONTENT', value: value);
      
  factory SaberInvalidContentException.fromValidation(String validationError) {
    return SaberInvalidContentException(
      'Contenido inválido: $validationError',
      code: 'SABER_VALIDATION_ERROR',
      value: {'error': validationError}
    );
  }
  
  factory SaberInvalidContentException.tituloInvalido(String razon) {
    return SaberInvalidContentException(
      'Título inválido: $razon',
      code: 'SABER_TITULO_INVALIDO',
      value: {'razon': razon}
    );
  }
  
  factory SaberInvalidContentException.contenidoInvalido(String razon) {
    return SaberInvalidContentException(
      'Contenido inválido: $razon',
      code: 'SABER_CONTENIDO_INVALIDO',
      value: {'razon': razon}
    );
  }
}

/// Error de multimedia
class SaberMediaException extends SaberException {
  SaberMediaException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'SABER_MEDIA_ERROR', value: value);
      
  factory SaberMediaException.formatoInvalido(String url) {
    return SaberMediaException(
      'Formato de imagen inválido: $url',
      code: 'SABER_MEDIA_FORMATO_INVALIDO',
      value: {'url': url}
    );
  }
  
  factory SaberMediaException.tamanoExcedido(String url) {
    return SaberMediaException(
      'La imagen excede el tamaño máximo permitido: $url',
      code: 'SABER_MEDIA_TAMANO_EXCEDIDO',
      value: {'url': url}
    );
  }
  
  factory SaberMediaException.limiteExcedido() {
    return SaberMediaException(
      'Se ha excedido el límite de imágenes permitidas',
      code: 'SABER_MEDIA_LIMITE_EXCEDIDO'
    );
  }
  
  factory SaberMediaException.fromError(String error) {
    return SaberMediaException(
      'Error multimedia: $error',
      code: 'SABER_MEDIA_ERROR_GENERAL',
      value: {'error': error}
    );
  }
}

/// Error de ubicación
class SaberLocationException extends SaberException {
  SaberLocationException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'SABER_LOCATION_ERROR', value: value);
      
  factory SaberLocationException.coordenadasInvalidas() {
    return SaberLocationException(
      'Las coordenadas proporcionadas son inválidas',
      code: 'SABER_COORDENADAS_INVALIDAS'
    );
  }
  
  factory SaberLocationException.fromError(String error) {
    return SaberLocationException(
      'Error de ubicación: $error',
      code: 'SABER_UBICACION_ERROR',
      value: {'error': error}
    );
  }
}

/// Error de moderación
class SaberModerationException extends SaberException {
  SaberModerationException([String message = 'Error en la moderación del saber'])
      : super(message, code: 'SABER_MODERATION_ERROR');
}

/// Saber ya reportado
class SaberAlreadyReportedException extends SaberException {
  SaberAlreadyReportedException([String message = 'Ya has reportado este saber'])
      : super(message, code: 'SABER_ALREADY_REPORTED');
}

/// Saber duplicado
class SaberDuplicadoException extends SaberException {
  SaberDuplicadoException([String message = 'Ya existe un saber similar'])
      : super(message, code: 'SABER_DUPLICADO');
}

/// Saber ya eliminado
class SaberAlreadyDeletedException extends SaberException {
  SaberAlreadyDeletedException([String message = 'El saber ya fue eliminado'])
      : super(message, code: 'SABER_ALREADY_DELETED');
}

/// Saber no eliminado (para restaurar)
class SaberNotDeletedException extends SaberException {
  SaberNotDeletedException([String message = 'El saber no está eliminado'])
      : super(message, code: 'SABER_NOT_DELETED');
}

/// Saber popular exception
class SaberPopularException extends SaberException {
  SaberPopularException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'SABER_POPULAR_ERROR', value: value);
}