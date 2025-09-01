# Validadores (Validators)

Los validadores encapsulan reglas de validación reutilizables para contenido, ubicaciones y otras estructuras del dominio.

## Principios
- Funciones puras y deterministas.
- No dependen de IO ni de infraestructura.
- Devuelven colecciones de errores o lanzan excepciones de validación específicas del dominio.

## Patrones
- Validación acumulativa: coleccionar errores y reportarlos en bloque (p. ej. `ContenidoValidationException` con `errores`).
- Validación corta: lanzar en la primera violación cuando sea crítico.
- Mensajes en español y con contexto.

## Relación con Failures
- Los casos de uso deben capturar `ContenidoValidationException` (u otras) y mapearlas a `ValidationFailure` con `details` útiles.

## Buenas prácticas
- Mantener validaciones atómicas y reutilizables.
- Separar validaciones de formato (longitud, regex) de semánticas (reglas del negocio).
- Incluir claves/códigos por campo para facilitar la UI.
