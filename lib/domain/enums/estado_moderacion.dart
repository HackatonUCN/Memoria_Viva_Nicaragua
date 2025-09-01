/// Estado de moderación del contenido
enum EstadoModeracion {
  activo('activo', 'Activo y visible'),
  pendiente('pendiente', 'Pendiente de revisión'),
  reportado('reportado', 'Reportado por usuarios'),
  oculto('oculto', 'Oculto por moderación'),
  rechazado('rechazado', 'Rechazado');

  final String value;
  final String titulo;
  const EstadoModeracion(this.value, this.titulo);

  static EstadoModeracion fromString(String value) {
    return EstadoModeracion.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoModeracion.activo,
    );
  }
}