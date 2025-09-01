import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Soft delete
  final bool eliminado;
  final DateTime? fechaEliminacion;

  const SaberPopular({
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
    this.eliminado = false,
    this.fechaEliminacion,
  });

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
    bool? eliminado,
    DateTime? fechaEliminacion,
    DateTime? fechaActualizacion,
  }) {
    return SaberPopular(
      id: this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      autorId: this.autorId,
      autorNombre: this.autorNombre,
      ubicacion: ubicacion ?? this.ubicacion,
      imagenes: imagenes ?? this.imagenes,
      etiquetas: etiquetas ?? this.etiquetas,
      fechaCreacion: this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      estado: estado ?? this.estado,
      reportes: reportes ?? this.reportes,
      procesado: procesado ?? this.procesado,
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
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
      estado: EstadoModeracion.fromString(map['estado'] as String),
      reportes: map['reportes'] as int? ?? 0,
      procesado: map['procesado'] as bool? ?? false,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] != null 
          ? (map['fechaEliminacion'] as Timestamp).toDate()
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
      id: FirebaseFirestore.instance.collection('saberes').doc().id,
      titulo: titulo,
      contenido: contenido,
      autorId: autorId,
      autorNombre: autorNombre,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      imagenes: imagenes,
      etiquetas: etiquetas,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Marca como eliminado (soft delete)
  SaberPopular marcarEliminado() {
    return copyWith(
      eliminado: true,
      fechaEliminacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Restaura un saber eliminado
  SaberPopular restaurar() {
    return copyWith(
      eliminado: false,
      fechaEliminacion: null,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Marca como reportado
  SaberPopular reportar() {
    return copyWith(
      estado: EstadoModeracion.reportado,
      reportes: reportes + 1,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Modera el saber popular
  SaberPopular moderar({required bool aprobar}) {
    return copyWith(
      estado: aprobar ? EstadoModeracion.activo : EstadoModeracion.oculto,
      procesado: true,
      fechaActualizacion: DateTime.now(),
    );
  }
}