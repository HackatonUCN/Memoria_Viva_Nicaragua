import '../entities/evento_cultural.dart';
import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../events/evento_cultural_events.dart';
import '../enums/estado_moderacion.dart';
import '../enums/tipos_evento.dart';

/// Sugerencia para un evento cultural
class SugerenciaEvento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final TipoEvento tipo;
  final Ubicacion ubicacion;
  final String usuarioId;
  final String usuarioNombre;
  final DateTime fechaSugerencia;
  final bool procesada;
  final bool aprobada;
  final String? comentarioModerador;
  final String? moderadorId;
  final DateTime? fechaProcesamiento;

  const SugerenciaEvento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipo,
    required this.ubicacion,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.fechaSugerencia,
    this.procesada = false,
    this.aprobada = false,
    this.comentarioModerador,
    this.moderadorId,
    this.fechaProcesamiento,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'fechaInicio': fechaInicio,
    'fechaFin': fechaFin,
    'tipo': tipo.value,
    'ubicacion': ubicacion.toMap(),
    'usuarioId': usuarioId,
    'usuarioNombre': usuarioNombre,
    'fechaSugerencia': fechaSugerencia,
    'procesada': procesada,
    'aprobada': aprobada,
    'comentarioModerador': comentarioModerador,
    'moderadorId': moderadorId,
    'fechaProcesamiento': fechaProcesamiento,
  };

  factory SugerenciaEvento.fromMap(Map<String, dynamic> map) => SugerenciaEvento(
    id: map['id'],
    titulo: map['titulo'],
    descripcion: map['descripcion'],
    fechaInicio: map['fechaInicio'].toDate(),
    fechaFin: map['fechaFin'].toDate(),
    tipo: TipoEvento.fromString(map['tipo']),
    ubicacion: Ubicacion.fromMap(map['ubicacion']),
    usuarioId: map['usuarioId'],
    usuarioNombre: map['usuarioNombre'],
    fechaSugerencia: map['fechaSugerencia'].toDate(),
    procesada: map['procesada'] ?? false,
    aprobada: map['aprobada'] ?? false,
    comentarioModerador: map['comentarioModerador'],
    moderadorId: map['moderadorId'],
    fechaProcesamiento: map['fechaProcesamiento']?.toDate(),
  );

  /// Crea una nueva sugerencia de evento
  factory SugerenciaEvento.crear({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required TipoEvento tipo,
    required Ubicacion ubicacion,
    required String usuarioId,
    required String usuarioNombre,
  }) {
    return SugerenciaEvento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipo: tipo,
      ubicacion: ubicacion,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fechaSugerencia: DateTime.now(),
    );
  }

  /// Procesa la sugerencia
  SugerenciaEvento procesar({
    required bool aprobar,
    required String moderadorId,
    String? comentario,
  }) {
    return SugerenciaEvento(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipo: tipo,
      ubicacion: ubicacion,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fechaSugerencia: fechaSugerencia,
      procesada: true,
      aprobada: aprobar,
      comentarioModerador: comentario,
      moderadorId: moderadorId,
      fechaProcesamiento: DateTime.now(),
    );
  }
}

/// Agregado de Evento Cultural
/// 
/// Representa el agregado completo de un evento cultural, incluyendo sus sugerencias
/// y métodos para manipular el agregado como un todo.
class EventoCulturalAggregate {
  final EventoCultural _evento;
  final List<SugerenciaEvento> _sugerencias;

  EventoCulturalAggregate(this._evento, this._sugerencias);

  // Getters
  EventoCultural get evento => _evento;
  List<SugerenciaEvento> get sugerencias => List.unmodifiable(_sugerencias);

  // Eventos generados por este agregado
  List<dynamic> _eventos = [];
  List<dynamic> get eventos => List.unmodifiable(_eventos);
  void _limpiarEventos() => _eventos = [];

  // Métodos para manipular el agregado

  /// Agrega una sugerencia al evento cultural
  EventoCulturalAggregate agregarSugerencia({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required TipoEvento tipo,
    required Ubicacion ubicacion,
    required String usuarioId,
    required String usuarioNombre,
  }) {
    final nuevaSugerencia = SugerenciaEvento.crear(
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipo: tipo,
      ubicacion: ubicacion,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
    );
    
    final nuevasSugerencias = [..._sugerencias, nuevaSugerencia];
    
    // Aquí se podría agregar un evento de dominio para la sugerencia
    
    return EventoCulturalAggregate(_evento, nuevasSugerencias);
  }

  /// Procesa una sugerencia
  EventoCulturalAggregate procesarSugerencia({
    required String sugerenciaId,
    required bool aprobar,
    required String moderadorId,
    String? comentario,
  }) {
    final sugerenciaIndex = _sugerencias.indexWhere((s) => s.id == sugerenciaId);
    if (sugerenciaIndex < 0) {
      return this;
    }
    
    final sugerencia = _sugerencias[sugerenciaIndex];
    
    // No procesar sugerencias ya procesadas
    if (sugerencia.procesada) {
      return this;
    }
    
    final sugerenciaProcesada = sugerencia.procesar(
      aprobar: aprobar,
      moderadorId: moderadorId,
      comentario: comentario,
    );
    
    final nuevasSugerencias = [..._sugerencias];
    nuevasSugerencias[sugerenciaIndex] = sugerenciaProcesada;
    
    // Aquí se podría agregar un evento de dominio para el procesamiento
    
    return EventoCulturalAggregate(_evento, nuevasSugerencias);
  }

  /// Actualiza el evento cultural
  EventoCulturalAggregate actualizarEvento({
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoEvento? tipo,
    Ubicacion? ubicacion,
    List<Multimedia>? multimedia,
    List<String>? etiquetas,
  }) {
    final cambios = <String, dynamic>{};
    
    if (titulo != null && titulo != _evento.titulo) {
      cambios['titulo'] = titulo;
    }
    
    if (descripcion != null && descripcion != _evento.descripcion) {
      cambios['descripcion'] = descripcion;
    }
    
    if (fechaInicio != null && fechaInicio != _evento.fechaInicio) {
      cambios['fechaInicio'] = fechaInicio;
    }
    
    if (fechaFin != null && fechaFin != _evento.fechaFin) {
      cambios['fechaFin'] = fechaFin;
    }
    
    if (tipo != null && tipo != _evento.tipo) {
      cambios['tipo'] = tipo.value;
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
    
    final eventoActualizado = _evento.copyWith(
      nombre: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipo: tipo,
      ubicacion: ubicacion,
      imagenes: multimedia,
      fechaActualizacion: DateTime.now(),
    );
    
    // Aquí se podría agregar un evento de dominio para la actualización
    
    return EventoCulturalAggregate(eventoActualizado, _sugerencias);
  }

  /// Marca el evento cultural como eliminado
  EventoCulturalAggregate eliminarEvento({
    required String usuarioId,
    bool eliminacionPermanente = false,
  }) {
    // Solo el autor o un administrador puede eliminar
    if (_evento.creadoPorId != usuarioId) {
      return this;
    }
    
    final eventoEliminado = _evento.marcarEliminado();
    
    // Aquí se podría agregar un evento de dominio para la eliminación
    
    return EventoCulturalAggregate(eventoEliminado, _sugerencias);
  }

  /// Restaura un evento cultural eliminado
  EventoCulturalAggregate restaurarEvento({
    required String usuarioId,
  }) {
    // Solo el autor o un administrador puede restaurar
    if (_evento.creadoPorId != usuarioId) {
      return this;
    }
    
    if (!_evento.eliminado) {
      return this;
    }
    
    final eventoRestaurado = _evento.restaurar();
    
    // Aquí se podría agregar un evento de dominio para la restauración
    
    return EventoCulturalAggregate(eventoRestaurado, _sugerencias);
  }

  /// Modera el evento cultural
  EventoCulturalAggregate moderarEvento({
    required String moderadorId,
    required bool aprobar,
    String? razon,
  }) {
    // En EventoCultural no tenemos propiedades de moderación como en otras entidades
    // Implementamos una versión simplificada
    
    // Crear una copia actualizada del evento con la fecha de actualización
    final eventoModerado = _evento.copyWith(
      fechaActualizacion: DateTime.now(),
    );
    
    // Aquí se podría agregar un evento de dominio para la moderación
    // También se podría implementar un sistema de moderación para eventos
    // guardando el estado en una colección separada
    
    return EventoCulturalAggregate(eventoModerado, _sugerencias);
  }

  /// Reporta el evento cultural
  EventoCulturalAggregate reportarEvento({
    required String reportadorId,
    required String razon,
  }) {
    // No se puede reportar un evento propio
    if (_evento.creadoPorId == reportadorId) {
      return this;
    }
    
    // En EventoCultural no tenemos un método reportar() como en otras entidades
    // Simplemente actualizamos la fecha por ahora
    final eventoReportado = _evento.copyWith(
      fechaActualizacion: DateTime.now(),
    );
    
    // Aquí se podría agregar un evento de dominio para el reporte
    // También se podría implementar un sistema de reportes para eventos
    // guardando los reportes en una colección separada
    
    return EventoCulturalAggregate(eventoReportado, _sugerencias);
  }

  /// Destaca el evento cultural
  EventoCulturalAggregate destacarEvento({
    required String moderadorId,
    required String razon,
  }) {

    
    // No hay un campo 'destacado' en EventoCultural, pero podríamos
    // agregar una propiedad al evento o usar algún otro mecanismo para marcarlo como destacado
    // Por ahora, solo actualizamos la fecha
    final eventoDestacado = _evento.copyWith(
      fechaActualizacion: DateTime.now(),
    );
    
    // TODO: Implementar lógica para marcar el evento como destacado
    // Por ejemplo, guardar en una colección separada de 'eventos_destacados'
    
    // Aquí se podría agregar un evento de dominio para destacar
    
    return EventoCulturalAggregate(eventoDestacado, _sugerencias);
  }

  /// Obtiene y limpia los eventos generados
  List<dynamic> obtenerYLimpiarEventos() {
    final eventosActuales = [..._eventos];
    _limpiarEventos();
    return eventosActuales;
  }
}
