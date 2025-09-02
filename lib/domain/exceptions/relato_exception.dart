/// Excepción base para errores relacionados con relatos
class RelatoException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  RelatoException(this.message, {this.code, this.value});

  @override
  String toString() => 'RelatoException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Relato no encontrado
class RelatoNotFoundException extends RelatoException {
  RelatoNotFoundException([super.message = 'Relato no encontrado'])
      : super(code: 'RELATO_NOT_FOUND');
}

/// Error de permisos
class RelatoPermissionException extends RelatoException {
  RelatoPermissionException([super.message = 'No tienes permisos para esta acción'])
      : super(code: 'RELATO_PERMISSION_DENIED');
}

/// Contenido inválido
class RelatoInvalidContentException extends RelatoException {
  RelatoInvalidContentException([super.message = 'El contenido del relato es inválido'])
      : super(code: 'RELATO_INVALID_CONTENT');
      
  factory RelatoInvalidContentException.fromValidation(String validationError) {
    return RelatoInvalidContentException('Contenido inválido: $validationError');
  }
  
  factory RelatoInvalidContentException.tituloInvalido(String razon) {
    return RelatoInvalidContentException('Título inválido: $razon');
  }
  
  factory RelatoInvalidContentException.contenidoInvalido(String razon) {
    return RelatoInvalidContentException('Contenido inválido: $razon');
  }
  
  factory RelatoInvalidContentException.etiquetasInvalidas(String razon) {
    return RelatoInvalidContentException('Etiquetas inválidas: $razon');
  }
}

/// Error de multimedia
class RelatoMediaException extends RelatoException {
  RelatoMediaException([super.message = 'Error al procesar archivos multimedia'])
      : super(code: 'RELATO_MEDIA_ERROR');
      
  factory RelatoMediaException.formatoInvalido(String url) {
    return RelatoMediaException('Formato de archivo inválido: $url');
  }
  
  factory RelatoMediaException.tamanoExcedido(String url) {
    return RelatoMediaException('El archivo excede el tamaño máximo permitido: $url');
  }
  
  factory RelatoMediaException.limiteExcedido() {
    return RelatoMediaException('Se ha excedido el límite de archivos multimedia permitidos');
  }
  
  factory RelatoMediaException.fromError(String error) {
    return RelatoMediaException('Error multimedia: $error');
  }
}

/// Error de ubicación
class RelatoLocationException extends RelatoException {
  RelatoLocationException([super.message = 'Error con la ubicación del relato'])
      : super(code: 'RELATO_LOCATION_ERROR');
      
  factory RelatoLocationException.coordenadasInvalidas() {
    return RelatoLocationException('Las coordenadas proporcionadas son inválidas');
  }
  
  factory RelatoLocationException.fromError(String error) {
    return RelatoLocationException('Error de ubicación: $error');
  }
}

/// Error de moderación
class RelatoModerationException extends RelatoException {
  RelatoModerationException([super.message = 'Error en la moderación del relato'])
      : super(code: 'RELATO_MODERATION_ERROR');
      
  factory RelatoModerationException.estadoInvalido(String estado) {
    return RelatoModerationException('Estado de moderación inválido: $estado');
  }
}

/// Relato ya reportado
class RelatoAlreadyReportedException extends RelatoException {
  RelatoAlreadyReportedException([super.message = 'Ya has reportado este relato'])
      : super(code: 'RELATO_ALREADY_REPORTED');
}

/// Relato ya eliminado
class RelatoAlreadyDeletedException extends RelatoException {
  RelatoAlreadyDeletedException([super.message = 'El relato ya fue eliminado'])
      : super(code: 'RELATO_ALREADY_DELETED');
}