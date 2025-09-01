import '../value_objects/ubicacion.dart';
import '../enums/departamentos.dart';
import '../exceptions/value_object_exception.dart';

/// Validador para ubicaciones geográficas en Nicaragua
class UbicacionValidator {
  static const double MIN_LAT_NICARAGUA = 10.7;
  static const double MAX_LAT_NICARAGUA = 15.0;
  static const double MIN_LON_NICARAGUA = -87.7;
  static const double MAX_LON_NICARAGUA = -83.1;

  /// Verifica si las coordenadas están dentro de Nicaragua
  bool estaEnNicaragua(double latitud, double longitud) {
    return latitud >= MIN_LAT_NICARAGUA && 
           latitud <= MAX_LAT_NICARAGUA &&
           longitud >= MIN_LON_NICARAGUA && 
           longitud <= MAX_LON_NICARAGUA;
  }

  /// Verifica si un municipio pertenece al departamento especificado
  bool municipioPerteneceADepartamento(String municipio, String departamento) {
    // Normalizar a minúsculas para comparación
    final depNormalizado = departamento.toLowerCase();
    final munNormalizado = municipio.toLowerCase();
    
    // Usar el mapa definido en enums/departamentos.dart
    final municipiosDelDepartamento = municipiosPorDepartamento[depNormalizado];
    if (municipiosDelDepartamento == null) return false;
    
    // Comparar en minúsculas
    return municipiosDelDepartamento
        .map((m) => m.toLowerCase())
        .contains(munNormalizado);
  }

  /// Valida una ubicación completa y retorna errores o lanza excepciones
  List<String> validarUbicacion(Ubicacion ubicacion) {
    final errores = <String>[];

    if (!estaEnNicaragua(ubicacion.latitud, ubicacion.longitud)) {
      errores.add('La ubicación debe estar dentro de Nicaragua');
    }

    if (!municipioPerteneceADepartamento(ubicacion.municipio, ubicacion.departamento)) {
      errores.add('El municipio ${ubicacion.municipio} no pertenece al departamento ${ubicacion.departamento}');
    }

    return errores;
  }
  
  /// Valida coordenadas y lanza excepciones si son inválidas
  void validarCoordenadas(double latitud, double longitud) {
    if (latitud.isNaN || longitud.isNaN) {
      throw UbicacionInvalidaException.coordenadasInvalidas();
    }

    if (!estaEnNicaragua(latitud, longitud)) {
      throw UbicacionInvalidaException.fueraDeNicaragua(
        latitud: latitud,
        longitud: longitud,
      );
    }
  }
  
  /// Valida departamento y lanza excepción si es inválido
  void validarDepartamento(String departamento) {
    final departamentosNicaragua = Departamento.values.map((d) => d.nombre).toList();
    
    if (!departamentosNicaragua.any((d) => d.toLowerCase() == departamento.toLowerCase())) {
      throw UbicacionInvalidaException.departamentoInvalido(
        departamento: departamento,
      );
    }
  }
  
  /// Valida la relación municipio-departamento y lanza excepción si es inválida
  void validarMunicipioDepartamento(String municipio, String departamento) {
    if (!municipioPerteneceADepartamento(municipio, departamento)) {
      throw UbicacionInvalidaException.municipioInvalido(
        municipio: municipio,
        departamento: departamento,
      );
    }
  }
}