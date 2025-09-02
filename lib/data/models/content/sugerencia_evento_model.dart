import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/evento_cultural.dart';
import '../../../domain/enums/tipos_evento.dart';
import '../value_objects/ubicacion_model.dart';
import '../value_objects/multimedia_model.dart';
import 'content_model.dart';

/// Modelo para mapear la entidad SugerenciaEvento a/desde Firestore
class SugerenciaEventoModel extends ContentModel<SugerenciaEvento> {
  final String nombre;
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
  final String estado;
  final String? razonRechazo;
  final String? eventoId;
  final String sugeridoPorId;
  final String sugeridoPorNombre;

  SugerenciaEventoModel({
    required super.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required super.categoriaId,
    required super.categoriaNombre,
    required this.ubicacion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.organizador,
    required this.sugeridoPorId,
    required this.sugeridoPorNombre,
    required super.fechaCreacion,
    required super.fechaActualizacion,
    this.imagenes = const [],
    this.esRecurrente = false,
    this.frecuencia,
    this.contacto,
    this.estado = 'pendiente',
    this.razonRechazo,
    this.eventoId,
  }) : super(
          autorId: sugeridoPorId,  // Usamos sugeridoPorId como autorId
          autorNombre: sugeridoPorNombre,
          eliminado: false,  // Las sugerencias no tienen soft delete
          fechaEliminacion: null,
        );

  @override
  SugerenciaEvento toDomain() {
    return SugerenciaEvento(
      id: id,
      nombre: nombre,
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
      estado: EstadoSugerencia.fromString(estado),
      razonRechazo: razonRechazo,
      eventoId: eventoId,
      sugeridoPorId: sugeridoPorId,
      sugeridoPorNombre: sugeridoPorNombre,
      fechaCreacion: ContentModel.timestampToDateTime(fechaCreacion),
      fechaActualizacion: ContentModel.timestampToDateTime(fechaActualizacion),
    );
  }

  /// Convierte la entidad de dominio SugerenciaEvento a SugerenciaEventoModel
  factory SugerenciaEventoModel.fromDomain(SugerenciaEvento sugerencia) {
    return SugerenciaEventoModel(
      id: sugerencia.id,
      nombre: sugerencia.nombre,
      descripcion: sugerencia.descripcion,
      tipo: sugerencia.tipo.value,
      categoriaId: sugerencia.categoriaId,
      categoriaNombre: sugerencia.categoriaNombre,
      ubicacion: UbicacionModel.fromDomain(sugerencia.ubicacion).toMap(),
      imagenes: sugerencia.imagenes
          .map((i) => MultimediaModel.fromDomain(i).toMap())
          .toList(),
      fechaInicio: ContentModel.dateTimeToTimestamp(sugerencia.fechaInicio),
      fechaFin: ContentModel.dateTimeToTimestamp(sugerencia.fechaFin),
      esRecurrente: sugerencia.esRecurrente,
      frecuencia: sugerencia.frecuencia,
      organizador: sugerencia.organizador,
      contacto: sugerencia.contacto,
      estado: sugerencia.estado.value,
      razonRechazo: sugerencia.razonRechazo,
      eventoId: sugerencia.eventoId,
      sugeridoPorId: sugerencia.sugeridoPorId,
      sugeridoPorNombre: sugerencia.sugeridoPorNombre,
      fechaCreacion: ContentModel.dateTimeToTimestamp(sugerencia.fechaCreacion),
      fechaActualizacion: ContentModel.dateTimeToTimestamp(sugerencia.fechaActualizacion),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
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
      'estado': estado,
      'razonRechazo': razonRechazo,
      'eventoId': eventoId,
      'sugeridoPorId': sugeridoPorId,
      'sugeridoPorNombre': sugeridoPorNombre,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea una instancia de SugerenciaEventoModel desde un Map de Firestore
  factory SugerenciaEventoModel.fromMap(Map<String, dynamic> map) {
    return SugerenciaEventoModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
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
      estado: map['estado'] as String? ?? 'pendiente',
      razonRechazo: map['razonRechazo'] as String?,
      eventoId: map['eventoId'] as String?,
      sugeridoPorId: map['sugeridoPorId'] as String,
      sugeridoPorNombre: map['sugeridoPorNombre'] as String,
      fechaCreacion: map['fechaCreacion'] as Timestamp,
      fechaActualizacion: map['fechaActualizacion'] as Timestamp,
    );
  }

  /// Crea una instancia desde un documento de Firestore
  factory SugerenciaEventoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id de la sugerencia
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return SugerenciaEventoModel.fromMap(data);
  }
}
