# Fallos (Failures) y Result

La capa de dominio usa una jerarquía unificada de fallos (`Failure`) y un tipo `Result` ligero para manejar errores sin lanzar excepciones hacia capas superiores.

## Jerarquía de `Failure`
- `Failure` (base): `message`, `code?`, `details?`.
- Especializaciones comunes:
  - `ValidationFailure`
  - `NotFoundFailure`
  - `PermissionDeniedFailure`
  - `NetworkFailure`
  - `UnexpectedFailure`

## Tipo `Result`
- `Success<T, E>(value)` y `FailureResult<T, E>(error)`.
- Utilidad: `when({ success: ..., failure: ... })`, `isSuccess`, `isFailure`.
- Alias para casos de uso: `UseCaseResult<T> = Future<Result<T, Failure>>`.

## Mapeo de excepciones
- Usar `mapExceptionToFailure(error)` para convertir excepciones del dominio a `Failure`.
- Cubre autenticación, saberes, relatos, eventos, categorías y validaciones genéricas.

## Ejemplo de uso en un caso de uso
```dart
UseCaseResult<User> execute() async {
  try {
    final user = await _userRepository.iniciarSesionGoogle();
    return Success<User, Failure>(user);
  } catch (e) {
    return FailureResult<User, Failure>(mapExceptionToFailure(e));
  }
}
```

## Buenas prácticas
- No devuelvas excepciones crudas; encapsula en `Failure`.
- Incluye `code`/`details` cuando aporte debugging o UX.
- Mantén `details` serializable (Map/List/valor simple) cuando sea posible.
