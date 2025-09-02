import '../enums/tipos_contenido.dart';

/// Entidad para categorizar el contenido de la aplicación
class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoContenido tipo;
  
  // Jerarquía
  final String? categoriaPadreId;
  
  // UI/UX
  final String icono;            // Nombre del icono
  final String color;            // Color en hex
  final int orden;               // Orden de visualización
  
  // Estado
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.orden,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.categoriaPadreId,
    this.activa = true,
  }) : assert(id != ''),
       assert(nombre.trim() != ''),
       assert(descripcion.trim() != ''),
       assert(icono.trim() != ''),
       assert(color.trim() != ''),
       assert(orden >= 0),
       assert(color.startsWith('#') ? (color.length == 7 || color.length == 9) : true);

  /// Crea una copia con campos actualizados
  Categoria copyWith({
    String? nombre,
    String? descripcion,
    TipoContenido? tipo,
    String? categoriaPadreId,
    String? icono,
    String? color,
    int? orden,
    bool? activa,
  }) {
    return Categoria(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      categoriaPadreId: categoriaPadreId ?? this.categoriaPadreId,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'categoriaPadreId': categoriaPadreId,
      'icono': icono,
      'color': color,
      'orden': orden,
      'activa': activa,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea desde Map de Firestore
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tipo: TipoContenido.fromString(map['tipo'] as String),
      categoriaPadreId: map['categoriaPadreId'] as String?,
      icono: map['icono'] as String,
      color: map['color'] as String,
      orden: map['orden'] as int,
      activa: map['activa'] as bool? ?? true,
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      fechaActualizacion: _parseDateTime(map['fechaActualizacion']),
    );
  }

  /// Crea una nueva categoría
  factory Categoria.crear({
    required String nombre,
    required String descripcion,
    required TipoContenido tipo,
    required String icono,
    required String color,
    required int orden,
    String? categoriaPadreId,
  }) {
    return Categoria(
      id: _generateId(),
      nombre: nombre,
      descripcion: descripcion,
      tipo: tipo,
      categoriaPadreId: categoriaPadreId,
      icono: icono,
      color: color,
      orden: orden,
      fechaCreacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  if (value is DateTime) {
    return value.isUtc ? value : value.toUtc();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is String) {
    return DateTime.parse(value).toUtc();
  }
  try {
    final dynamic dyn = value;
    final DateTime dt = dyn.toDate();
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

String _generateId({int length = 20}) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final StringBuffer buffer = StringBuffer();
  final int max = chars.length;
  int seed = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < length; i++) {
    seed = 1664525 * seed + 1013904223;
    final int index = (seed & 0x7FFFFFFF) % max;
    buffer.write(chars[index]);
  }
  return buffer.toString();
}