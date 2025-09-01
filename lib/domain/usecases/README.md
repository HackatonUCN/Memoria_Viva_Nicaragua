# Casos de Uso (Use Cases)

Los casos de uso orquestan reglas de negocio. Dependen únicamente de interfaces del dominio y retornan un `Result` tipado para flujos de éxito y error controlados.

## Principios
- Sin dependencias a UI ni infraestructura.
- Una responsabilidad clara por caso de uso.
- Nombres en español y orientados a acciones (crear, obtener, actualizar, eliminar, moderar, etc.).

## Firma estándar
- `typedef UseCaseResult<T> = Future<Result<T, Failure>>;`
- Método público: `Future<Result<T, Failure>> execute(...)`.
- Resultado:
  - `Success<T, Failure>(valor)` en éxito.
  - `FailureResult<T, Failure>(failure)` en error.

## Manejo de errores
- Capture excepciones del dominio y conviértales con `mapExceptionToFailure`.
- No lance excepciones a capas superiores; devuelva `FailureResult`.
- Mapeos habituales: credenciales inválidas, red, permisos, validación, no encontrado.

## Dependencias
- Repositorios de `repositories/` (interfaces `I...Repository`).
- Servicios de `services/` (interfaces `I...Service`).

## Convenciones
- Archivo: `accion_recurso_usecase.dart`.
- Clase: `AccionRecursoUseCase`.
- Método: `execute`.
- Parámetros nombrados y requeridos para claridad.

## Estructura de carpetas actual
- `auth/`, `relatos/`, `saberes/`, `eventos/`, `categorias/`, `preferences/`, `user/`.

## Ejemplo (resumido)
```dart
class LoginWithGoogleUseCase {
  final IUserRepository _userRepository;
  LoginWithGoogleUseCase(this._userRepository);

  UseCaseResult<User> execute() async {
    try {
      final user = await _userRepository.iniciarSesionGoogle();
      return Success<User, Failure>(user);
    } catch (e) {
      return FailureResult<User, Failure>(mapExceptionToFailure(e));
    }
  }
}
```

## Checklist al crear un caso de uso
- Defina dependencias por constructor (interfaces del dominio).
- Valide entradas y estados previos si corresponde.
- Use `try/catch` y devuelva `Success`/`FailureResult`.
- No acceda a Firebase ni a implementaciones concretas.
- Añada pruebas unitarias con dobles de prueba de repositorios/servicios.

## Antipatrones a evitar
- Acoplar a paquetes externos o infraestructura.
- Devolver `null` en lugar de `Result`.
- Ocultar errores sin mapear a `Failure`.
- Lógica compleja no relacionada con el dominio.
