/// Excepción base para errores relacionados con juegos
class JuegoException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  JuegoException(this.message, {this.code, this.value});

  @override
  String toString() => 'JuegoException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Juego no encontrado
class JuegoNotFoundException extends JuegoException {
  JuegoNotFoundException([super.message = 'Juego no encontrado'])
      : super(code: 'JUEGO_NOT_FOUND');
      
  factory JuegoNotFoundException.withId(String id) {
    return JuegoNotFoundException('Juego con ID $id no encontrado');
  }
  
  factory JuegoNotFoundException.withTipo(String tipo) {
    return JuegoNotFoundException('No se encontraron juegos de tipo $tipo');
  }
}

/// Error de validación
class JuegoValidationException extends JuegoException {
  JuegoValidationException([super.message = 'Datos del juego inválidos'])
      : super(code: 'JUEGO_VALIDATION_ERROR');
      
  factory JuegoValidationException.respuestaInvalida() {
    return JuegoValidationException('La respuesta proporcionada es inválida');
  }
  
  factory JuegoValidationException.configuracionInvalida(String razon) {
    return JuegoValidationException('Configuración inválida: $razon');
  }
}

/// Error de estado
class JuegoEstadoException extends JuegoException {
  JuegoEstadoException(super.message, {String? code, super.value})
      : super(code: code ?? 'JUEGO_ESTADO_ERROR');
      
  factory JuegoEstadoException.estadoIncorrecto(String estadoActual, String estadoEsperado) {
    return JuegoEstadoException(
      'Estado incorrecto: actual $estadoActual, esperado $estadoEsperado',
      code: 'JUEGO_ESTADO_INCORRECTO',
      value: {'actual': estadoActual, 'esperado': estadoEsperado}
    );
  }
  
  factory JuegoEstadoException.juegoFinalizado() {
    return JuegoEstadoException(
      'El juego ya ha finalizado',
      code: 'JUEGO_FINALIZADO'
    );
  }
  
  factory JuegoEstadoException.juegoNoIniciado() {
    return JuegoEstadoException(
      'El juego no ha sido iniciado',
      code: 'JUEGO_NO_INICIADO'
    );
  }
}

/// Error de puntaje
class JuegoPuntajeException extends JuegoException {
  JuegoPuntajeException(super.message, {String? code, super.value})
      : super(code: code ?? 'JUEGO_PUNTAJE_ERROR');
      
  factory JuegoPuntajeException.puntajeInvalido(int puntaje, int maximo) {
    return JuegoPuntajeException(
      'Puntaje inválido: $puntaje (máximo: $maximo)',
      code: 'JUEGO_PUNTAJE_INVALIDO',
      value: {'puntaje': puntaje, 'maximo': maximo}
    );
  }
}

/// Error de tiempo
class JuegoTiempoException extends JuegoException {
  JuegoTiempoException(super.message, {String? code})
      : super(code: code ?? 'JUEGO_TIEMPO_ERROR');
      
  factory JuegoTiempoException.tiempoExpirado() {
    return JuegoTiempoException(
      'El tiempo para completar el juego ha expirado',
      code: 'JUEGO_TIEMPO_EXPIRADO'
    );
  }
}

/// Error de dificultad
class JuegoDificultadException extends JuegoException {
  JuegoDificultadException(super.message, {String? code, super.value})
      : super(code: code ?? 'JUEGO_DIFICULTAD_ERROR');
      
  factory JuegoDificultadException.dificultadInvalida(String dificultad) {
    return JuegoDificultadException(
      'Nivel de dificultad inválido: $dificultad',
      code: 'JUEGO_DIFICULTAD_INVALIDA',
      value: {'dificultad': dificultad}
    );
  }
}