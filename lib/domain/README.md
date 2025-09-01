# Dominio (Domain Layer)

Este directorio define el corazón de la aplicación Memoria Viva Nicaragua: modelos de negocio, reglas, contratos y casos de uso. Es independiente de frameworks y no conoce detalles de Firebase u otras implementaciones.

## Principios
- Independencia: sin dependencias a Flutter, Firebase ni UI. Solo usa Dart estándar.
- Explícito y tipado: entidades y objetos de valor con invariantes claras; evitar `dynamic` salvo en interoperabilidad.
- Contratos primero: `repositories/` y `services/` son interfaces; la infraestructura las implementa.
- Errores controlados: excepciones de dominio se mapean a `Failure` unificado; los casos de uso devuelven `Result`.
- Ubiquitous language: nombres en español alineados al contexto cultural y educativo.
- Pequeñas reglas, alta cohesión: cada carpeta cumple una responsabilidad única.

## Dependencias permitidas
- Dart core (`dart:core`).
- Archivos del propio dominio. No se permiten imports desde `data/`, `presentation/` ni paquetes de terceros.

## Estructura
- `aggregates/`: documentación y agregados conceptuales DDD.
- `entities/`: entidades con identidad e invariantes (p. ej. `User`, `Relato`).
- `value_objects/`: tipos inmutables con validaciones (p. ej. `Ubicacion`, `Multimedia`).
- `enums/`: enumeraciones de negocio (p. ej. `UserRole`, `TiposContenido`).
- `validators/`: validaciones de contenido y ubicación del dominio.
- `exceptions/`: excepciones específicas de dominio (no se exportan fuera del dominio).
- `failures/`: jerarquía unificada `Failure` y el tipo `Result` para casos de uso.
- `repositories/`: interfaces de acceso a persistencia y autenticación.
- `services/`: interfaces de servicios de dominio (analítica, geolocalización, etc.).
- `policies/`: políticas y reglas transversales (p. ej. moderación).
- `events/`: eventos de dominio para integración entre agregados.
- `usecases/`: orquestadores de reglas de negocio que usan los contratos.

## Convenciones de nombres
- Interfaces con prefijo `I` (p. ej. `IUserRepository`, `IAnalyticsService`).
- Casos de uso en español con sufijo `UseCase` y método `execute`.
- Entidades y value objects en `UpperCamelCase`. Enums en singular con valores serializados en `snake_case` si aplica.
- Archivos en `lower_snake_case.dart`.

## Errores y retornos
- Excepciones del dominio viven en `exceptions/` y NO deben salir a capas superiores.
- Los casos de uso devuelven `UseCaseResult<T>` que es `Future<Result<T, Failure>>`.
- Use `mapExceptionToFailure(error)` para convertir excepciones a `Failure`:
  - `ValidationFailure`, `NotFoundFailure`, `PermissionDeniedFailure`, `NetworkFailure`, `UnexpectedFailure`.
- No propagar excepciones crudas; capture y devuelva `FailureResult`.

## Guía rápida para casos de uso
- Dependan solo de interfaces del dominio (`repositories/`, `services/`).
- Validar entradas y lanzar excepciones de dominio o devolver `ValidationFailure` mapeado.
- Estructura recomendada: `try { ... return Success(...); } catch (e) { return FailureResult(mapExceptionToFailure(e)); }`.

## Compatibilidad y serialización
- Entidades proveen `toMap()`/`fromMap()` sin acoplar a proveedores concretos.
- Fechas en UTC. Conversión robusta desde `DateTime`, `int`, `double` o `String`.

## Ejemplo mínimo
- Repositorio (`repositories/user_repository.dart`): define el contrato `IUserRepository`.
- Caso de uso (`usecases/auth/register_user_usecase.dart`): orquesta registro y mapea errores a `Failure` devolviendo `Result`. 
