/// Tipos de juegos disponibles
enum TipoJuego {
  adivinanza('adivinanza', 'Adivinanzas'),
  completar_frase('completar_frase', 'Completar frases'),
  trivia('trivia', 'Trivia cultural'),
  ahorcado('ahorcado', 'Ahorcado'),
  sopa_letras('sopa_letras', 'Sopa de letras'),
  puzzle('puzzle', 'Rompecabezas');

  final String value;
  final String titulo;
  const TipoJuego(this.value, this.titulo);

  static TipoJuego fromString(String value) {
    return TipoJuego.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoJuego.trivia,
    );
  }
}

/// Nivel de dificultad
enum NivelDificultad {
  facil('facil', 'Fácil'),
  medio('medio', 'Medio'),
  dificil('dificil', 'Difícil');

  final String value;
  final String titulo;
  const NivelDificultad(this.value, this.titulo);

  static NivelDificultad fromString(String value) {
    return NivelDificultad.values.firstWhere(
      (n) => n.value == value,
      orElse: () => NivelDificultad.medio,
    );
  }
}

/// Estado de un juego
enum EstadoJuego {
  no_iniciado('no_iniciado', 'No iniciado'),
  en_progreso('en_progreso', 'En progreso'),
  completado('completado', 'Completado'),
  fallido('fallido', 'Fallido');

  final String value;
  final String titulo;
  const EstadoJuego(this.value, this.titulo);

  static EstadoJuego fromString(String value) {
    return EstadoJuego.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoJuego.no_iniciado,
    );
  }
}
