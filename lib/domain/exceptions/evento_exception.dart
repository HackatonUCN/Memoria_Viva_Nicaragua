/// Excepción base para errores relacionados con eventos culturales
class EventoException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  EventoException(this.message, {this.code, this.value});

  @override
  String toString() => 'EventoException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Evento no encontrado
class EventoNotFoundException extends EventoException {
  EventoNotFoundException([String message = 'Evento no encontrado'])
      : super(message, code: 'EVENTO_NOT_FOUND');
}

/// Error de permisos
class EventoPermissionException extends EventoException {
  EventoPermissionException([String message = 'No tienes permisos para esta acción'])
      : super(message, code: 'EVENTO_PERMISSION_DENIED');
}

/// Contenido inválido
class EventoInvalidContentException extends EventoException {
  EventoInvalidContentException([String message = 'El contenido del evento es inválido'])
      : super(message, code: 'EVENTO_INVALID_CONTENT');

  factory EventoInvalidContentException.fromValidation(String validationError) {
    return EventoInvalidContentException('Contenido inválido: $validationError');
  }
}

/// Error de fechas
class EventoInvalidDateException extends EventoException {
  EventoInvalidDateException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'EVENTO_INVALID_DATE', value: value);
      
  factory EventoInvalidDateException.fechaInicioMayorQueFin() {
    return EventoInvalidDateException(
      'La fecha de inicio debe ser anterior a la fecha de fin',
      code: 'EVENTO_FECHA_INICIO_MAYOR'
    );
  }
  
  factory EventoInvalidDateException.fechaPasada() {
    return EventoInvalidDateException(
      'La fecha del evento no puede ser en el pasado',
      code: 'EVENTO_FECHA_PASADA'
    );
  }
}

/// Evento duplicado
class EventoDuplicadoException extends EventoException {
  EventoDuplicadoException([String message = 'Ya existe un evento similar en esas fechas'])
      : super(message, code: 'EVENTO_DUPLICADO');
}

/// Evento ya eliminado
class EventoAlreadyDeletedException extends EventoException {
  EventoAlreadyDeletedException([String message = 'El evento ya fue eliminado'])
      : super(message, code: 'EVENTO_ALREADY_DELETED');
}

/// Evento no eliminado (para restaurar)
class EventoNotDeletedException extends EventoException {
  EventoNotDeletedException([String message = 'El evento no está eliminado'])
      : super(message, code: 'EVENTO_NOT_DELETED');
}

/// Sugerencia no encontrada
class SugerenciaNotFoundException extends EventoException {
  SugerenciaNotFoundException([String message = 'Sugerencia de evento no encontrada'])
      : super(message, code: 'SUGERENCIA_NOT_FOUND');
}

/// Error al procesar la sugerencia
class SugerenciaProcessException extends EventoException {
  SugerenciaProcessException([String message = 'Error al procesar la sugerencia'])
      : super(message, code: 'SUGERENCIA_PROCESS_ERROR');
}

/// Error de ubicación en evento
class EventoLocationException extends EventoException {
  EventoLocationException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'EVENTO_LOCATION_ERROR', value: value);
      
  factory EventoLocationException.ubicacionRequerida() {
    return EventoLocationException(
      'La ubicación es requerida para el evento',
      code: 'EVENTO_UBICACION_REQUERIDA'
    );
  }
  
  factory EventoLocationException.coordenadasInvalidas() {
    return EventoLocationException(
      'Las coordenadas proporcionadas son inválidas',
      code: 'EVENTO_COORDENADAS_INVALIDAS'
    );
  }
  
  factory EventoLocationException.fromError(String error) {
    return EventoLocationException(
      'Error de ubicación: $error',
      code: 'EVENTO_UBICACION_ERROR',
      value: {'error': error}
    );
  }
}

/// Error de multimedia en evento
class EventoMediaException extends EventoException {
  EventoMediaException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'EVENTO_MEDIA_ERROR', value: value);
      
  factory EventoMediaException.formatoInvalido(String url) {
    return EventoMediaException(
      'Formato de archivo inválido: $url',
      code: 'EVENTO_MEDIA_FORMATO_INVALIDO',
      value: {'url': url}
    );
  }
  
  factory EventoMediaException.tamanoExcedido(String url) {
    return EventoMediaException(
      'El archivo excede el tamaño máximo permitido: $url',
      code: 'EVENTO_MEDIA_TAMANO_EXCEDIDO',
      value: {'url': url}
    );
  }
  
  factory EventoMediaException.fromError(String error) {
    return EventoMediaException(
      'Error multimedia: $error',
      code: 'EVENTO_MEDIA_ERROR_GENERAL',
      value: {'error': error}
    );
  }
}