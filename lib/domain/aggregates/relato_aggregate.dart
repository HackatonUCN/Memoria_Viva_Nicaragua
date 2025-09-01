import '../entities/relato.dart';
import '../events/domain_event.dart';
import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../events/contenido_events.dart';
import '../enums/estado_moderacion.dart';
import '../enums/tipos_contenido.dart';

/// Comentario en un relato
class Comentario {
  final String id;
  final String texto;
  final String autorId;
  final String autorNombre;
  final DateTime fechaCreacion;
  final bool eliminado;

  const Comentario({
    required this.id,
    required this.texto,
    required this.autorId,
    required this.autorNombre,
    required this.fechaCreacion,
    this.eliminado = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'texto': texto,
    'autorId': autorId,
    'autorNombre': autorNombre,
    'fechaCreacion': fechaCreacion,
    'eliminado': eliminado,
  };

  factory Comentario.fromMap(Map<String, dynamic> map) => Comentario(
    id: map['id'],
    texto: map['texto'],
    autorId: map['autorId'],
    autorNombre: map['autorNombre'],
    fechaCreacion: map['fechaCreacion'].toDate(),
    eliminado: map['eliminado'] ?? false,
  );
}

/// Agregado de Relato
/// 
/// Representa el agregado completo de un relato, incluyendo sus comentarios
/// y métodos para manipular el agregado como un todo.
class RelatoAggregate {
  final Relato _relato;
  final List<Comentario> _comentarios;

  RelatoAggregate(this._relato, this._comentarios);

  // Getters
  Relato get relato => _relato;
  List<Comentario> get comentarios => List.unmodifiable(_comentarios);

  // Eventos generados por este agregado
  List<DomainEvent> _eventos = [];
  List<DomainEvent> get eventos => List.unmodifiable(_eventos);
  void _limpiarEventos() => _eventos = [];

  // Métodos para manipular el agregado

  /// Agrega un comentario al relato
  RelatoAggregate agregarComentario({
    required String texto,
    required String autorId,
    required String autorNombre,
  }) {
    final comentarioId = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevoComentario = Comentario(
      id: comentarioId,
      texto: texto,
      autorId: autorId,
      autorNombre: autorNombre,
      fechaCreacion: DateTime.now(),
    );
    
    final nuevosComentarios = [..._comentarios, nuevoComentario];
    
    _eventos.add(ContenidoComentado(
      userId: autorId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      comentarioId: comentarioId,
      texto: texto,
    ));
    
    return RelatoAggregate(_relato, nuevosComentarios);
  }

  /// Elimina un comentario del relato
  RelatoAggregate eliminarComentario({
    required String comentarioId,
    required String usuarioId,
  }) {
    final comentarioIndex = _comentarios.indexWhere((c) => c.id == comentarioId);
    if (comentarioIndex < 0) {
      return this;
    }
    
    final comentario = _comentarios[comentarioIndex];
    
    // Solo el autor del comentario o el autor del relato pueden eliminarlo
    if (comentario.autorId != usuarioId && _relato.autorId != usuarioId) {
      return this;
    }
    
    final comentarioEliminado = Comentario(
      id: comentario.id,
      texto: comentario.texto,
      autorId: comentario.autorId,
      autorNombre: comentario.autorNombre,
      fechaCreacion: comentario.fechaCreacion,
      eliminado: true,
    );
    
    final nuevosComentarios = [..._comentarios];
    nuevosComentarios[comentarioIndex] = comentarioEliminado;
    
    return RelatoAggregate(_relato, nuevosComentarios);
  }

  /// Actualiza el relato
  RelatoAggregate actualizarRelato({
    String? titulo,
    String? descripcion,
    Ubicacion? ubicacion,
    List<Multimedia>? multimedia,
    List<String>? etiquetas,
  }) {
    final cambios = <String, dynamic>{};
    
    if (titulo != null && titulo != _relato.titulo) {
      cambios['titulo'] = titulo;
    }
    
    if (descripcion != null && descripcion != _relato.contenido) {
      cambios['descripcion'] = descripcion;
    }
    
    if (ubicacion != null) {
      cambios['ubicacion'] = ubicacion.toMap();
    }
    
    if (multimedia != null) {
      cambios['multimedia'] = multimedia.map((m) => m.toMap()).toList();
    }
    
    if (etiquetas != null) {
      cambios['etiquetas'] = etiquetas;
    }
    
    if (cambios.isEmpty) {
      return this;
    }
    
    final relatoActualizado = _relato.copyWith(
      titulo: titulo,
      contenido: descripcion,
      ubicacion: ubicacion,
      multimedia: multimedia,
      etiquetas: etiquetas,
      fechaActualizacion: DateTime.now(),
    );
    
    _eventos.add(ContenidoActualizado(
      userId: _relato.autorId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      cambios: cambios,
    ));
    
    return RelatoAggregate(relatoActualizado, _comentarios);
  }

  /// Marca el relato como eliminado
  RelatoAggregate eliminarRelato({
    required String usuarioId,
    bool eliminacionPermanente = false,
  }) {
    // Solo el autor o un administrador puede eliminar
    if (_relato.autorId != usuarioId) {
      return this;
    }
    
    final relatoEliminado = _relato.marcarEliminado();
    
    _eventos.add(ContenidoEliminado(
      userId: usuarioId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      titulo: _relato.titulo,
      eliminacionPermanente: eliminacionPermanente,
    ));
    
    return RelatoAggregate(relatoEliminado, _comentarios);
  }

  /// Restaura un relato eliminado
  RelatoAggregate restaurarRelato({
    required String usuarioId,
  }) {
    // Solo el autor o un administrador puede restaurar
    if (_relato.autorId != usuarioId) {
      return this;
    }
    
    if (!_relato.eliminado) {
      return this;
    }
    
    final relatoRestaurado = _relato.restaurar();
    
    _eventos.add(ContenidoRestaurado(
      userId: usuarioId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      titulo: _relato.titulo,
    ));
    
    return RelatoAggregate(relatoRestaurado, _comentarios);
  }

  /// Modera el relato
  RelatoAggregate moderarRelato({
    required String moderadorId,
    required bool aprobar,
    String? razon,
  }) {
    // No se puede moderar un relato ya procesado
    if (_relato.procesado) {
      return this;
    }
    
    final estadoAnterior = _relato.estado;
    final estadoNuevo = aprobar ? EstadoModeracion.activo : EstadoModeracion.oculto;
    
    // Si el estado no cambia, no hacemos nada
    if (estadoAnterior == estadoNuevo) {
      return this;
    }
    
    final relatoModerado = _relato.moderar(aprobar: aprobar);
    
    _eventos.add(ContenidoModerado(
      userId: moderadorId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      estadoAnterior: estadoAnterior,
      estadoNuevo: estadoNuevo,
      razon: razon,
    ));
    
    return RelatoAggregate(relatoModerado, _comentarios);
  }

  /// Reporta el relato
  RelatoAggregate reportarRelato({
    required String reportadorId,
    required String razon,
  }) {
    // No se puede reportar un relato propio
    if (_relato.autorId == reportadorId) {
      return this;
    }
    
    final relatoReportado = _relato.reportar();
    
    _eventos.add(ContenidoReportado(
      userId: reportadorId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      razon: razon,
      reportadoPorId: reportadorId,
    ));
    
    return RelatoAggregate(relatoReportado, _comentarios);
  }

  /// Destaca el relato
  RelatoAggregate destacarRelato({
    required String moderadorId,
    required String razon,
  }) {
    // Solo se pueden destacar relatos activos
    if (_relato.estado != EstadoModeracion.activo) {
      return this;
    }
    
    // No hay un campo 'destacado' en Relato, pero podríamos
    // agregar una propiedad al relato o usar algún otro mecanismo para marcarlo como destacado
    // Por ahora, solo actualizamos la fecha
    final relatoDestacado = _relato.copyWith(
      fechaActualizacion: DateTime.now(),
    );
    
    // TODO: Implementar lógica para marcar el relato como destacado
    // Por ejemplo, guardar en una colección separada de 'relatos_destacados'
    
    _eventos.add(ContenidoDestacado(
      userId: moderadorId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      razon: razon,
    ));
    
    return RelatoAggregate(relatoDestacado, _comentarios);
  }

  /// Registra una valoración del relato
  RelatoAggregate valorarRelato({
    required String usuarioId,
    required int valoracion,
  }) {
    // Validar que la valoración esté entre 1 y 5
    if (valoracion < 1 || valoracion > 5) {
      return this;
    }
    
    // No se puede valorar un relato propio
    if (_relato.autorId == usuarioId) {
      return this;
    }
    
    // Aquí se podría actualizar un contador de valoraciones en el relato
    // si se implementa esa funcionalidad
    
    _eventos.add(ContenidoValorado(
      userId: usuarioId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      valoracion: valoracion,
    ));
    
    return this;
  }

  /// Registra que el relato ha sido compartido
  RelatoAggregate compartirRelato({
    required String usuarioId,
    required String plataforma,
  }) {
    _eventos.add(ContenidoCompartido(
      userId: usuarioId,
      contenidoId: _relato.id,
      tipo: TipoContenido.relato,
      plataforma: plataforma,
    ));
    
    return this;
  }

  /// Obtiene y limpia los eventos generados
  List<DomainEvent> obtenerYLimpiarEventos() {
    final eventosActuales = [..._eventos];
    _limpiarEventos();
    return eventosActuales;
  }
}
