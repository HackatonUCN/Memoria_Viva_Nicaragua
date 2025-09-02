import '../../../domain/value_objects/ubicacion.dart';

/// Modelo para mapear el value object Ubicacion a/desde Firestore
class UbicacionModel {
  final double latitud;
  final double longitud;
  final String departamento;
  final String municipio;

  UbicacionModel({
    required this.latitud,
    required this.longitud,
    required this.departamento,
    required this.municipio,
  });

  /// Convierte el modelo a la entidad de dominio Ubicacion
  Ubicacion toDomain() {
    return Ubicacion(
      latitud: latitud,
      longitud: longitud,
      departamento: departamento,
      municipio: municipio,
    );
  }

  /// Convierte la entidad de dominio Ubicacion a UbicacionModel
  factory UbicacionModel.fromDomain(Ubicacion ubicacion) {
    return UbicacionModel(
      latitud: ubicacion.latitud,
      longitud: ubicacion.longitud,
      departamento: ubicacion.departamento,
      municipio: ubicacion.municipio,
    );
  }

  /// Convierte el modelo a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'departamento': departamento,
      'municipio': municipio,
    };
  }

  /// Crea una instancia de UbicacionModel desde un Map de Firestore
  factory UbicacionModel.fromMap(Map<String, dynamic> map) {
    return UbicacionModel(
      latitud: map['latitud'] as double,
      longitud: map['longitud'] as double,
      departamento: map['departamento'] as String,
      municipio: map['municipio'] as String,
    );
  }
}
