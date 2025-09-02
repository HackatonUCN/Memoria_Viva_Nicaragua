import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/relato.dart';
import '../value_objects/ubicacion_model.dart';
import '../value_objects/multimedia_model.dart';
import 'content_model.dart';

/// Modelo para mapear la entidad Relato a/desde Firestore
class RelatoModel extends ContentModel<Relato> {
  final String titulo;
  final String contenido;
  final Map<String, dynamic>? ubicacion;
  final List<Map<String, dynamic>> multimedia;
  final List<String> etiquetas;
  final String estado;
  final int reportes;
  final bool procesado;
  final int likes;
  final int compartidos;

  RelatoModel({
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
    this.multimedia = const [],
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
  Relato toDomain() {
    return Relato(
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
      multimedia: multimedia
          .map((m) => MultimediaModel.fromMap(m).toDomain())
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

  /// Convierte la entidad de dominio Relato a RelatoModel
  factory RelatoModel.fromDomain(Relato relato) {
    return RelatoModel(
      id: relato.id,
      titulo: relato.titulo,
      contenido: relato.contenido,
      autorId: relato.autorId,
      autorNombre: relato.autorNombre,
      categoriaId: relato.categoriaId,
      categoriaNombre: relato.categoriaNombre,
      ubicacion: relato.ubicacion != null
          ? UbicacionModel.fromDomain(relato.ubicacion!).toMap()
          : null,
      multimedia: relato.multimedia
          .map((m) => MultimediaModel.fromDomain(m).toMap())
          .toList(),
      etiquetas: relato.etiquetas,
      fechaCreacion: ContentModel.dateTimeToTimestamp(relato.fechaCreacion),
      fechaActualizacion: ContentModel.dateTimeToTimestamp(relato.fechaActualizacion),
      estado: ContentModel.estadoModeracionToString(relato.estado),
      reportes: relato.reportes,
      procesado: relato.procesado,
      likes: relato.likes,
      compartidos: relato.compartidos,
      eliminado: relato.eliminado,
      fechaEliminacion: relato.fechaEliminacion != null
          ? ContentModel.dateTimeToTimestamp(relato.fechaEliminacion)
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
      'multimedia': multimedia,
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

  /// Crea una instancia de RelatoModel desde un Map de Firestore
  factory RelatoModel.fromMap(Map<String, dynamic> map) {
    return RelatoModel(
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
      multimedia: (map['multimedia'] as List<dynamic>?)
              ?.map((m) => Map<String, dynamic>.from(m))
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
  factory RelatoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id del relato
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return RelatoModel.fromMap(data);
  }
}
