import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/evento_cultural.dart';
import '../../../domain/enums/tipos_evento.dart';
import '../value_objects/ubicacion_model.dart';
import '../value_objects/multimedia_model.dart';
import 'content_model.dart';

/// Modelo para mapear la entidad EventoCultural a/desde Firestore
class EventoCulturalModel extends ContentModel<EventoCultural> {
  final String titulo;
  final String descripcion;
  final String tipo;
  final Map<String, dynamic> ubicacion;
  final List<Map<String, dynamic>> imagenes;
  final Timestamp fechaInicio;
  final Timestamp fechaFin;
  final bool esRecurrente;
  final String? frecuencia;
  final String organizador;
  final String? contacto;
  final String creadoPorId;
  final String creadoPorNombre;

  EventoCulturalModel({
    required super.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required super.categoriaId,
    required super.categoriaNombre,
    required this.ubicacion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.organizador,
    required this.creadoPorId,
    required this.creadoPorNombre,
    required super.fechaCreacion,
    required super.fechaActualizacion,
    this.imagenes = const [],
    this.esRecurrente = false,
    this.frecuencia,
    this.contacto,
    super.eliminado = false,
    super.fechaEliminacion,
  }) : super(
          autorId: creadoPorId,  // Usamos creadoPorId como autorId
          autorNombre: creadoPorNombre,
        );

  @override
  EventoCultural toDomain() {
    return EventoCultural(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      tipo: TipoEvento.fromString(tipo),
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: UbicacionModel.fromMap(ubicacion).toDomain(),
      imagenes: imagenes
          .map((i) => MultimediaModel.fromMap(i).toDomain())
          .toList(),
      fechaInicio: ContentModel.timestampToDateTime(fechaInicio),
      fechaFin: ContentModel.timestampToDateTime(fechaFin),
      esRecurrente: esRecurrente,
      frecuencia: frecuencia,
      organizador: organizador,
      contacto: contacto,
      creadoPorId: creadoPorId,
      creadoPorNombre: creadoPorNombre,
      fechaCreacion: ContentModel.timestampToDateTime(fechaCreacion),
      fechaActualizacion: ContentModel.timestampToDateTime(fechaActualizacion),
      eliminado: eliminado,
      fechaEliminacion: fechaEliminacion != null
          ? ContentModel.timestampToDateTime(fechaEliminacion)
          : null,
    );
  }

  /// Convierte la entidad de dominio EventoCultural a EventoCulturalModel
  factory EventoCulturalModel.fromDomain(EventoCultural evento) {
    return EventoCulturalModel(
      id: evento.id,
      titulo: evento.titulo,
      descripcion: evento.descripcion,
      tipo: evento.tipo.value,
      categoriaId: evento.categoriaId,
      categoriaNombre: evento.categoriaNombre,
      ubicacion: UbicacionModel.fromDomain(evento.ubicacion).toMap(),
      imagenes: evento.imagenes
          .map((i) => MultimediaModel.fromDomain(i).toMap())
          .toList(),
      fechaInicio: ContentModel.dateTimeToTimestamp(evento.fechaInicio),
      fechaFin: ContentModel.dateTimeToTimestamp(evento.fechaFin),
      esRecurrente: evento.esRecurrente,
      frecuencia: evento.frecuencia,
      organizador: evento.organizador,
      contacto: evento.contacto,
      creadoPorId: evento.creadoPorId,
      creadoPorNombre: evento.creadoPorNombre,
      fechaCreacion: ContentModel.dateTimeToTimestamp(evento.fechaCreacion),
      fechaActualizacion: ContentModel.dateTimeToTimestamp(evento.fechaActualizacion),
      eliminado: evento.eliminado,
      fechaEliminacion: evento.fechaEliminacion != null
          ? ContentModel.dateTimeToTimestamp(evento.fechaEliminacion)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': titulo,  // Usamos nombre en vez de titulo para mantener compatibilidad
      'descripcion': descripcion,
      'tipo': tipo,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'ubicacion': ubicacion,
      'imagenes': imagenes,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'esRecurrente': esRecurrente,
      'frecuencia': frecuencia,
      'organizador': organizador,
      'contacto': contacto,
      'creadoPorId': creadoPorId,
      'creadoPorNombre': creadoPorNombre,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
      'eliminado': eliminado,
      'fechaEliminacion': fechaEliminacion,
    };
  }

  /// Crea una instancia de EventoCulturalModel desde un Map de Firestore
  factory EventoCulturalModel.fromMap(Map<String, dynamic> map) {
    return EventoCulturalModel(
      id: map['id'] as String,
      titulo: map['nombre'] as String,  // Usamos nombre en vez de titulo
      descripcion: map['descripcion'] as String,
      tipo: map['tipo'] as String,
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      ubicacion: Map<String, dynamic>.from(map['ubicacion']),
      imagenes: (map['imagenes'] as List<dynamic>?)
              ?.map((i) => Map<String, dynamic>.from(i))
              .toList() ??
          [],
      fechaInicio: map['fechaInicio'] as Timestamp,
      fechaFin: map['fechaFin'] as Timestamp,
      esRecurrente: map['esRecurrente'] as bool? ?? false,
      frecuencia: map['frecuencia'] as String?,
      organizador: map['organizador'] as String,
      contacto: map['contacto'] as String?,
      creadoPorId: map['creadoPorId'] as String,
      creadoPorNombre: map['creadoPorNombre'] as String,
      fechaCreacion: map['fechaCreacion'] as Timestamp,
      fechaActualizacion: map['fechaActualizacion'] as Timestamp,
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] as Timestamp?,
    );
  }

  /// Crea una instancia desde un documento de Firestore
  factory EventoCulturalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id del evento
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return EventoCulturalModel.fromMap(data);
  }
}
