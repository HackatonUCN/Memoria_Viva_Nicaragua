import '../enums/tipos_notificacion.dart';

/// Entidad para manejar notificaciones
class Notificacion {
  final String id;
  final String usuarioId;      // Usuario que recibe la notificación
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final Map<String, dynamic> datos; // Datos adicionales
  final DateTime fechaCreacion;
  final bool leida;
  final bool eliminada;

  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.datos,
    required this.fechaCreacion,
    this.leida = false,
    this.eliminada = false,
  });

  /// Crea una copia con campos actualizados
  Notificacion copyWith({
    bool? leida,
    bool? eliminada,
  }) {
    return Notificacion(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      datos: datos,
      fechaCreacion: fechaCreacion,
      leida: leida ?? this.leida,
      eliminada: eliminada ?? this.eliminada,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.value,
      'datos': datos,
      'fechaCreacion': fechaCreacion,
      'leida': leida,
      'eliminada': eliminada,
    };
  }

  /// Crea desde Map de Firestore
  factory Notificacion.fromMap(Map<String, dynamic> map) {
    return Notificacion(
      id: map['id'] as String,
      usuarioId: map['usuarioId'] as String,
      titulo: map['titulo'] as String,
      mensaje: map['mensaje'] as String,
      tipo: TipoNotificacion.fromString(map['tipo'] as String),
      datos: Map<String, dynamic>.from(map['datos'] as Map),
      fechaCreacion: _parseDateTime(map['fechaCreacion']),
      leida: map['leida'] as bool? ?? false,
      eliminada: map['eliminada'] as bool? ?? false,
    );
  }

  // Factories para Eventos Culturales
  factory Notificacion.eventoSugerenciaAprobada({
    required String usuarioId,
    required String nombreEvento,
    required String eventoId,
  }) {
    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: '¡Sugerencia de Evento Aprobada!',
      mensaje: 'Tu sugerencia para el evento "$nombreEvento" ha sido aprobada.',
      tipo: TipoNotificacion.evento_sugerencia_aprobada,
      datos: {
        'eventoId': eventoId,
        'nombreEvento': nombreEvento,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  factory Notificacion.eventoSugerenciaRechazada({
    required String usuarioId,
    required String nombreEvento,
    required String razonRechazo,
  }) {
    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: 'Sugerencia de Evento No Aprobada',
      mensaje: 'Tu sugerencia para "$nombreEvento" no fue aprobada: $razonRechazo',
      tipo: TipoNotificacion.evento_sugerencia_rechazada,
      datos: {
        'nombreEvento': nombreEvento,
        'razonRechazo': razonRechazo,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  // Factories para Relatos
  factory Notificacion.relatoNuevo({
    required String usuarioId,
    required String relatoId,
    required String titulo,
    required String autorNombre,
  }) {
    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: 'Nuevo Relato en tu Área',
      mensaje: '$autorNombre compartió: "$titulo"',
      tipo: TipoNotificacion.relato_nuevo,
      datos: {
        'relatoId': relatoId,
        'titulo': titulo,
        'autorNombre': autorNombre,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  factory Notificacion.relatoModerado({
    required String usuarioId,
    required String relatoId,
    required String titulo,
    required bool aprobado,
    String? razon,
  }) {
    final estado = aprobado ? 'aprobado' : 'ocultado';
    final mensaje = aprobado 
        ? 'Tu relato "$titulo" ha sido aprobado.'
        : 'Tu relato "$titulo" ha sido ocultado: $razon';

    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: 'Relato $estado',
      mensaje: mensaje,
      tipo: TipoNotificacion.relato_moderado,
      datos: {
        'relatoId': relatoId,
        'titulo': titulo,
        'aprobado': aprobado,
        'razon': razon,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  // Factories para Saberes Populares
  factory Notificacion.saberNuevo({
    required String usuarioId,
    required String saberId,
    required String titulo,
    required String autorNombre,
    required String categoria,
  }) {
    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: 'Nuevo Saber Popular',
      mensaje: '$autorNombre compartió el $categoria: "$titulo"',
      tipo: TipoNotificacion.saber_nuevo,
      datos: {
        'saberId': saberId,
        'titulo': titulo,
        'autorNombre': autorNombre,
        'categoria': categoria,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  factory Notificacion.saberModerado({
    required String usuarioId,
    required String saberId,
    required String titulo,
    required bool aprobado,
    String? razon,
  }) {
    final estado = aprobado ? 'aprobado' : 'ocultado';
    final mensaje = aprobado 
        ? 'Tu saber popular "$titulo" ha sido aprobado.'
        : 'Tu saber popular "$titulo" ha sido ocultado: $razon';

    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: 'Saber Popular $estado',
      mensaje: mensaje,
      tipo: TipoNotificacion.saber_moderado,
      datos: {
        'saberId': saberId,
        'titulo': titulo,
        'aprobado': aprobado,
        'razon': razon,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }

  // Notificaciones de Sistema
  factory Notificacion.contenidoViral({
    required String usuarioId,
    required String titulo,
    required String tipo,
    required String id,
    required int interacciones,
  }) {
    return Notificacion(
      id: _generateId(),
      usuarioId: usuarioId,
      titulo: '¡Tu Contenido es Popular!',
      mensaje: 'Tu $tipo "$titulo" está siendo muy compartido ($interacciones interacciones)',
      tipo: TipoNotificacion.contenido_viral,
      datos: {
        'id': id,
        'titulo': titulo,
        'tipo': tipo,
        'interacciones': interacciones,
      },
      fechaCreacion: DateTime.now().toUtc(),
    );
  }
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