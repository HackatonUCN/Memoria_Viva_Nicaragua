# Entidades (Entities)

Las entidades representan objetos con identidad estable (ID) y reglas de negocio. Mantienen invariantes y exponen operaciones coherentes con el lenguaje del dominio.

## Principios
- Identidad única e inmutable (campo `id`).
- Invariantes validadas en el constructor (asserts) o fábricas dedicadas.
- Métodos que preservan consistencia y actualizan `ultimaModificacion` si aplica.

## Convenciones
- Nombre en `UpperCamelCase` (p. ej. `User`, `Relato`).
- Constructor con asserts para invariantes mínimas.
- Fábricas `crear(...)` para inicialización con defaults y tiempos en UTC.
- Método `copyWith` para cambios inmutables.
- Serialización: `toMap()`/`fromMap()` sin acoplar a proveedores.

## Ejemplo (extracto de `User`)
```dart
class User {
  final String id;
  final String nombre;
  final String email;
  // ...
  User({ required this.id, required this.nombre, required this.email, /* ... */ })
      : assert(id != ''),
        assert(nombre.trim() != ''),
        assert(email.trim() != '' && email.contains('@'));

  User copyWith({ String? nombre, /* ... */ }) { /* ... */ }

  Map<String, dynamic> toMap() { /* ... */ }
  factory User.fromMap(Map<String, dynamic> map) { /* ... */ }
}
```

## Fechas y zonas horarias
- Usar UTC para `fechaRegistro` y `ultimaModificacion`.
- Proveer conversión robusta desde `DateTime`, `int`, `double`, `String`.

## Buenas prácticas
- Evitar lógica de persistencia o de infraestructura.
- Mantener métodos que representen acciones del dominio (p. ej. `actualizarEstadisticas`).
- No exponer campos mutables; preferir patrones inmutables.
