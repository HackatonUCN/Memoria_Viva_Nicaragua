# Servicios de Dominio (Services)

Los servicios del dominio son interfaces que exponen capacidades que no pertenecen a una entidad/VO específicos (analítica, geolocalización, multimedia, notificaciones, etc.). Aquí solo se definen contratos.

## Principios
- Interfaces puras con prefijo `I`.
- Sin detalles de implementación ni dependencias externas.
- Operaciones nombradas con verbos claros en español.

## Convenciones
- Nombre: `IServicio...` o `I...Service` (consistencia con el código existente: `IAnalyticsService`).
- Métodos asíncronos (`Future`/`Stream`) con parámetros nombrados.
- Tipos del dominio en las firmas cuando aplique (`User`, `Relato`, `EventoCultural`).

## Ejemplo (extracto de `IAnalyticsService`)
```dart
abstract class IAnalyticsService {
  Future<void> inicializar({User? usuario});
  Future<void> registrarVisualizacion({required String contenidoId, required String tipoContenido, Map<String, dynamic>? propiedades});
  Future<void> registrarError({required String mensaje, required String codigo, String? ubicacion, Map<String, dynamic>? contexto});
}
```

## Buenas prácticas
- Mantener contextos de operación claros (prefijos `registrar`, `obtener`, `establecer`).
- Evitar sobrecargar interfaces; preferir interfaces enfocadas por capacidad.
- Diseñar pensando en testabilidad (dobles de prueba en la capa de tests).
