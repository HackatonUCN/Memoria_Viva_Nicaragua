import '../value_objects/ubicacion.dart';

/// Interfaz para el servicio de geolocalización
abstract class IGeolocationService {
  /// Obtiene la ubicación actual del dispositivo
  Future<Ubicacion> obtenerUbicacionActual();

  /// Busca lugares por texto
  Future<List<Ubicacion>> buscarLugares(String query);

  /// Obtiene la dirección desde coordenadas
  Future<String?> obtenerDireccion(double latitud, double longitud);

  /// Verifica si las coordenadas están en Nicaragua
  bool estaEnNicaragua(double latitud, double longitud);

  /// Obtiene lugares cercanos a una ubicación
  Future<List<Ubicacion>> obtenerLugaresCercanos(
    Ubicacion centro,
    double radioKm,
  );

  /// Calcula la distancia entre dos ubicaciones
  double calcularDistancia(Ubicacion origen, Ubicacion destino);

  /// Obtiene el departamento y municipio desde coordenadas
  Future<Map<String, String>?> obtenerDivisionPolitica(
    double latitud,
    double longitud,
  );
}
