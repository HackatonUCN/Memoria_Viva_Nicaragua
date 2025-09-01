import '../value_objects/ubicacion.dart';

/// Política de geolocalización para validar áreas y proximidad
class GeolocalizacionPolicy {
  /// Verifica si la ubicación está dentro de los límites de Nicaragua
  static bool estaDentroDeNicaragua(Ubicacion ubicacion) {
    return ubicacion.latitud >= Ubicacion.MIN_LAT_NICARAGUA &&
           ubicacion.latitud <= Ubicacion.MAX_LAT_NICARAGUA &&
           ubicacion.longitud >= Ubicacion.MIN_LON_NICARAGUA &&
           ubicacion.longitud <= Ubicacion.MAX_LON_NICARAGUA;
  }

  /// Verifica si dos ubicaciones están a menos de 'km' kilómetros
  static bool estaCercaDe({required Ubicacion a, required Ubicacion b, double km = 5}) {
    return a.calcularDistanciaA(b) <= km;
  }
}
