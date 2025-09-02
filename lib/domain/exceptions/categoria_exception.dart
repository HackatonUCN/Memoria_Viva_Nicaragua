/// Excepción base para errores relacionados con categorías
class CategoriaException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  CategoriaException(this.message, {this.code, this.data});

  @override
  String toString() => 'CategoriaException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Excepción para cuando no se encuentra una categoría
class CategoriaNotFoundException extends CategoriaException {
  final dynamic value;

  CategoriaNotFoundException(String message, {String? code, this.value}) 
      : super(message, code: code ?? 'categoria-not-found', data: value);

  factory CategoriaNotFoundException.withId(String id) {
    return CategoriaNotFoundException(
      'Categoría no encontrada (ID: $id)',
      value: {'id': id},
    );
  }

  factory CategoriaNotFoundException.withName(String nombre) {
    return CategoriaNotFoundException(
      'Categoría no encontrada (Nombre: $nombre)',
      value: {'nombre': nombre},
    );
  }
}

/// Excepción para cuando ya existe una categoría con el mismo nombre y tipo
class CategoriaDuplicadaException extends CategoriaException {
  final dynamic value;

  CategoriaDuplicadaException(String message, {String? code, this.value}) 
      : super(message, code: code ?? 'categoria-duplicate', data: value);

  factory CategoriaDuplicadaException.withName({required String nombre, String? tipo}) {
    return CategoriaDuplicadaException(
      'Ya existe una categoría con el nombre: $nombre${tipo != null ? ' (Tipo: $tipo)' : ''}',
      value: {'nombre': nombre, 'tipo': tipo},
    );
  }
}

/// Excepción para cuando una categoría está en uso y no se puede eliminar
class CategoriaEnUsoException extends CategoriaException {
  final dynamic value;

  CategoriaEnUsoException(String message, {String? code, this.value}) 
      : super(message, code: code ?? 'categoria-in-use', data: value);

  factory CategoriaEnUsoException.withContent({
    required String id,
    required String tipo,
    required int cantidad,
  }) {
    return CategoriaEnUsoException(
      'No se puede eliminar la categoría porque tiene $cantidad elementos de tipo $tipo asociados',
      value: {'id': id, 'tipo': tipo, 'cantidad': cantidad},
    );
  }
}

/// Excepción para errores de validación en categorías
class CategoriaValidationException extends CategoriaException {
  final dynamic value;

  CategoriaValidationException(String message, {String? code, this.value}) 
      : super(message, code: code ?? 'categoria-validation', data: value);

  factory CategoriaValidationException.field({required String campo, required String razon}) {
    return CategoriaValidationException(
      'Error de validación en campo $campo: $razon',
      value: {'campo': campo, 'razon': razon},
    );
  }
}

/// Excepción para problemas con la jerarquía de categorías
class CategoriaHierarchyException extends CategoriaException {
  final dynamic value;

  CategoriaHierarchyException(String message, {String? code, this.value}) 
      : super(message, code: code ?? 'categoria-hierarchy', data: value);

  factory CategoriaHierarchyException.withSubcategories({required String id, required int cantidad}) {
    return CategoriaHierarchyException(
      'No se puede eliminar la categoría porque tiene $cantidad subcategorías',
      value: {'id': id, 'cantidad': cantidad},
    );
  }

  factory CategoriaHierarchyException.circularReference({
    required String categoriaId,
    required String padreId,
  }) {
    return CategoriaHierarchyException(
      'Referencia circular detectada: la categoría $categoriaId no puede tener como padre a $padreId',
      value: {'categoriaId': categoriaId, 'padreId': padreId},
    );
  }
}