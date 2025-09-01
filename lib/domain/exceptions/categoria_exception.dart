/// Excepción base para errores relacionados con categorías
class CategoriaException implements Exception {
  final String message;
  final String? code;
  final dynamic value;

  CategoriaException(this.message, {this.code, this.value});

  @override
  String toString() => 'CategoriaException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Categoría no encontrada
class CategoriaNotFoundException extends CategoriaException {
  CategoriaNotFoundException([String message = 'Categoría no encontrada'])
      : super(message, code: 'CATEGORIA_NOT_FOUND');
      
  factory CategoriaNotFoundException.withId(String id) {
    return CategoriaNotFoundException('Categoría con ID $id no encontrada');
  }
}

/// Categoría duplicada
class CategoriaDuplicadaException extends CategoriaException {
  CategoriaDuplicadaException([String message = 'Ya existe una categoría con este nombre'])
      : super(message, code: 'CATEGORIA_DUPLICADA');
      
  factory CategoriaDuplicadaException.withName(String nombre) {
    return CategoriaDuplicadaException('Ya existe una categoría con el nombre: $nombre');
  }
}

/// Categoría en uso
class CategoriaEnUsoException extends CategoriaException {
  CategoriaEnUsoException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'CATEGORIA_EN_USO', value: value);
      
  factory CategoriaEnUsoException.withDetails(String id, String nombre, int usos) {
    return CategoriaEnUsoException(
      'La categoría "$nombre" está siendo utilizada en $usos elementos',
      code: 'CATEGORIA_EN_USO_DETALLES',
      value: {'id': id, 'nombre': nombre, 'usos': usos}
    );
  }
}

/// Error de validación de categoría
class CategoriaValidationException extends CategoriaException {
  CategoriaValidationException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'CATEGORIA_VALIDATION_ERROR', value: value);
      
  factory CategoriaValidationException.nombreInvalido(String razon) {
    return CategoriaValidationException(
      'Nombre inválido: $razon',
      code: 'CATEGORIA_NOMBRE_INVALIDO',
      value: {'razon': razon}
    );
  }
  
  factory CategoriaValidationException.descripcionInvalida(String razon) {
    return CategoriaValidationException(
      'Descripción inválida: $razon',
      code: 'CATEGORIA_DESCRIPCION_INVALIDA',
      value: {'razon': razon}
    );
  }
  
  factory CategoriaValidationException.iconoInvalido(String razon) {
    return CategoriaValidationException(
      'Icono inválido: $razon',
      code: 'CATEGORIA_ICONO_INVALIDO',
      value: {'razon': razon}
    );
  }
  
  factory CategoriaValidationException.colorInvalido(String razon) {
    return CategoriaValidationException(
      'Color inválido: $razon',
      code: 'CATEGORIA_COLOR_INVALIDO',
      value: {'razon': razon}
    );
  }
}

/// Error de jerarquía de categoría
class CategoriaHierarchyException extends CategoriaException {
  CategoriaHierarchyException(String message, {String? code, dynamic value})
      : super(message, code: code ?? 'CATEGORIA_HIERARCHY_ERROR', value: value);
      
  factory CategoriaHierarchyException.cicloDetectado() {
    return CategoriaHierarchyException(
      'Se ha detectado un ciclo en la jerarquía de categorías',
      code: 'CATEGORIA_CICLO_DETECTADO'
    );
  }
  
  factory CategoriaHierarchyException.padreNoEncontrado(String padreId) {
    return CategoriaHierarchyException(
      'La categoría padre con ID $padreId no existe',
      code: 'CATEGORIA_PADRE_NO_ENCONTRADO',
      value: {'padreId': padreId}
    );
  }
}