import 'package:cloud_firestore/cloud_firestore.dart';
import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../enums/estado_moderacion.dart';

/// Entidad principal para los relatos en Memoria Viva Nicaragua
class Relato {
  final String id;
  final String titulo;
  final String contenido;
  
  // Información del autor
  final String autorId;
  final String autorNombre;
  
  // Ubicación como value object
  final Ubicacion? ubicacion;
  
  // Multimedia como value objects
  final List<Multimedia> multimedia;
  
  // Categorización
  final String categoriaId;      // ID de la categoría
  final String categoriaNombre;  // Nombre de la categoría
  final List<String> etiquetas;
  
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

  const Relato({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.autorId,
    required this.autorNombre,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.ubicacion,
    this.multimedia = const [],
    this.etiquetas = const [],
    this.estado = EstadoModeracion.activo,
    this.reportes = 0,
    this.procesado = false,
    this.likes = 0,
    this.compartidos = 0,
    this.eliminado = false,
    this.fechaEliminacion,
  });

  /// Crea una copia del relato con campos actualizados
  Relato copyWith({
    String? titulo,
    String? contenido,
    Ubicacion? ubicacion,
    List<Multimedia>? multimedia,
    String? categoriaId,
    String? categoriaNombre,
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
    return Relato(
      id: this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      autorId: this.autorId,
      autorNombre: this.autorNombre,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      ubicacion: ubicacion ?? this.ubicacion,
      multimedia: multimedia ?? this.multimedia,
      etiquetas: etiquetas ?? this.etiquetas,
      fechaCreacion: this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      estado: estado ?? this.estado,
      reportes: reportes ?? this.reportes,
      procesado: procesado ?? this.procesado,
      likes: likes ?? this.likes,
      compartidos: compartidos ?? this.compartidos,
      eliminado: eliminado ?? this.eliminado,
      fechaEliminacion: fechaEliminacion ?? this.fechaEliminacion,
    );
  }

  /// Convierte el relato a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'autorId': autorId,
      'autorNombre': autorNombre,
      'ubicacion': ubicacion?.toMap(),
      'multimedia': multimedia.map((m) => m.toMap()).toList(),
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
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
  factory Relato.fromMap(Map<String, dynamic> map) {
    return Relato(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      autorId: map['autorId'] as String,
      autorNombre: map['autorNombre'] as String,
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      ubicacion: map['ubicacion'] != null 
          ? Ubicacion.fromMap(map['ubicacion'] as Map<String, dynamic>)
          : null,
      multimedia: (map['multimedia'] as List<dynamic>?)
          ?.map((m) => Multimedia.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      etiquetas: List<String>.from(map['etiquetas'] ?? []),
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
      estado: EstadoModeracion.fromString(map['estado'] as String),
      reportes: map['reportes'] as int? ?? 0,
      procesado: map['procesado'] as bool? ?? false,
      likes: map['likes'] as int? ?? 0,
      compartidos: map['compartidos'] as int? ?? 0,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] != null 
          ? (map['fechaEliminacion'] as Timestamp).toDate()
          : null,
    );
  }

  /// Crea un nuevo relato
  factory Relato.crear({
    required String titulo,
    required String contenido,
    required String autorId,
    required String autorNombre,
    required String categoriaId,
    required String categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia> multimedia = const [],
    List<String> etiquetas = const [],
  }) {
    return Relato(
      id: FirebaseFirestore.instance.collection('relatos').doc().id,
      titulo: titulo,
      contenido: contenido,
      autorId: autorId,
      autorNombre: autorNombre,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      multimedia: multimedia,
      etiquetas: etiquetas,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Marca el relato como eliminado (soft delete)
  Relato marcarEliminado() {
    return copyWith(
      eliminado: true,
      fechaEliminacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Restaura un relato eliminado
  Relato restaurar() {
    return copyWith(
      eliminado: false,
      fechaEliminacion: null,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Marca como reportado
  Relato reportar() {
    return copyWith(
      estado: EstadoModeracion.reportado,
      reportes: reportes + 1,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Modera el relato
  Relato moderar({required bool aprobar}) {
    return copyWith(
      estado: aprobar ? EstadoModeracion.activo : EstadoModeracion.oculto,
      procesado: true,
      fechaActualizacion: DateTime.now(),
    );
  }
}