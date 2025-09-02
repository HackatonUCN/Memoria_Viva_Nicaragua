import 'package:cloud_firestore/cloud_firestore.dart';

/// Clase abstracta que define los métodos comunes para los modelos de datos
/// que se utilizan para mapear entidades de dominio a/desde Firestore
abstract class BaseModel<T> {
  /// Convierte la instancia actual a un Map para Firestore
  Map<String, dynamic> toMap();
  
  /// Convierte la instancia actual a la entidad de dominio correspondiente
  T toDomain();

  /// Utilidad para convertir valores de DateTime a Timestamp y viceversa
  static Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  /// Convierte un valor dinámico (Timestamp, DateTime, int, etc.) a DateTime UTC
  static DateTime parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    }
    if (value is Timestamp) {
      return value.toDate().toUtc();
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
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
