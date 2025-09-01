import 'dart:math' show cos, sin, asin, sqrt, pi;
import '../exceptions/value_object_exception.dart';
import '../validators/ubicacion_validator.dart';

class Ubicacion {
  static const double MIN_LAT_NICARAGUA = 10.7;
  static const double MAX_LAT_NICARAGUA = 15.0;
  static const double MIN_LON_NICARAGUA = -87.7;
  static const double MAX_LON_NICARAGUA = -83.1;

  final double latitud;
  final double longitud;
  final String departamento;
  final String municipio;

  const Ubicacion._({
    required this.latitud,
    required this.longitud,
    required this.departamento,
    required this.municipio,
  });

  factory Ubicacion({
    required double latitud,
    required double longitud,
    required String departamento,
    required String municipio,
  }) {
    final validator = UbicacionValidator();
    
    // Validar coordenadas
    validator.validarCoordenadas(latitud, longitud);
    
    // Validar departamento
    validator.validarDepartamento(departamento);
    
    // Validar municipio-departamento
    validator.validarMunicipioDepartamento(municipio, departamento);

    return Ubicacion._(
      latitud: latitud,
      longitud: longitud,
      departamento: departamento,
      municipio: municipio,
    );
  }

  /// Calcula la distancia en kilómetros a otra ubicación usando la fórmula de Haversine
  double calcularDistanciaA(Ubicacion otra) {
    const radioTierra = 6371.0; // Radio de la Tierra en km
    
    final dLat = _toRadianes(otra.latitud - latitud);
    final dLon = _toRadianes(otra.longitud - longitud);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadianes(latitud)) * cos(_toRadianes(otra.latitud)) *
              sin(dLon / 2) * sin(dLon / 2);
              
    final c = 2 * asin(sqrt(a));
    return radioTierra * c;
  }

  /// Convierte grados a radianes
  double _toRadianes(double grados) => grados * pi / 180.0;

  /// Obtiene una dirección formateada
  String obtenerDireccionFormateada() {
    return '$municipio, $departamento, Nicaragua';
  }

  Map<String, dynamic> toMap() => {
    'latitud': latitud,
    'longitud': longitud,
    'departamento': departamento,
    'municipio': municipio,
  };

  factory Ubicacion.fromMap(Map<String, dynamic> map) {
    return Ubicacion(
      latitud: map['latitud'] as double,
      longitud: map['longitud'] as double,
      departamento: map['departamento'] as String,
      municipio: map['municipio'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Ubicacion &&
    runtimeType == other.runtimeType &&
    latitud == other.latitud &&
    longitud == other.longitud &&
    departamento == other.departamento &&
    municipio == other.municipio;

  @override
  int get hashCode =>
    latitud.hashCode ^
    longitud.hashCode ^
    departamento.hashCode ^
    municipio.hashCode;

  @override
  String toString() =>
    'Ubicacion(latitud: $latitud, longitud: $longitud, departamento: $departamento, municipio: $municipio)';
}