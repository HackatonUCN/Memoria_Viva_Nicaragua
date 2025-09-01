# Agregados del Dominio

En Domain-Driven Design (DDD), un agregado es un grupo de objetos relacionados que se tratan como una unidad para propósitos de cambios de datos. Cada agregado tiene una raíz y un límite. La raíz es una entidad específica dentro del agregado, y el límite define qué está dentro del agregado.

## Agregados en Memoria Viva Nicaragua

### 1. Agregado de Relato

**Raíz:** `Relato`

**Entidades y objetos de valor contenidos:**
- `Relato` (raíz)
- `Ubicacion` (value object)
- `Multimedia` (value object)
- `Comentario` (entidad)

**Invariantes:**
- Un relato debe tener un título y una descripción válidos
- Un relato debe estar asociado a un autor existente
- La ubicación debe ser válida si se proporciona
- Los archivos multimedia deben ser válidos si se proporcionan

### 2. Agregado de Saber Popular

**Raíz:** `SaberPopular`

**Entidades y objetos de valor contenidos:**
- `SaberPopular` (raíz)
- `Ubicacion` (value object)
- `Multimedia` (value object)
- `Comentario` (entidad)

**Invariantes:**
- Un saber popular debe tener un título y contenido válidos
- Un saber popular debe estar asociado a un autor existente
- Un saber popular debe pertenecer a una categoría válida
- La ubicación debe ser válida si se proporciona
- Los archivos multimedia deben ser válidos si se proporcionan

### 3. Agregado de Evento Cultural

**Raíz:** `EventoCultural`

**Entidades y objetos de valor contenidos:**
- `EventoCultural` (raíz)
- `Ubicacion` (value object)
- `Multimedia` (value object)
- `SugerenciaEvento` (entidad)

**Invariantes:**
- Un evento cultural debe tener un título, descripción y fechas válidas
- Un evento cultural debe estar asociado a un autor existente
- La ubicación debe ser válida y es obligatoria
- Las fechas de inicio y fin deben ser coherentes

### 4. Agregado de Usuario

**Raíz:** `User`

**Entidades y objetos de valor contenidos:**
- `User` (raíz)
- `UserPreferences` (entidad)
- `UserStats` (value object)
- `Notificacion` (entidad)

**Invariantes:**
- Un usuario debe tener un correo electrónico único y válido
- Un usuario debe tener un nombre de usuario único
- Las preferencias del usuario deben ser coherentes
- Las estadísticas del usuario deben reflejar su actividad real

### 5. Agregado de Juego

**Raíz:** `JuegoBase`

**Entidades y objetos de valor contenidos:**
- `JuegoBase` (raíz)
- `Trivia`, `Adivinanza`, `Ahorcado`, etc. (entidades derivadas)
- `Pregunta` (entidad)
- `Respuesta` (value object)
- `Puntaje` (value object)

**Invariantes:**
- Un juego debe tener un título y descripción válidos
- Un juego debe tener un nivel de dificultad válido
- Las preguntas y respuestas deben ser coherentes según el tipo de juego
- Los puntajes deben calcularse según las reglas específicas del juego

## Reglas de consistencia entre agregados

1. **Referencias entre agregados:**
   - Los agregados se refieren entre sí solo por identidad (ID), no por referencia directa.
   - Por ejemplo, un `Relato` se refiere a su autor mediante `autorId`, no mediante una referencia directa al objeto `User`.

2. **Transacciones:**
   - Las transacciones deben respetar los límites de los agregados.
   - Una transacción puede modificar un solo agregado.
   - Para cambios que afectan a múltiples agregados, se utilizan eventos de dominio.

3. **Consultas:**
   - Las consultas pueden atravesar múltiples agregados.
   - Los repositorios pueden proporcionar métodos para recuperar datos de múltiples agregados para casos de uso específicos.

## Implementación en el código

En nuestro código, los agregados están implícitamente definidos por la estructura de nuestras entidades y value objects. Para hacer esta estructura más explícita, se recomienda:

1. Asegurar que los repositorios estén organizados por agregado (uno por raíz de agregado).
2. Implementar métodos en las raíces de agregado para gestionar las operaciones que afectan a todo el agregado.
3. Utilizar eventos de dominio para coordinar cambios entre agregados.
4. Documentar claramente los límites de los agregados en los comentarios del código.
