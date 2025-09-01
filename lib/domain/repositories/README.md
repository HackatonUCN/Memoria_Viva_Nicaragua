# Repositorios (Repositories)

Los repositorios son contratos que abstraen el acceso a datos (Firestore, REST, caché, etc.). Aquí solo se definen interfaces (`abstract class`) con prefijo `I`. Las implementaciones viven en la capa de infraestructura.

## Principios
- Solo contratos, sin detalles técnicos.
- Métodos orientados a casos de uso y al lenguaje del dominio.
- Tipos del dominio en firmas (e.g., `User`, `Relato`).
- Nombres en español, parámetros nombrados.

## Convenciones
- Nombre de interfaz: `IRecursoRepository` (p. ej. `IUserRepository`).
- Firma asíncrona (`Future`/`Stream`).
- No retornar `null` salvo cuando el recurso puede no existir; preferir `Future<User?>` vs excepciones.
- Mantener operaciones CRUD y queries comunes.

## Ejemplo (extracto)
```dart
abstract class IUserRepository {
  Future<User?> obtenerUsuarioActual();
  Future<User> registrarEmail({required String email, required String password, required String nombre});
  Future<User> iniciarSesionGoogle();
  Future<void> cerrarSesion();
  Stream<User?> observarUsuarioActual();
}
```

## Errores
- Lanza excepciones de dominio definidas en `exceptions/` (p. ej. `UserNotFoundException`, `NetworkException`).
- Los casos de uso convertirán estas excepciones con `mapExceptionToFailure`.

## Buenas prácticas
- Mantener métodos atómicos y explícitos.
- No mezclar lógica de autorización aquí; delegarla a casos de uso/policies.
- Usar IDs y filtros claros; evitar parámetros ambiguos.
