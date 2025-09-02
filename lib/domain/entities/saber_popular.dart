import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../enums/estado_moderacion.dart';

/// Entidad que representa un saber popular en la aplicación
class SaberPopular {
  final String id;
  final String titulo;
  final String contenido;
  
  // Categorización
  final String categoriaId;      // ID de la categoría
  final String categoriaNombre;  // Nombre de la categoría
  final List<String> etiquetas;
  
  // Ubicación como value object
  final Ubicacion? ubicacion;
  
  // Multimedia como value objects (solo imágenes)
  final List<Multimedia> imagenes;
  
  // Información del autor
  final String autorId;
  final String autorNombre;
  
  // Timestamps
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  
  // Estado y moderación
  final EstadoModeracion estado;
  final int reportes;
  final bool procesado;
  
  // Métricas
  final int likes;
  final int compartidos;
  
  // Soft delete
  final bool eliminado;
  final DateTime? fechaEliminacion;

  SaberPopular({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.autorId,
    required this.autorNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.ubicacion,
    this.imagenes = const [],
    this.etiquetas = const [],
    this.estado = EstadoModeracion.activo,
    this.reportes = 0,
    this.procesado = false,
    this.likes = 0,
    this.compartidos = 0,
    this.eliminado = false,
    this.fechaEliminacion,
  }) : assert(id != ''),
       assert(titulo.trim() != ''),
       assert(contenido.trim() != ''),
       assert(autorId != ''),
       assert(autorNombre.trim() != ''),
       assert(categoriaId != ''),
       assert(categoriaNombre.trim() != ''),
       assert(reportes >= 0),
       assert(likes >= 0),
       assert(compartidos >= 0);

  /// Crea una copia con campos actualizados
  SaberPopular copyWith({
    String? titulo,
    String? contenido,
    String? categoriaId,
    String? categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia>? imagenes,
    List<String>? etiquetas,
    EstadoModeracion? estado,
    int? reportes,
    bool? procesado,
    int? likes,
    int? compartidos,
    bool? eliminado,
    DateTime? fechaEliminacion,
    DateTime? fechaActualizacion,
  }) {
    return SaberPopular(
      id: id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      autorId: autorId,
      autorNombre: autorNombre,
      ubicacion: ubicacion ?? this.ubicacion,
      imagenes: imagenes ?? this.imagenes,
      etiquetas: etiquetas ?? this.etiquetas,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now().toUtc(),
      estado: estado ?? this.estado,
      reportes: reportes ?? this.reportes,
      procesado: procesado ?? this.procesado,
      likes: likes ?? this.likes,
      compartidos: compartidos ?? this.compartidos,
      eliminado: eliminado ?? this.eliminado,
      fechaEliminacion: fechaEliminacion ?? this.fechaEliminacion,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'autorId': autorId,
      'autorNombre': autorNombre,
      'ubicacion': ubicacion?.toMap(),
      'imagenes': imagenes.map((i) => i.toMap()).toList(),
      'etiquetas': etiquetas,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
      'estado': estado.value,
      'reportes': reportes,
      'procesado': procesado,
      'likes': likes,
      'compartidos': compartidos,
      'eliminado': eliminado,
      'fechaEliminacion': fechaEliminacion,
    };
  }

  /// Crea desde Map de Firestore
  factory SaberPopular.fromMap(Map<String, dynamic> map) {
    return SaberPopular(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      autorId: map['autorId'] as String,
      autorNombre: map['autorNombre'] as String,
      ubicacion: map['ubicacion'] != null 
          ? Ubicacion.fromMap(map['ubicacion'] as Map<String, dynamic>)
          : null,
      imagenes: (map['imagenes'] as List<dynamic>?)
          ?.map((i) => Multimedia.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      etiquetas: List<String>.from(map['etiquetas'] ?? []),
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      fechaActualizacion: _parseDateTime(map['fechaActualizacion']),
      estado: EstadoModeracion.fromString(map['estado'] as String),
      reportes: map['reportes'] as int? ?? 0,
      procesado: map['procesado'] as bool? ?? false,
      likes: map['likes'] as int? ?? 0,
      compartidos: map['compartidos'] as int? ?? 0,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] != null 
          ? _parseDateTime(map['fechaEliminacion'])
          : null,
    );
  }

  /// Crea un nuevo saber popular
  factory SaberPopular.crear({
    required String titulo,
    required String contenido,
    required String autorId,
    required String autorNombre,
    required String categoriaId,
    required String categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia> imagenes = const [],
    List<String> etiquetas = const [],
  }) {
    return SaberPopular(
      id: _generateId(),
      titulo: titulo,
      contenido: contenido,
      autorId: autorId,
      autorNombre: autorNombre,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      imagenes: imagenes,
      etiquetas: etiquetas,
      fechaCreacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
      likes: 0,
      compartidos: 0,
    );
  }

  /// Marca como eliminado (soft delete)
  SaberPopular marcarEliminado() {
    return copyWith(
      eliminado: true,
      fechaEliminacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaberPopular && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Restaura un saber eliminado
  SaberPopular restaurar() {
    return copyWith(
      eliminado: false,
      fechaEliminacion: null,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Marca como reportado
  SaberPopular reportar() {
    return copyWith(
      estado: EstadoModeracion.reportado,
      reportes: reportes + 1,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Modera el saber popular
  SaberPopular moderar({required bool aprobar}) {
    return copyWith(
      estado: aprobar ? EstadoModeracion.activo : EstadoModeracion.oculto,
      procesado: true,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    }
    if (value is int) {
      // Assume milliseconds since epoch
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

  static String _generateId({int length = 20}) {
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
}