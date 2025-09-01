/// Tipos de contenido en la aplicación
enum TipoContenido {
  relato('relato', 'Relatos y Memorias'),
  saber('saber', 'Saberes Populares'),
  evento('evento', 'Eventos Culturales'),
  juego('juego', 'Juegos Didácticos');

  final String value;
  final String titulo;
  const TipoContenido(this.value, this.titulo);

  /// Obtiene el tipo desde un string
  static TipoContenido fromString(String value) {
    try {
      return TipoContenido.values.firstWhere(
        (t) => t.value == value,
      );
    } catch (_) {
      return TipoContenido.relato; // Valor por defecto
    }
  }
}

/// Visibilidad del contenido
enum Visibilidad {
  publico('publico', 'Visible para todos'),
  privado('privado', 'Solo visible para el autor'),
  borrador('borrador', 'En borrador');

  final String value;
  final String titulo;
  const Visibilidad(this.value, this.titulo);

  static Visibilidad fromString(String value) {
    try {
      return Visibilidad.values.firstWhere(
        (v) => v.value == value,
      );
    } catch (_) {
      return Visibilidad.publico; // Valor por defecto
    }
  }
}