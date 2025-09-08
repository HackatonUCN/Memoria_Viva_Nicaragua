/// Utilidad para mapear strings a entorno del contenedor DI.
/// Útil cuando se inyecta por argumentos de línea de comandos o variables.
import '../di/service_locator.dart';

class AppEnvironmentMapper {
  static DIEnvironment fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'prod':
      case 'production':
        return DIEnvironment.production;
      case 'stg':
      case 'staging':
        return DIEnvironment.staging;
      case 'dev':
      default:
        return DIEnvironment.dev;
    }
  }
}


