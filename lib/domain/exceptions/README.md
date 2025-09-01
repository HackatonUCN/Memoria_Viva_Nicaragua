# Excepciones de Dominio (Exceptions)

Las excepciones en `exceptions/` representan errores específicos del dominio (autenticación, relatos, saberes, eventos, categorías, value objects, etc.). No deben salir de la capa de dominio sin convertirse a `Failure`.

## Principios
- Específicas y semánticas (e.g., `EmailAlreadyInUseException`).
- Incluyen `message`, `code?` y, opcionalmente, `value/details` útiles para diagnóstico.
- No dependen de paquetes externos.

## Categorías presentes
- `AuthException` y derivadas (credenciales, verificación, permisos, red, sesión, Google/Apple, cuenta desactivada).
- `RelatoException` y derivadas.
- `SaberException` y derivadas.
- `EventoException` y derivadas (incluye sugerencias).
- `CategoriaException` y derivadas.
- `ValueObjectException`.

## Relación con Failures
- Convertir SIEMPRE con `mapExceptionToFailure(error)` antes de retornar desde un caso de uso.
- Mapeos típicos: validación → `ValidationFailure`, no encontrado → `NotFoundFailure`, permisos → `PermissionDeniedFailure`, red → `NetworkFailure`.

## Buenas prácticas
- Proveer factorías útiles (e.g., `UserNotFoundException.withId(id)`).
- Usar `code` estable para permitir manejo en UI/infra.
- No capturar silenciosamente; si se crea una excepción, debe manejarse en el caso de uso.
