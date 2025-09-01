/// Tipos de eventos culturales
enum TipoEvento {
  feria('feria', 'Feria tradicional'),
  festival('festival', 'Festival cultural'),
  celebracion('celebracion', 'Celebración religiosa/cultural'),
  taller('taller', 'Taller de artesanía/cultura'),
  exposicion('exposicion', 'Exposición artística'),
  otro('otro', 'Otro tipo');

  final String value;
  final String titulo;
  const TipoEvento(this.value, this.titulo);

  static TipoEvento fromString(String value) {
    return TipoEvento.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoEvento.otro,
    );
  }
}

/// Estados de una sugerencia de evento
enum EstadoSugerencia {
  pendiente('pendiente', 'Esperando revisión'),
  aprobada('aprobada', 'Aprobada y convertida a evento'),
  rechazada('rechazada', 'Rechazada por moderación');

  final String value;
  final String titulo;
  const EstadoSugerencia(this.value, this.titulo);

  static EstadoSugerencia fromString(String value) {
    return EstadoSugerencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoSugerencia.pendiente,
    );
  }
}
