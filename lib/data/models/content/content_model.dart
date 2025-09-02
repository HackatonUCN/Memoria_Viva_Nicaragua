import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/enums/estado_moderacion.dart';
import '../base_model.dart';

/// Modelo base para todos los tipos de contenido (Relatos, Saberes, Eventos)
abstract class ContentModel<T> implements BaseModel<T> {
  final String id;
  final String autorId;
  final String autorNombre;
  final String categoriaId;
  final String categoriaNombre;
  final Timestamp fechaCreacion;
  final Timestamp fechaActualizacion;
  final bool eliminado;
  final Timestamp? fechaEliminacion;

  ContentModel({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.eliminado,
    this.fechaEliminacion,
  });

  /// Convertir DateTime a Timestamp
  static Timestamp dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return Timestamp.now();
    }
    return Timestamp.fromDate(dateTime.isUtc ? dateTime : dateTime.toUtc());
  }

  /// Convertir Timestamp a DateTime
  static DateTime timestampToDateTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return timestamp.toDate().toUtc();
  }

  /// Convertir string de estado a EstadoModeracion
  static EstadoModeracion stringToEstadoModeracion(String? estado) {
    if (estado == null) {
      return EstadoModeracion.activo;
    }
    return EstadoModeracion.fromString(estado);
  }

  /// Convertir EstadoModeracion a string
  static String estadoModeracionToString(EstadoModeracion estado) {
    return estado.value;
  }
}
