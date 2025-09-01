# Eventos de Dominio (Domain Events)

Los eventos de dominio representan hechos significativos ocurridos en el dominio (p. ej. `RelatoCreado`, `SaberModerado`). Permiten desacoplar acciones posteriores (notificaciones, estadísticas) respetando límites de agregados.

## Principios
- Hechos pasados (nombres en pasado: "Creado", "Actualizado").
- Inmutables y con timestamp.
- No deben contener lógica, sólo datos necesarios.

## Uso típico
- Un caso de uso emite un evento tras una operación exitosa.
- Servicios suscriptores reaccionan (analítica, notificaciones).
- Mantiene transacciones limitadas al agregado; efectos secundarios fuera del flujo principal.

## Carpeta actual
- `domain_event.dart`: base del evento.
- Archivos por contexto: `contenido_events.dart`, `evento_cultural_events.dart`, `juego_events.dart`, `saber_popular_events.dart`, `user_events.dart`.

## Buenas prácticas
- Incluir IDs relevantes y contexto mínimo suficiente.
- Evitar referencias a objetos completos; preferir IDs/valores primitivos.
- Documentar semántica y cuándo se emite cada evento.
