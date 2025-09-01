# Objetos de Valor (Value Objects)

Los objetos de valor encapsulan conceptos inmutables sin identidad propia (p. ej. `Ubicacion`, `Multimedia`). Su igualdad depende de sus atributos y deben validar su estado al crearse.

## Principios
- Inmutables: todos los campos `final`.
- Igualdad por valor (idealmente sobreescribir `==` y `hashCode` si se usan en colecciones/claves).
- Validación en fábricas/constructores; lanzar excepciones de `value_object_exception.dart` o usar validadores.

## Convenciones
- Nombre en `UpperCamelCase`.
- Fábricas estáticas con validación de entradas.
- Métodos de ayuda para serialización si aplica.

## Ejemplos
- `Ubicacion`: latitud/longitud válidas, opcional nivel de detalle (departamento, municipio).
- `Multimedia`: URLs/paths y metadatos válidos (tipo, tamaño, mime).

## Buenas prácticas
- No dependas de servicios externos ni IO.
- Mantén funciones puras y sin efectos secundarios.
- Provee utilidades para normalizar datos (trims, lowercases, rangos) dentro del VO.
