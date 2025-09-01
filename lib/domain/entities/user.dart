import '../enums/roles_usuario.dart';

/// Entidad que representa un usuario en la aplicación Memoria Viva Nicaragua
class User {
  final String id;                // UID de Firebase Auth
  final String nombre;            // Nombre completo
  final String email;            // Email para autenticación
  final UserRole rol;            // Rol del usuario
  final String? avatarUrl;       // URL de Firebase Storage para la foto
  final DateTime fechaRegistro;   // Timestamp de creación
  final DateTime ultimaModificacion; // Último update
  
  // Campos de perfil
  final String? departamento;    // Ubicación - importante para contexto cultural
  final String? municipio;       // Ubicación más específica
  final String? biografia;       // Descripción personal
  
  // Estadísticas y métricas
  final int relatosPublicados;   // Contador de historias
  final int saberesCompartidos;  // Contador de saberes populares
  final int puntajeTotal;        // Gamificación
  
  // Estado y preferencias
  final bool activo;             // Estado de la cuenta
  final bool notificacionesActivas; // Preferencias de notificación
  
  /// Constructor con invariantes básicas
  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaRegistro,
    required this.ultimaModificacion,
    required this.activo,
    this.avatarUrl,
    this.departamento,
    this.municipio,
    this.biografia,
    this.relatosPublicados = 0,
    this.saberesCompartidos = 0,
    this.puntajeTotal = 0,
    this.notificacionesActivas = true,
  }) : assert(id != ''),
       assert(nombre.trim() != ''),
       assert(email.trim() != '' && email.contains('@')),
       assert(relatosPublicados >= 0),
       assert(saberesCompartidos >= 0),
       assert(puntajeTotal >= 0);

  /// Crea una copia del usuario con campos actualizados
  User copyWith({
    String? nombre,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
    bool? notificacionesActivas,
    UserRole? rol,
    bool? activo,
    int? relatosPublicados,
    int? saberesCompartidos,
    int? puntajeTotal,
  }) {
    return User(
      id: this.id,
      email: this.email,
      nombre: nombre ?? this.nombre,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rol: rol ?? this.rol,
      fechaRegistro: this.fechaRegistro,
      ultimaModificacion: DateTime.now().toUtc(),
      departamento: departamento ?? this.departamento,
      municipio: municipio ?? this.municipio,
      biografia: biografia ?? this.biografia,
      activo: activo ?? this.activo,
      relatosPublicados: relatosPublicados ?? this.relatosPublicados,
      saberesCompartidos: saberesCompartidos ?? this.saberesCompartidos,
      puntajeTotal: puntajeTotal ?? this.puntajeTotal,
      notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
    );
  }

  /// Convierte la entidad a un Map para almacenar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol.value,
      'avatarUrl': avatarUrl,
      'fechaRegistro': fechaRegistro,
      'ultimaModificacion': ultimaModificacion,
      'departamento': departamento,
      'municipio': municipio,
      'biografia': biografia,
      'activo': activo,
      'relatosPublicados': relatosPublicados,
      'saberesCompartidos': saberesCompartidos,
      'puntajeTotal': puntajeTotal,
      'notificacionesActivas': notificacionesActivas,
    };
  }

  /// Crea una instancia de User desde un Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: UserRole.fromString(map['rol'] as String),
      avatarUrl: map['avatarUrl'] as String?,
      fechaRegistro: _parseDateTime(map['fechaRegistro']),
      ultimaModificacion: _parseDateTime(map['ultimaModificacion']),
      departamento: map['departamento'] as String?,
      municipio: map['municipio'] as String?,
      biografia: map['biografia'] as String?,
      activo: map['activo'] as bool,
      relatosPublicados: map['relatosPublicados'] as int? ?? 0,
      saberesCompartidos: map['saberesCompartidos'] as int? ?? 0,
      puntajeTotal: map['puntajeTotal'] as int? ?? 0,
      notificacionesActivas: map['notificacionesActivas'] as bool? ?? true,
    );
  }

  /// Crea un nuevo usuario
  factory User.crear({
    required String id,
    required String nombre,
    required String email,
    UserRole rol = UserRole.normal,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
  }) {
    return User(
      id: id,
      nombre: nombre,
      email: email,
      rol: rol,
      avatarUrl: avatarUrl,
      departamento: departamento,
      municipio: municipio,
      biografia: biografia,
      fechaRegistro: DateTime.now().toUtc(),
      ultimaModificacion: DateTime.now().toUtc(),
      activo: true,
    );
  }

  bool get esAdmin => rol == UserRole.admin;
  bool get esInvitado => rol == UserRole.invitado;

  /// Actualiza las estadísticas del usuario
  User actualizarEstadisticas({
    int? nuevosPuntaje,
    int? nuevosRelatos,
    int? nuevosSaberes,
  }) {
    return copyWith(
      puntajeTotal: nuevosPuntaje != null ? puntajeTotal + nuevosPuntaje : null,
      relatosPublicados: nuevosRelatos != null ? relatosPublicados + nuevosRelatos : null,
      saberesCompartidos: nuevosSaberes != null ? saberesCompartidos + nuevosSaberes : null,
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