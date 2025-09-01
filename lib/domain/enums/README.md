# Enumeraciones (Enums)

Las enumeraciones modelan conjuntos finitos de valores del dominio (roles, tipos de contenido, estados de moderación, etc.).

## Principios
- Semánticas y estables (evitar cambios frecuentes en valores públicos).
- Conversión explícita a/desde `String` para serialización.

## Convenciones
- Nombre en singular (`UserRole`, `TiposContenido` puede ser singular si aplica).
- Métodos auxiliares `fromString(...)` y `get value` para persistencia/UI.
- Valores serializados en `snake_case` cuando se almacenan o se exponen.

## Ejemplo (patrón recomendado)
```dart
enum UserRole { admin, normal, invitado; 
  String get value => switch (this) {
    UserRole.admin => 'admin',
    UserRole.normal => 'normal',
    UserRole.invitado => 'invitado',
  };
  static UserRole fromString(String v) => switch (v) {
    'admin' => UserRole.admin,
    'normal' => UserRole.normal,
    'invitado' => UserRole.invitado,
    _ => UserRole.normal,
  };
}
```

## Buenas prácticas
- Mantener funciones de utilidad junto al enum.
- Evitar dependencias cíclicas; los enums no deben importar entidades.
- Documentar significado y uso de cada valor.
