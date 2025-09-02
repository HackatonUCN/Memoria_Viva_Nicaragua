import '../value_objects/ubicacion.dart';
import '../value_objects/multimedia.dart';
import '../enums/tipos_evento.dart';

/// Entidad para eventos culturales (creados por admin)
class EventoCultural {
  final String id;
  final String titulo;
  final String descripcion;
  final TipoEvento tipo;
  
  // Categorización
  final String categoriaId;
  final String categoriaNombre;
  
  // Ubicación como value object
  final Ubicacion ubicacion;
  
  // Multimedia como value objects
  final List<Multimedia> imagenes;
  
  // Fechas del evento
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool esRecurrente;
  final String? frecuencia;  // "anual", "mensual", etc.
  
  // Organizador
  final String organizador;
  final String? contacto;
  
  // Metadata
  final String creadoPorId;     // ID del admin
  final String creadoPorNombre; // Nombre del admin
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  
  // Soft delete
  final bool eliminado;
  final DateTime? fechaEliminacion;

  EventoCultural({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.ubicacion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.organizador,
    required this.creadoPorId,
    required this.creadoPorNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.imagenes = const [],
    this.esRecurrente = false,
    this.frecuencia,
    this.contacto,
    this.eliminado = false,
    this.fechaEliminacion,
  }) : assert(id != ''),
       assert(titulo.trim() != ''),
       assert(descripcion.trim() != ''),
       assert(categoriaId != ''),
       assert(categoriaNombre.trim() != ''),
       assert(organizador.trim() != ''),
       assert(creadoPorId != ''),
       assert(creadoPorNombre.trim() != '');

  /// Crea una copia con campos actualizados
  EventoCultural copyWith({
    String? nombre,
    String? descripcion,
    TipoEvento? tipo,
    String? categoriaId,
    String? categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia>? imagenes,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? esRecurrente,
    String? frecuencia,
    String? organizador,
    String? contacto,
    bool? eliminado,
    DateTime? fechaEliminacion,
    DateTime? fechaActualizacion,
  }) {
    return EventoCultural(
      id: id,
      titulo: nombre ?? titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      ubicacion: ubicacion ?? this.ubicacion,
      imagenes: imagenes ?? this.imagenes,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      frecuencia: frecuencia ?? this.frecuencia,
      organizador: organizador ?? this.organizador,
      contacto: contacto ?? this.contacto,
      creadoPorId: creadoPorId,
      creadoPorNombre: creadoPorNombre,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now().toUtc(),
      eliminado: eliminado ?? this.eliminado,
      fechaEliminacion: fechaEliminacion ?? this.fechaEliminacion,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': titulo,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'ubicacion': ubicacion.toMap(),
      'imagenes': imagenes.map((i) => i.toMap()).toList(),
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'esRecurrente': esRecurrente,
      'frecuencia': frecuencia,
      'organizador': organizador,
      'contacto': contacto,
      'creadoPorId': creadoPorId,
      'creadoPorNombre': creadoPorNombre,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
      'eliminado': eliminado,
      'fechaEliminacion': fechaEliminacion,
    };
  }

  /// Crea desde Map de Firestore
  factory EventoCultural.fromMap(Map<String, dynamic> map) {
    return EventoCultural(
      id: map['id'] as String,
      titulo: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tipo: TipoEvento.fromString(map['tipo'] as String),
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      ubicacion: Ubicacion.fromMap(map['ubicacion'] as Map<String, dynamic>),
      imagenes: (map['imagenes'] as List<dynamic>?)
          ?.map((i) => Multimedia.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      fechaInicio: _parseDateTime(map['fechaInicio']),
      fechaFin: _parseDateTime(map['fechaFin']),
      esRecurrente: map['esRecurrente'] as bool? ?? false,
      frecuencia: map['frecuencia'] as String?,
      organizador: map['organizador'] as String,
      contacto: map['contacto'] as String?,
      creadoPorId: map['creadoPorId'] as String,
      creadoPorNombre: map['creadoPorNombre'] as String,
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      fechaActualizacion: _parseDateTime(map['fechaActualizacion']),
      eliminado: map['eliminado'] as bool? ?? false,
      fechaEliminacion: map['fechaEliminacion'] != null 
          ? _parseDateTime(map['fechaEliminacion'])
          : null,
    );
  }

  /// Crea un nuevo evento cultural
  factory EventoCultural.crear({
    required String nombre,
    required String descripcion,
    required TipoEvento tipo,
    required String categoriaId,
    required String categoriaNombre,
    required Ubicacion ubicacion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String organizador,
    required String creadoPorId,
    required String creadoPorNombre,
    List<Multimedia> imagenes = const [],
    bool esRecurrente = false,
    String? frecuencia,
    String? contacto,
  }) {
    return EventoCultural(
      id: _generateId(),
      titulo: nombre,
      descripcion: descripcion,
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      imagenes: imagenes,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      esRecurrente: esRecurrente,
      frecuencia: frecuencia,
      organizador: organizador,
      contacto: contacto,
      creadoPorId: creadoPorId,
      creadoPorNombre: creadoPorNombre,
      fechaCreacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Marca como eliminado (soft delete)
  EventoCultural marcarEliminado() {
    return copyWith(
      eliminado: true,
      fechaEliminacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Restaura un evento eliminado
  EventoCultural restaurar() {
    return copyWith(
      eliminado: false,
      fechaEliminacion: null,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventoCultural && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Entidad para sugerencias de eventos (creadas por usuarios)
class SugerenciaEvento {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoEvento tipo;
  
  // Categorización
  final String categoriaId;
  final String categoriaNombre;
  
  // Ubicación como value object
  final Ubicacion ubicacion;
  
  // Multimedia como value objects
  final List<Multimedia> imagenes;
  
  // Fechas propuestas
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool esRecurrente;
  final String? frecuencia;
  
  // Organizador
  final String organizador;
  final String? contacto;
  
  // Estado y moderación
  final EstadoSugerencia estado;
  final String? razonRechazo;
  final String? eventoId;  // ID del evento creado si fue aprobada
  
  // Metadata
  final String sugeridoPorId;  // ID del usuario que sugiere
  final String sugeridoPorNombre;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  SugerenciaEvento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.ubicacion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.organizador,
    required this.sugeridoPorId,
    required this.sugeridoPorNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.imagenes = const [],
    this.esRecurrente = false,
    this.frecuencia,
    this.contacto,
    this.estado = EstadoSugerencia.pendiente,
    this.razonRechazo,
    this.eventoId,
  }) : assert(id != ''),
       assert(nombre.trim() != ''),
        assert(descripcion.trim() != ''),
        assert(categoriaId != ''),
        assert(categoriaNombre.trim() != ''),
        assert(organizador.trim() != ''),
        assert(sugeridoPorId != ''),
        assert(sugeridoPorNombre.trim() != '');

  /// Crea una copia con campos actualizados
  SugerenciaEvento copyWith({
    String? nombre,
    String? descripcion,
    TipoEvento? tipo,
    String? categoriaId,
    String? categoriaNombre,
    Ubicacion? ubicacion,
    List<Multimedia>? imagenes,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? esRecurrente,
    String? frecuencia,
    String? organizador,
    String? contacto,
    EstadoSugerencia? estado,
    String? razonRechazo,
    String? eventoId,
    DateTime? fechaActualizacion,
  }) {
    return SugerenciaEvento(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      ubicacion: ubicacion ?? this.ubicacion,
      imagenes: imagenes ?? this.imagenes,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      frecuencia: frecuencia ?? this.frecuencia,
      organizador: organizador ?? this.organizador,
      contacto: contacto ?? this.contacto,
      estado: estado ?? this.estado,
      razonRechazo: razonRechazo ?? this.razonRechazo,
      eventoId: eventoId ?? this.eventoId,
      sugeridoPorId: sugeridoPorId,
      sugeridoPorNombre: sugeridoPorNombre,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now().toUtc(),
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'ubicacion': ubicacion.toMap(),
      'imagenes': imagenes.map((i) => i.toMap()).toList(),
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'esRecurrente': esRecurrente,
      'frecuencia': frecuencia,
      'organizador': organizador,
      'contacto': contacto,
      'estado': estado.value,
      'razonRechazo': razonRechazo,
      'eventoId': eventoId,
      'sugeridoPorId': sugeridoPorId,
      'sugeridoPorNombre': sugeridoPorNombre,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea desde Map de Firestore
  factory SugerenciaEvento.fromMap(Map<String, dynamic> map) {
    return SugerenciaEvento(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tipo: TipoEvento.fromString(map['tipo'] as String),
      categoriaId: map['categoriaId'] as String,
      categoriaNombre: map['categoriaNombre'] as String,
      ubicacion: Ubicacion.fromMap(map['ubicacion'] as Map<String, dynamic>),
      imagenes: (map['imagenes'] as List<dynamic>?)
          ?.map((i) => Multimedia.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      fechaInicio: _parseDateTime(map['fechaInicio']),
      fechaFin: _parseDateTime(map['fechaFin']),
      esRecurrente: map['esRecurrente'] as bool? ?? false,
      frecuencia: map['frecuencia'] as String?,
      organizador: map['organizador'] as String,
      contacto: map['contacto'] as String?,
      estado: EstadoSugerencia.fromString(map['estado'] as String),
      razonRechazo: map['razonRechazo'] as String?,
      eventoId: map['eventoId'] as String?,
      sugeridoPorId: map['sugeridoPorId'] as String,
      sugeridoPorNombre: map['sugeridoPorNombre'] as String,
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      fechaActualizacion: _parseDateTime(map['fechaActualizacion']),
    );
  }

  /// Crea una nueva sugerencia de evento
  factory SugerenciaEvento.crear({
    required String nombre,
    required String descripcion,
    required TipoEvento tipo,
    required String categoriaId,
    required String categoriaNombre,
    required Ubicacion ubicacion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String organizador,
    required String sugeridoPorId,
    required String sugeridoPorNombre,
    List<Multimedia> imagenes = const [],
    bool esRecurrente = false,
    String? frecuencia,
    String? contacto,
  }) {
    return SugerenciaEvento(
      id: _generateId(),
      nombre: nombre,
      descripcion: descripcion,
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNombre: categoriaNombre,
      ubicacion: ubicacion,
      imagenes: imagenes,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      esRecurrente: esRecurrente,
      frecuencia: frecuencia,
      organizador: organizador,
      contacto: contacto,
      sugeridoPorId: sugeridoPorId,
      sugeridoPorNombre: sugeridoPorNombre,
      fechaCreacion: DateTime.now().toUtc(),
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Aprueba la sugerencia y crea el evento
  SugerenciaEvento aprobar(String eventoId) {
    return copyWith(
      estado: EstadoSugerencia.aprobada,
      eventoId: eventoId,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  /// Rechaza la sugerencia
  SugerenciaEvento rechazar(String razon) {
    return copyWith(
      estado: EstadoSugerencia.rechazada,
      razonRechazo: razon,
      fechaActualizacion: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SugerenciaEvento && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

 DateTime _parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  if (value is DateTime) {
    return value.isUtc ? value : value.toUtc();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is String) {
    return DateTime.parse(value).toUtc();
  }
  try {
    final dynamic dyn = value;
    final DateTime dt = dyn.toDate();
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

String _generateId({int length = 20}) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final StringBuffer buffer = StringBuffer();
  final int max = chars.length;
  int seed = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < length; i++) {
    seed = 1664525 * seed + 1013904223;
    final int index = (seed & 0x7FFFFFFF) % max;
    buffer.write(chars[index]);
  }
  return buffer.toString();
}