# Migración de Categorías

Esta utilidad permite migrar categorías desde un archivo JSON a Firestore sin tener que hacerlo manualmente.

## Archivo de categorías

Las categorías se definen en el archivo `assets/config/categories_seed.json` con la siguiente estructura:

```json
[
  {
    "id": "categoria_id",
    "nombre": "Nombre de la Categoría",
    "descripcion": "Descripción detallada",
    "tipo": "relato",  // Valores posibles: relato, saber, evento, juego
    "icono": "nombre_icono",
    "color": "#HEXCOLOR",
    "orden": 1,
    "activa": true,
    "categoriaPadreId": null  // O el ID de la categoría padre si es subcategoría
  },
  // ... más categorías
]
```

## Solución de problemas de permisos

Si encuentras errores de permisos como `PERMISSION_DENIED` o `Missing or insufficient permissions`, debes:

1. Asegurarte de que estás autenticado con una cuenta que tenga permisos de administrador, o
2. Modificar temporalmente las reglas de seguridad de Firestore para permitir la migración:

```bash
# 1. Hacer backup de las reglas actuales
cp firestore.rules firestore.rules.backup

# 2. Usar las reglas temporales para la migración
cp firestore.rules.temp firestore.rules

# 3. Implementar las reglas temporales
firebase deploy --only firestore:rules

# 4. Ejecutar la migración
flutter run -t lib/utils/run_migration.dart

# 5. Restaurar las reglas originales
cp firestore.rules.backup firestore.rules
firebase deploy --only firestore:rules
```

> ⚠️ **ADVERTENCIA**: Las reglas temporales permiten escritura completa en la colección de categorías. Úsalas solo durante la migración y restaura las reglas originales inmediatamente después.

## Formas de ejecutar la migración

### 1. Durante el inicio de la aplicación (automático)

En modo desarrollo (`dev`), la aplicación intentará migrar las categorías automáticamente al iniciar. Esto está configurado en `main.dart`.

### 2. Script independiente

Para ejecutar la migración sin iniciar toda la aplicación:

```bash
flutter run -t lib/utils/run_migration.dart
```

Para forzar la actualización de categorías existentes:

```bash
flutter run -t lib/utils/run_migration.dart --dart-define=FORCE_UPDATE_CATEGORIAS=true
```

## Comportamiento

- Por defecto, la migración **no sobrescribe** categorías existentes
- Con `forceUpdate=true`, se actualizarán todas las categorías
- La migración usa operaciones batch para eficiencia
- Se muestran estadísticas al finalizar (categorías nuevas, actualizadas, existentes)

## Consideraciones

- Los IDs de las categorías deben ser únicos
- Se recomienda usar IDs descriptivos (ej: `relato_tradiciones`)
- La migración verifica duplicados por nombre y tipo
- El campo `tipo` debe coincidir con los valores de `TipoContenido` en la aplicación