import '../entities/saber_popular.dart';
import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../events/saber_popular_events.dart';
import '../enums/estado_moderacion.dart';

/// Comentario en un saber popular
class ComentarioSaber {
  final String id;
  final String texto;
  final String autorId;
  final String autorNombre;
  final DateTime fechaCreacion;
  final bool eliminado;

  const ComentarioSaber({
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

  factory ComentarioSaber.fromMap(Map<String, dynamic> map) => ComentarioSaber(
    id: map['id'],
    texto: map['texto'],
    autorId: map['autorId'],
    autorNombre: map['autorNombre'],
    fechaCreacion: map['fechaCreacion'].toDate(),
    eliminado: map['eliminado'] ?? false,
  );
}

/// Verificación de autenticidad de un saber popular
class VerificacionSaber {
  final String id;
  final String verificadorId;
  final String verificadorNombre;
  final DateTime fechaVerificacion;
  final bool esAutentico;
  final String? comentario;

  const VerificacionSaber({
    required this.id,
    required this.verificadorId,
    required this.verificadorNombre,
    required this.fechaVerificacion,
    required this.esAutentico,
    this.comentario,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'verificadorId': verificadorId,
    'verificadorNombre': verificadorNombre,
    'fechaVerificacion': fechaVerificacion,
    'esAutentico': esAutentico,
    'comentario': comentario,
  };

  factory VerificacionSaber.fromMap(Map<String, dynamic> map) => VerificacionSaber(
    id: map['id'],
    verificadorId: map['verificadorId'],
    verificadorNombre: map['verificadorNombre'],
    fechaVerificacion: map['fechaVerificacion'].toDate(),
    esAutentico: map['esAutentico'],
    comentario: map['comentario'],
  );
}

/// Agregado de Saber Popular
/// 
/// Representa el agregado completo de un saber popular, incluyendo sus comentarios,
/// verificaciones y métodos para manipular el agregado como un todo.
class SaberPopularAggregate {
  final SaberPopular _saber;
  final List<ComentarioSaber> _comentarios;
  final List<VerificacionSaber> _verificaciones;

  SaberPopularAggregate(this._saber, this._comentarios, this._verificaciones);

  // Getters
  SaberPopular get saber => _saber;
  List<ComentarioSaber> get comentarios => List.unmodifiable(_comentarios);
  List<VerificacionSaber> get verificaciones => List.unmodifiable(_verificaciones);

  // Eventos generados por este agregado
  List<SaberPopularCreado> _eventos = [];
  List<SaberPopularCreado> get eventos => List.unmodifiable(_eventos);
  void _limpiarEventos() => _eventos = [];

  // Métodos para manipular el agregado

  /// Agrega un comentario al saber popular
  SaberPopularAggregate agregarComentario({
    required String texto,
    required String autorId,
    required String autorNombre,
  }) {
    final comentarioId = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevoComentario = ComentarioSaber(
      id: comentarioId,
      texto: texto,
      autorId: autorId,
      autorNombre: autorNombre,
      fechaCreacion: DateTime.now(),
    );
    
    final nuevosComentarios = [..._comentarios, nuevoComentario];
    
    return SaberPopularAggregate(_saber, nuevosComentarios, _verificaciones);
  }

  /// Elimina un comentario del saber popular
  SaberPopularAggregate eliminarComentario({
    required String comentarioId,
    required String usuarioId,
  }) {
    final comentarioIndex = _comentarios.indexWhere((c) => c.id == comentarioId);
    if (comentarioIndex < 0) {
      return this;
    }
    
    final comentario = _comentarios[comentarioIndex];
    
    // Solo el autor del comentario o el autor del saber pueden eliminarlo
    if (comentario.autorId != usuarioId && _saber.autorId != usuarioId) {
      return this;
    }
    
    final comentarioEliminado = ComentarioSaber(
      id: comentario.id,
      texto: comentario.texto,
      autorId: comentario.autorId,
      autorNombre: comentario.autorNombre,
      fechaCreacion: comentario.fechaCreacion,
      eliminado: true,
    );
    
    final nuevosComentarios = [..._comentarios];
    nuevosComentarios[comentarioIndex] = comentarioEliminado;
    
    return SaberPopularAggregate(_saber, nuevosComentarios, _verificaciones);
  }

  /// Agrega una verificación de autenticidad al saber popular
  SaberPopularAggregate agregarVerificacion({
    required String verificadorId,
    required String verificadorNombre,
    required bool esAutentico,
    String? comentario,
  }) {
    final verificacionId = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevaVerificacion = VerificacionSaber(
      id: verificacionId,
      verificadorId: verificadorId,
      verificadorNombre: verificadorNombre,
      fechaVerificacion: DateTime.now(),
      esAutentico: esAutentico,
      comentario: comentario,
    );
    
    final nuevasVerificaciones = [..._verificaciones, nuevaVerificacion];
    
    _eventos.add(SaberPopularVerificado(
      userId: verificadorId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      esAutentico: esAutentico,
      comentario: comentario,
    ) as SaberPopularCreado);

    return SaberPopularAggregate(_saber, _comentarios, nuevasVerificaciones);
  }

  /// Actualiza el saber popular
  SaberPopularAggregate actualizarSaber({
    String? titulo,
    String? contenido,
    String? categoriaId,
    String? categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia>? imagenes,
    List<String>? etiquetas,
  }) {
    final cambios = <String, dynamic>{};
    
    if (titulo != null && titulo != _saber.titulo) {
      cambios['titulo'] = titulo;
    }
    
    if (contenido != null && contenido != _saber.contenido) {
      cambios['contenido'] = contenido;
    }
    
    if (categoriaId != null && categoriaId != _saber.categoriaId) {
      cambios['categoriaId'] = categoriaId;
    }
    
    if (categoriaNombre != null && categoriaNombre != _saber.categoriaNombre) {
      cambios['categoriaNombre'] = categoriaNombre;
    }
    
    if (ubicacion != null) {
      cambios['ubicacion'] = ubicacion.toMap();
    }
    
    if (imagenes != null) {
      cambios['imagenes'] = imagenes.map((m) => m.toMap()).toList();
    }
    
    if (etiquetas != null) {
      cambios['etiquetas'] = etiquetas;
    }
    
    if (cambios.isEmpty) {
      return this;
    }
    
    final saberActualizado = _saber.copyWith(
      titulo: titulo,
      contenido: contenido,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      imagenes: imagenes,
      etiquetas: etiquetas,
      fechaActualizacion: DateTime.now(),
    );
    
    _eventos.add(SaberPopularActualizado(
      userId: _saber.autorId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      cambios: cambios,
    ) as SaberPopularCreado);
    
    return SaberPopularAggregate(saberActualizado, _comentarios, _verificaciones);
  }

  /// Marca el saber popular como eliminado
  SaberPopularAggregate eliminarSaber({
    required String usuarioId,
    bool eliminacionPermanente = false,
  }) {
    // Solo el autor o un administrador puede eliminar
    if (_saber.autorId != usuarioId) {
      return this;
    }
    
    final saberEliminado = _saber.marcarEliminado();
    
    _eventos.add(SaberPopularEliminado(
      userId: usuarioId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      eliminacionPermanente: eliminacionPermanente,
    ) as SaberPopularCreado);
    
    return SaberPopularAggregate(saberEliminado, _comentarios, _verificaciones);
  }

  /// Restaura un saber popular eliminado
  SaberPopularAggregate restaurarSaber({
    required String usuarioId,
  }) {
    // Solo el autor o un administrador puede restaurar
    if (_saber.autorId != usuarioId) {
      return this;
    }
    
    if (!_saber.eliminado) {
      return this;
    }
    
    final saberRestaurado = _saber.restaurar();
    
    _eventos.add(SaberPopularRestaurado(
      userId: usuarioId,
      saberId: _saber.id,
      titulo: _saber.titulo,
    ) as SaberPopularCreado);
    
    return SaberPopularAggregate(saberRestaurado, _comentarios, _verificaciones);
  }

  /// Modera el saber popular
  SaberPopularAggregate moderarSaber({
    required String moderadorId,
    required bool aprobar,
    String? razon,
  }) {
    // No se puede moderar un saber ya procesado
    if (_saber.procesado) {
      return this;
    }
    
    final estadoAnterior = _saber.estado;
    final estadoNuevo = aprobar ? EstadoModeracion.activo : EstadoModeracion.oculto;
    
    // Si el estado no cambia, no hacemos nada
    if (estadoAnterior == estadoNuevo) {
      return this;
    }
    
    final saberModerado = _saber.moderar(aprobar: aprobar);
    
    _eventos.add(SaberPopularModerado(
      userId: moderadorId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      estadoAnterior: estadoAnterior,
      estadoNuevo: estadoNuevo,
      razon: razon,
    ) as SaberPopularCreado);
    
    return SaberPopularAggregate(saberModerado, _comentarios, _verificaciones);
  }

  /// Reporta el saber popular
  SaberPopularAggregate reportarSaber({
    required String reportadorId,
    required String razon,
  }) {
    // No se puede reportar un saber propio
    if (_saber.autorId == reportadorId) {
      return this;
    }
    
    final saberReportado = _saber.reportar();
    
    _eventos.add(SaberPopularReportado(
      userId: reportadorId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      razon: razon,
      reportadoPorId: reportadorId,
      reportesActuales: saberReportado.reportes,
    ) as SaberPopularCreado);
    
    return SaberPopularAggregate(saberReportado, _comentarios, _verificaciones);
  }

  /// Destaca el saber popular
  SaberPopularAggregate destacarSaber({
    required String moderadorId,
    required String razon,
  }) {
    // Solo se pueden destacar saberes activos
    if (_saber.estado != EstadoModeracion.activo) {
      return this;
    }
    
    // Aquí se podría actualizar un campo destacado si se implementa
    
    _eventos.add(SaberPopularDestacado(
      userId: moderadorId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      razon: razon,
    ) as SaberPopularCreado);
    
    return this;
  }

  /// Registra una valoración del saber popular
  SaberPopularAggregate valorarSaber({
    required String usuarioId,
    required int valoracion,
  }) {
    // Validar que la valoración esté entre 1 y 5
    if (valoracion < 1 || valoracion > 5) {
      return this;
    }
    
    // No se puede valorar un saber propio
    if (_saber.autorId == usuarioId) {
      return this;
    }
    
    // Aquí se podría actualizar un contador de valoraciones en el saber
    // si se implementa esa funcionalidad
    
    _eventos.add(SaberPopularValorado(
      userId: usuarioId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      valoracion: valoracion,
    ) as SaberPopularCreado);
    
    return this;
  }

  /// Registra que el saber popular ha sido compartido
  SaberPopularAggregate compartirSaber({
    required String usuarioId,
    required String plataforma,
  }) {
    _eventos.add(SaberPopularCompartido(
      userId: usuarioId,
      saberId: _saber.id,
      titulo: _saber.titulo,
      plataforma: plataforma,
    ) as SaberPopularCreado);
    
    return this;
  }

  /// Obtiene y limpia los eventos generados
  List<SaberPopularCreado> obtenerYLimpiarEventos() {
    final eventosActuales = [..._eventos];
    _limpiarEventos();
    return eventosActuales;
  }
}
