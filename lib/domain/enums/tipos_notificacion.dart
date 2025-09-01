/// Tipos de notificaciones en la aplicación
enum TipoNotificacion {
  // Eventos Culturales
  evento_sugerencia_aprobada('evento_sugerencia_aprobada', 'Sugerencia de evento aprobada'),
  evento_sugerencia_rechazada('evento_sugerencia_rechazada', 'Sugerencia de evento rechazada'),
  evento_nuevo('evento_nuevo', 'Nuevo evento cultural'),
  evento_proximo('evento_proximo', 'Evento próximo a ocurrir'),
  
  // Relatos
  relato_nuevo('relato_nuevo', 'Nuevo relato publicado'),
  relato_reportado('relato_reportado', 'Relato reportado'),
  relato_moderado('relato_moderado', 'Relato moderado'),
  relato_comentado('relato_comentado', 'Comentario en relato'),
  
  // Saberes Populares
  saber_nuevo('saber_nuevo', 'Nuevo saber popular'),
  saber_reportado('saber_reportado', 'Saber popular reportado'),
  saber_moderado('saber_moderado', 'Saber popular moderado'),
  saber_comentado('saber_comentado', 'Comentario en saber popular'),
  
  // Sistema
  cuenta_verificada('cuenta_verificada', 'Cuenta verificada'),
  contenido_viral('contenido_viral', 'Contenido popular');

  final String value;
  final String titulo;
  const TipoNotificacion(this.value, this.titulo);

  static TipoNotificacion fromString(String value) {
    return TipoNotificacion.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoNotificacion.evento_nuevo,
    );
  }
}
