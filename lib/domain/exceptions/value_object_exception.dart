/// Excepción base para errores en value objects
class ValueObjectException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  const ValueObjectException({
    required this.message,
    this.code,
    this.value,
  });

  @override
  String toString() => 'ValueObjectException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Excepciones para Ubicacion
class UbicacionInvalidaException extends ValueObjectException {
  UbicacionInvalidaException({
    required String message,
    String? code,
    dynamic value,
  }) : super(
    message: message,
    code: code ?? 'UBICACION_INVALIDA',
    value: value,
  );

  factory UbicacionInvalidaException.coordenadasInvalidas() => 
    UbicacionInvalidaException(
      message: 'Las coordenadas son inválidas',
      code: 'COORDENADAS_INVALIDAS',
    );

  factory UbicacionInvalidaException.fueraDeNicaragua({
    required double latitud,
    required double longitud,
  }) => UbicacionInvalidaException(
    message: 'La ubicación está fuera de Nicaragua',
    code: 'FUERA_DE_NICARAGUA',
    value: {'latitud': latitud, 'longitud': longitud},
  );

  factory UbicacionInvalidaException.departamentoInvalido({
    required String departamento,
  }) => UbicacionInvalidaException(
    message: 'El departamento $departamento no existe en Nicaragua',
    code: 'DEPARTAMENTO_INVALIDO',
    value: departamento,
  );

  factory UbicacionInvalidaException.municipioInvalido({
    required String municipio,
    required String departamento,
  }) => UbicacionInvalidaException(
    message: 'El municipio $municipio no pertenece al departamento $departamento',
    code: 'MUNICIPIO_INVALIDO',
    value: {'municipio': municipio, 'departamento': departamento},
  );
}

/// Excepciones para Multimedia
class MultimediaInvalidaException extends ValueObjectException {
  MultimediaInvalidaException({
    required String message,
    String? code,
    dynamic value,
  }) : super(
    message: message,
    code: code ?? 'MULTIMEDIA_INVALIDA',
    value: value,
  );

  factory MultimediaInvalidaException.urlInvalida({
    required String url,
  }) => MultimediaInvalidaException(
    message: 'La URL del archivo multimedia es inválida',
    code: 'URL_INVALIDA',
    value: url,
  );

  factory MultimediaInvalidaException.tipoInvalido({
    required String tipoInvalido,
  }) => MultimediaInvalidaException(
    message: 'El tipo de multimedia "$tipoInvalido" no es válido',
    code: 'TIPO_INVALIDO',
    value: tipoInvalido,
  );

  factory MultimediaInvalidaException.tipoArchivoNoSoportado({
    required String url,
    required String extension,
    required List<String> extensionesPermitidas,
  }) => MultimediaInvalidaException(
    message: 'El tipo de archivo .$extension no está soportado',
    code: 'TIPO_ARCHIVO_NO_SOPORTADO',
    value: {
      'url': url,
      'extension': extension,
      'extensionesPermitidas': extensionesPermitidas,
    },
  );

  factory MultimediaInvalidaException.descripcionInvalida({
    required String descripcion,
    required int maxCaracteres,
  }) => MultimediaInvalidaException(
    message: 'La descripción excede el máximo de $maxCaracteres caracteres',
    code: 'DESCRIPCION_INVALIDA',
    value: {'descripcion': descripcion, 'maxCaracteres': maxCaracteres},
  );

  factory MultimediaInvalidaException.tamanoExcedido({
    required String url,
    required int tamanoBytes,
    required int limiteMegaBytes,
  }) => MultimediaInvalidaException(
    message: 'El archivo excede el tamaño máximo de $limiteMegaBytes MB',
    code: 'TAMANO_EXCEDIDO',
    value: {
      'url': url,
      'tamanoBytes': tamanoBytes,
      'limiteMegaBytes': limiteMegaBytes,
    },
  );
}

/// Excepciones para validación de contenido
class ContenidoInvalidoException extends ValueObjectException {
  ContenidoInvalidoException({
    required String message,
    String? code,
    dynamic value,
  }) : super(
    message: message,
    code: code ?? 'CONTENIDO_INVALIDO',
    value: value,
  );

  factory ContenidoInvalidoException.longitudInvalida({
    required String campo,
    required int longitudActual,
    required int longitudMinima,
    required int longitudMaxima,
  }) => ContenidoInvalidoException(
    message: 'La longitud del $campo debe estar entre $longitudMinima y $longitudMaxima caracteres',
    code: 'LONGITUD_INVALIDA',
    value: {
      'campo': campo,
      'longitudActual': longitudActual,
      'longitudMinima': longitudMinima,
      'longitudMaxima': longitudMaxima,
    },
  );

  factory ContenidoInvalidoException.caracteresInvalidos({
    required String campo,
    required String caracteresInvalidos,
  }) => ContenidoInvalidoException(
    message: 'El $campo contiene caracteres no permitidos: $caracteresInvalidos',
    code: 'CARACTERES_INVALIDOS',
    value: {'campo': campo, 'caracteresInvalidos': caracteresInvalidos},
  );
}
