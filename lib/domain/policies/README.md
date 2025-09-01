# Políticas de Dominio (Policies)

Las políticas son reglas transversales que aplican sobre uno o más agregados (p. ej. moderación de contenido). Encapsulan decisiones y umbrales que pueden cambiar sin modificar entidades/VOs.

## Principios
- Determinísticas y puras: dada una entrada, devuelven siempre el mismo resultado.
- Independientes de infraestructura; parametrizables.
- Claras sobre entradas y salidas (booleans, decisiones, razones).

## Ejemplo: Moderación
- Archivo: `moderacion_policy.dart`.
- Objetivo: decidir si un contenido cumple estándares antes de publicarse o promoverse.
- Entradas: texto, metadatos, señales (p. ej. reportes previos).
- Salidas: permitido/denegado y lista de razones.

## Buenas prácticas
- Evitar dependencias a tiempo real; si se requieren señales externas, inyectarlas como datos de entrada.
- Mantener las razones en español y aptas para UI.
- Versionar reglas cuando cambien para trazabilidad.
