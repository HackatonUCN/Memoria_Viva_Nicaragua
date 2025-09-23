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
  // Nuevo: multimedia general, con compatibilidad para 'imagenes'
  final List<Map<String, dynamic>> multimedia;
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
      multimedia: multimedia
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
      multimedia: saber.multimedia
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
    final map = {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'autorId': autorId,
      'autorNombre': autorNombre,
      'ubicacion': ubicacion,
      // Nuevo: escribir siempre en 'multimedia'
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
    // ignore: avoid_print
    print('[SABER_MODEL][TO_MAP] autorId=$autorId categoriaId=$categoriaId keys=${map.keys.length}');
    return map;
  }

  /// Crea una instancia de SaberPopularModel desde un Map de Firestore
  factory SaberPopularModel.fromMap(Map<String, dynamic> map) {
    Timestamp _asTimestamp(dynamic v) {
      if (v == null) return Timestamp.now();
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      if (v is int) return Timestamp.fromMillisecondsSinceEpoch(v);
      if (v is double) return Timestamp.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        try { return Timestamp.fromDate(DateTime.parse(v)); } catch (_) { return Timestamp.now(); }
      }
      return Timestamp.now();
    }
    // Compatibilidad: preferir 'multimedia' con fallback a 'imagenes'
    final List<Map<String, dynamic>> multimedia =
        (map['multimedia'] as List<dynamic>?)
                ?.map((i) => Map<String, dynamic>.from(i))
                .toList() ??
        (map['imagenes'] as List<dynamic>?)
                ?.map((i) => Map<String, dynamic>.from(i))
                .toList() ??
        [];
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
      multimedia: multimedia,
      etiquetas: List<String>.from(map['etiquetas'] ?? []),
      fechaCreacion: _asTimestamp(map['fechaCreacion']),
      fechaActualizacion: _asTimestamp(map['fechaActualizacion']),
      estado: map['estado'] as String? ?? 'activo',
      reportes: map['reportes'] as int? ?? 0,
      procesado: map['procesado'] as bool? ?? false,
      likes: map['likes'] as int? ?? 0,
      compartidos: map['compartidos'] as int? ?? 0,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] != null ? _asTimestamp(map['fechaEliminacion']) : null,
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
