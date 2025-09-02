import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/saber_popular.dart';
import '../value_objects/ubicacion_model.dart';
import '../value_objects/multimedia_model.dart';
import 'content_model.dart';

/// Modelo para mapear la entidad SaberPopular a/desde Firestore
class SaberPopularModel extends ContentModel<SaberPopular> {
  final String titulo;
  final String contenido;
  final Map<String, dynamic>? ubicacion;
  final List<Map<String, dynamic>> imagenes;
  final List<String> etiquetas;
  final String estado;
  final int reportes;
  final bool procesado;
  final int likes;
  final int compartidos;

  SaberPopularModel({
    required super.id,
    required this.titulo,
    required this.contenido,
    required super.autorId,
    required super.autorNombre,
    required super.categoriaId,
    required super.categoriaNombre,
    required super.fechaCreacion,
    required super.fechaActualizacion,
    this.ubicacion,
    this.imagenes = const [],
    this.etiquetas = const [],
    this.estado = 'activo',
    this.reportes = 0,
    this.procesado = false,
    this.likes = 0,
    this.compartidos = 0,
    super.eliminado = false,
    super.fechaEliminacion,
  });

  @override
  SaberPopular toDomain() {
    return SaberPopular(
      id: id,
      titulo: titulo,
      contenido: contenido,
      autorId: autorId,
      autorNombre: autorNombre,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion != null
          ? UbicacionModel.fromMap(ubicacion!).toDomain()
          : null,
      imagenes: imagenes
          .map((i) => MultimediaModel.fromMap(i).toDomain())
          .toList(),
      etiquetas: etiquetas,
      fechaCreacion: ContentModel.timestampToDateTime(fechaCreacion),
      fechaActualizacion: ContentModel.timestampToDateTime(fechaActualizacion),
      estado: ContentModel.stringToEstadoModeracion(estado),
      reportes: reportes,
      procesado: procesado,
      likes: likes,
      compartidos: compartidos,
      eliminado: eliminado,
      fechaEliminacion: fechaEliminacion != null
          ? ContentModel.timestampToDateTime(fechaEliminacion)
          : null,
    );
  }

  /// Convierte la entidad de dominio SaberPopular a SaberPopularModel
  factory SaberPopularModel.fromDomain(SaberPopular saber) {
    return SaberPopularModel(
      id: saber.id,
      titulo: saber.titulo,
      contenido: saber.contenido,
      autorId: saber.autorId,
      autorNombre: saber.autorNombre,
      categoriaId: saber.categoriaId,
      categoriaNombre: saber.categoriaNombre,
      ubicacion: saber.ubicacion != null
          ? UbicacionModel.fromDomain(saber.ubicacion!).toMap()
          : null,
      imagenes: saber.imagenes
          .map((i) => MultimediaModel.fromDomain(i).toMap())
          .toList(),
      etiquetas: saber.etiquetas,
      fechaCreacion: ContentModel.dateTimeToTimestamp(saber.fechaCreacion),
      fechaActualizacion: ContentModel.dateTimeToTimestamp(saber.fechaActualizacion),
      estado: ContentModel.estadoModeracionToString(saber.estado),
      reportes: saber.reportes,
      procesado: saber.procesado,
      likes: saber.likes,
      compartidos: saber.compartidos,
      eliminado: saber.eliminado,
      fechaEliminacion: saber.fechaEliminacion != null
          ? ContentModel.dateTimeToTimestamp(saber.fechaEliminacion)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'autorId': autorId,
      'autorNombre': autorNombre,
      'ubicacion': ubicacion,
      'imagenes': imagenes,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'etiquetas': etiquetas,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
      'estado': estado,
      'reportes': reportes,
      'procesado': procesado,
      'likes': likes,
      'compartidos': compartidos,
      'eliminado': eliminado,
      'fechaEliminacion': fechaEliminacion,
    };
  }

  /// Crea una instancia de SaberPopularModel desde un Map de Firestore
  factory SaberPopularModel.fromMap(Map<String, dynamic> map) {
    return SaberPopularModel(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      autorId: map['autorId'] as String,
      autorNombre: map['autorNombre'] as String,
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      ubicacion: map['ubicacion'] != null
          ? Map<String, dynamic>.from(map['ubicacion'])
          : null,
      imagenes: (map['imagenes'] as List<dynamic>?)
              ?.map((i) => Map<String, dynamic>.from(i))
              .toList() ??
          [],
      etiquetas: List<String>.from(map['etiquetas'] ?? []),
      fechaCreacion: map['fechaCreacion'] as Timestamp,
      fechaActualizacion: map['fechaActualizacion'] as Timestamp,
      estado: map['estado'] as String? ?? 'activo',
      reportes: map['reportes'] as int? ?? 0,
      procesado: map['procesado'] as bool? ?? false,
      likes: map['likes'] as int? ?? 0,
      compartidos: map['compartidos'] as int? ?? 0,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] as Timestamp?,
    );
  }

  /// Crea una instancia desde un documento de Firestore
  factory SaberPopularModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id del saber
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return SaberPopularModel.fromMap(data);
  }
}
